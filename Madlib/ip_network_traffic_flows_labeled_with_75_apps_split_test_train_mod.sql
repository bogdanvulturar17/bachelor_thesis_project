-- ip_network_traffic_flows_labeled_with_75_apps

-- creare tabel train
DROP TABLE IF EXISTS ip_network_traffic_flows;

CREATE TABLE IF NOT EXISTS ip_network_traffic_flows(
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
    Total_Length_of_Fwd_Packets decimal,
    Total_Length_of_Bwd_Packets decimal,
    Fwd_Packet_Length_Max int,
    Fwd_Packet_Length_Min int,
    Fwd_Packet_Length_Mean float,
    Fwd_Packet_Length_Std float,
    Bwd_Packet_Length_Max int,
    Bwd_Packet_Length_Min int,
    Bwd_Packet_Length_Mean float,
    Bwd_Packet_Length_Std float,
    Flow_Bytes_s decimal,
    Flow_Packets_s decimal,
    Flow_IAT_Mean decimal,
    Flow_IAT_Std decimal,
    Flow_IAT_Max decimal,
    Flow_IAT_Min decimal,
    Fwd_IAT_Total decimal,
    Fwd_IAT_Mean decimal,
    Fwd_IAT_Std decimal,
    Fwd_IAT_Max decimal,
    Fwd_IAT_Min decimal,
    Bwd_IAT_Total decimal,
    Bwd_IAT_Mean decimal,
    Bwd_IAT_Std decimal,
    Bwd_IAT_Max decimal,
    Bwd_IAT_Min decimal,
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
    Active_Max decimal,
    Active_Min decimal,
    Idle_Mean float,
    Idle_Std float,
    Idle_Max decimal,
    Idle_Min decimal,
    Label varchar(15),
    L7Protocol int,
    ProtocolName varchar(20)
);

-- copiere fisiere in container-ul de docker
-- docker cp C:\Users\vultu\OneDrive\Desktop\ip_network_traffic_flows_labeled_with_75_apps\ip_network_traffic_flows_labeled_with_75_apps.csv postgres-madlib:/tmp/

-- incarcare date train
COPY ip_network_traffic_flows
FROM '/tmp/ip_network_traffic_flows_labeled_with_75_apps.csv'
DELIMITER ','
CSV HEADER;

-- add PK AI (corectie)
ALTER TABLE ip_network_traffic_flows ADD COLUMN id SERIAL PRIMARY KEY;

-- verifica date
SELECT * FROM ip_network_traffic_flows LIMIT 10;

DROP TABLE IF EXISTS ip_network_traffic_flows_split_train;
DROP TABLE IF EXISTS ip_network_traffic_flows_split_test;

SELECT train_test_split(
    'ip_network_traffic_flows', --Source Table
    'ip_network_traffic_flows_split', -- Output Table
    0.01, -- Sample proportion
    NULL, -- Sample proportion
    NULL, -- Strata definition
    '"average_packet_size", "destination_port", "destination_ip", "protocolname", "id"', -- Columns to out
    FALSE, -- Sample without replacement
    TRUE --Do not separate output tables
);

-- cate randuri au ramas 0.05 - 178865
SELECT COUNT(*) FROM ip_network_traffic_flows_split_train;

SELECT * FROM ip_network_traffic_flows_split_train;

SELECT * FROM ip_network_traffic_flows_split_test;

-- antrenare https://madlib.apache.org/docs/latest/group__grp__decision__tree.html
DROP TABLE IF EXISTS ip_network_traffic_flows_split_train_out, ip_network_traffic_flows_split_train_out_group, ip_network_traffic_flows_split_train_out_summary;

SELECT forest_train(
    'ip_network_traffic_flows_split_train', -- source table
    'ip_network_traffic_flows_split_train_out', -- output model table
    'id', -- id column
    'protocolname', -- response
    '"average_packet_size", "destination_port", "destination_ip"', --features
    NULL, -- exclude columns
    NULL, -- grouping columns
    20::integer, -- number of trees
    2::integer, -- number of random features
    TRUE::boolean, -- variable importance
    1::integer, -- num_permutations
    8::integer, --max depth
    3::integer, --min split
    1::integer,  --min bucket
    10::integer,  --number of splits per continuous variable
    'null_as_category=TRUE'
);

-- view model
SELECT * FROM ip_network_traffic_flows_split_train_out;

SELECT * FROM ip_network_traffic_flows_split_train_out_summary;

SELECT get_tree('ip_network_traffic_flows_split_train_out',1,7,FALSE);

-- predictie
DROP TABLE IF EXISTS prediction_results_ip_network_traffic;
SELECT forest_predict(
    'ip_network_traffic_flows_split_train_out', -- tree model
    'ip_network_traffic_flows_split_test', -- new data table
    'the_prediction_results_ip_network_traffic', -- output table
    'response'); -- show response

-- view scoring
SELECT * from prediction_results_ip_network_traffic;

DROP TABLE IF EXISTS scoring_results_ip_network_traffic;
CREATE TABLE scoring_results_ip_network_traffic AS
    SELECT a prob0,
        b prob1,
        c prob2,
        d prob3,
        e prob4,
        f prob5,
        g prob6,
        h prob7,
        i prob8,
        j prob9,
        k prob10,
        l prob11,
        m prob12,
        n prob13,
        o prob14,
        p prob15,
        q prob16,
        r prob17,
        s prob18,
        t prob19,
        v prob20,
        u prob21,
        w prob22,
        x prob23,
        y prob24,
        z prob25,
        aa prob26,
        ab prob27,
        ac prob28,
        ad prob29,
        ae prob30,
        af prob31,
        ag prob32,
        ah prob33,
        ai prob34,
        aj prob35,
        ak prob36,
        al prob37,
        am prob38,
        an prob39,
        ao prob40,
        ap prob41,
        aq prob42,
        ar prob43,
        at prob44,
        av prob45,
        CASE
            WHEN greatest(a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,v,u,w,x,y,z,aa,ab,ac,ad,ae,af,ag,ah,ai,aj,ak,al,am,an,ao,ap,aq,ar,at,av) > 0.5 THEN TRUE
            ELSE FALSE
        END AS obs
    FROM (SELECT "estimated_prob_AMAZON" AS a, "estimated_prob_APPLE" AS b, "estimated_prob_APPLE_ICLOUD" AS c, "estimated_prob_APPLE_ITUNES" AS d, "estimated_prob_CLOUDFLARE"  AS e, "estimated_prob_CONTENT_FLASH" AS f, "estimated_prob_DEEZER" AS g, "estimated_prob_DNS" AS h, "estimated_prob_DROPBOX" AS i, "estimated_prob_EASYTAXI" AS j, "estimated_prob_EBAY" AS k, "estimated_prob_EDONKEY" AS l, "estimated_prob_FACEBOOK" AS m, "estimated_prob_FTP_DATA" AS n, "estimated_prob_GMAIL" AS o, "estimated_prob_GOOGLE" AS p, "estimated_prob_GOOGLE_MAPS" AS q, "estimated_prob_HTTP" AS r, "estimated_prob_HTTP_CONNECT" AS s, "estimated_prob_HTTP_DOWNLOAD" AS t, "estimated_prob_HTTP_PROXY" AS u, "estimated_prob_INSTAGRAM" AS v, "estimated_prob_IP_ICMP" AS w, "estimated_prob_LASTFM" AS x, "estimated_prob_MICROSOFT" AS y, "estimated_prob_MQTT" AS z, "estimated_prob_MSN" AS aa, "estimated_prob_MS_ONE_DRIVE" AS ab, "estimated_prob_NETFLIX" AS ac, "estimated_prob_NTP" AS ad, "estimated_prob_OFFICE_365" AS ae, "estimated_prob_RTMP" AS af, "estimated_prob_SKYPE" AS ag, "estimated_prob_SPOTIFY" AS ah, "estimated_prob_SSL" AS ai, "estimated_prob_SSL_NO_CERT" AS aj, "estimated_prob_TEAMVIEWER" AS ak, "estimated_prob_TOR" AS al, "estimated_prob_TWITTER" AS am, "estimated_prob_UBUNTUONE" AS an, "estimated_prob_UNENCRYPED_JABBER" AS ao, "estimated_prob_WHATSAPP" AS ap, "estimated_prob_WIKIPEDIA" AS aq, "estimated_prob_WINDOWS_UPDATE" AS ar, "estimated_prob_YAHOO" AS at, "estimated_prob_YOUTUBE" AS av FROM prediction_results_ip_network_traffic) x;
SELECT * FROM scoring_results_ip_network_traffic;

--binary classifier
DROP TABLE IF EXISTS scoring_results_ip_network_traffic_bin_class;
SELECT binary_classifier('scoring_results_ip_network_traffic', 'scoring_results_ip_network_traffic_bin_class', 'prob0', 'obs');
SELECT * FROM scoring_results_ip_network_traffic_bin_class WHERE threshold=0.5;

-- arata memoria disponibila
SHOW work_mem;
select * from pg_settings where name IN ('work_mem', 'shared_buffers');

-- se modifica valorile pentru memorie si se reporneste serviciul
ALTER SYSTEM SET shared_buffers TO 1079800;
ALTER SYSTEM SET work_mem TO 2096000;