-- ip_network_traffic_flows_labeled_with_75_apps

-- creare tabel train
DROP TABLE IF EXISTS pgml.ip_network_traffic_flows;

CREATE TABLE IF NOT EXISTS pgml.ip_network_traffic_flows(
    Flow_ID varchar(50),
    Source_IP varchar(25),
    Source_Port int,
    Destination_IP varchar(25),
    Destination_Port int,
    Protocol int,
    Timestamp varchar(25),
    Flow_Duration int,
    Total_Fwd_Packets int,
    Total_Backward_Packets int,
    Total_Length_of_Fwd_Packets float,
    Total_Length_of_Bwd_Packets float,
    Fwd_Packet_Length_Max int,
    Fwd_Packet_Length_Min int,
    Fwd_Packet_Length_Mean float,
    Fwd_Packet_Length_Std float,
    Bwd_Packet_Length_Max int,
    Bwd_Packet_Length_Min int,
    Bwd_Packet_Length_Mean float,
    Bwd_Packet_Length_Std float,
    Flow_Bytes_s float,
    Flow_Packets_s float,
    Flow_IAT_Mean float,
    Flow_IAT_Std float,
    Flow_IAT_Max float,
    Flow_IAT_Min float,
    Fwd_IAT_Total float,
    Fwd_IAT_Mean float,
    Fwd_IAT_Std float,
    Fwd_IAT_Max float,
    Fwd_IAT_Min float,
    Bwd_IAT_Total float,
    Bwd_IAT_Mean float,
    Bwd_IAT_Std float,
    Bwd_IAT_Max float,
    Bwd_IAT_Min float,
    Fwd_PSH_Flags int,
    Bwd_PSH_Flags int,
    Fwd_URG_Flags int,
    Bwd_URG_Flags int,
    Fwd_Header_Length int,
    Bwd_Header_Length int,
    Fwd_Packets_s float,
    Bwd_Packets_s float,
    Min_Packet_Length int,
    Max_Packet_Length int,
    Packet_Length_Mean float,
    Packet_Length_Std float,
    Packet_Length_Variance float,
    FIN_Flag_Count int,
    SYN_Flag_Count int,
    RST_Flag_Count int,
    PSH_Flag_Count int,
    ACK_Flag_Count int,
    URG_Flag_Count int,
    CWE_Flag_Count int,
    ECE_Flag_Count int,
    Down_Up_Ratio int,
    Average_Packet_Size float,
    Avg_Fwd_Segment_Size float,
    Avg_Bwd_Segment_Size float,
    Fwd_Header_Length_1 int,
    Fwd_Avg_Bytes_Bulk int,
    Fwd_Avg_Packets_Bulk int,
    Fwd_Avg_Bulk_Rate int,
    Bwd_Avg_Bytes_Bulk int,
    Bwd_Avg_Packets_Bulk int,
    Bwd_Avg_Bulk_Rate int,
    Subflow_Fwd_Packets int,
    Subflow_Fwd_Bytes int,
    Subflow_Bwd_Packets int,
    Subflow_Bwd_Bytes int,
    Init_Win_bytes_forward int,
    Init_Win_bytes_backward int,
    act_data_pkt_fwd int,
    min_seg_size_forward int,
    Active_Mean float,
    Active_Std float,
    Active_Max float,
    Active_Min float,
    Idle_Mean float,
    Idle_Std float,
    Idle_Max float,
    Idle_Min float,
    Label varchar(15),
    L7Protocol int,
    ProtocolName varchar(20)
);

-- copiere fisiere in container-ul de docker
-- docker cp C:\Users\vultu\Desktop\ip_network_traffic_flows_labeled_with_75_apps\ip_network_traffic_flows_labeled_with_75_apps.csv postgres-madlib:/tmp/

-- incarcare date train
COPY pgml.ip_network_traffic_flows
FROM '/tmp/ip_network_traffic_flows_labeled_with_75_apps.csv'
DELIMITER ','
CSV HEADER;

-- add PK AI (corectie)
ALTER TABLE pgml.ip_network_traffic_flows ADD COLUMN id SERIAL PRIMARY KEY;

-- verifica date
SELECT * FROM pgml.ip_network_traffic_flows LIMIT 10;

-- tabel mai mic
DROP TABLE IF EXISTS pgml.ip_network_traffic_flows_small;
CREATE TABLE IF NOT EXISTS pgml.ip_network_traffic_flows_small AS SELECT "average_packet_size", "destination_port", "destination_ip", "protocolname" FROM pgml.ip_network_traffic_flows LIMIT 10000;

-- vizualizare tabel mic
SELECT * FROM pgml.ip_network_traffic_flows_small;

-- snapshots are automatically random ordered at creation, so this view is just for fun
DROP VIEW IF EXISTS pgml.ip_network_traffic_flows_view;
CREATE VIEW pgml.ip_network_traffic_flows_view AS SELECT *FROM pgml.ip_network_traffic_flows ORDER BY random()LIMIT 100;

-- training
SELECT * FROM pgml.train(
    project_name => 'ip_network_traffic_flows',
    task => 'classification',
    relation_name => 'pgml.ip_network_traffic_flows_small',
    y_column_name => 'protocolname',
    algorithm => 'random_forest',
    preprocess => '{
        "destination_ip": {"impute": "mode"},
        "average_packet_size" : {"impute": "mode"},
        "destination_port" : {"impute": "mode"},
        "protocolname": {"impute": "mode"}
    }'
);

-- predictions
SELECT protocolname, pgml.predict('ip_network_traffic_flows_labeled_with_75_apps', ARRAY[average_packet_size:: double precision, destination_port::double precision] || 3) AS prediction
FROM pgml.ip_network_traffic_flows_small;

SELECT table_name, column_name, data_type FROM information_schema.columns WHERE table_name='ip_network_traffic_flows_small';

/*
-- ensembles
SELECT * FROM pgml.train('internet_service_offers_dataset_verizon', algorithm => 'random_forest', hyperparams => '{"n_estimators": 10}');

-- check out all that hard work
SELECT trained_models.* FROM pgml.trained_models
JOIN pgml.models on models.id = trained_models.id
ORDER BY models.metrics->>'f1' DESC LIMIT 5;

-- deploy the random_forest model for prediction use
SELECT * FROM pgml.deploy('internet_service_offers_dataset_verizon', 'most_recent', 'random_forest');

-- check out that throughput
SELECT * FROM pgml.deployed_models ORDER BY deployed_at DESC LIMIT 5;

-- do a hyperparam search on your favorite algorithm
SELECT pgml.train(
    'internet_service_offers_dataset_verizon',
    algorithm => 'gradient_boosting_trees',
    hyperparams => '{"random_state": 0}',
    search => 'grid',
    search_params => '{
        "n_estimators": [10, 20],
        "max_leaf_nodes": [2, 4],
        "criterion": ["friedman_mse", "squared_error"]
    }'
);

-- deploy the "best" model for prediction use
SELECT * FROM pgml.deploy('internet_service_offers_dataset_verizon', 'best_score');
SELECT * FROM pgml.deploy('internet_service_offers_dataset_verizon', 'most_recent');
SELECT * FROM pgml.deploy('internet_service_offers_dataset_verizon', 'rollback');
SELECT * FROM pgml.deploy('internet_service_offers_dataset_verizon', 'best_score', 'svm');

-- improved predictions
SELECT speed_up, pgml.predict('internet_service_offers_dataset_verizon', ARRAY[lat,lon,block_group,collection_datetime,speed_down,speed_up,price,fastest_speed_down,fastest_speed_price,closest_fiber_miles,lat_closest_fiber,lon_closest_fiber,race_perc_non_white,income_lmi,ppl_per_sq_mile,n_providers,income_dollars_below_median,internet_perc_broadband,median_household_income, id] || 20 || 21 || 23 || 24 || 25 || 26 || 27 || 28 || 29 || 30 || 31) AS prediction
FROM pgml.internet_service_offers_dataset_verizon;
 */

-- arata memoria disponibila
SHOW work_mem;
select * from pg_settings where name IN ('work_mem', 'shared_buffers');

-- se modifica valorile pentru memorie si se reporneste serviciul
ALTER SYSTEM SET shared_buffers TO 1079800;
ALTER SYSTEM SET work_mem TO 2096000;