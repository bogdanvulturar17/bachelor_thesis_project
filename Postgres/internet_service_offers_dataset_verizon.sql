-- internet_service_offers_dataset_verizon

-- creare tabel train
DROP TABLE IF EXISTS pgml.internet_service_offers_dataset_verizon cascade;

CREATE TABLE IF NOT EXISTS pgml.internet_service_offers_dataset_verizon(
    address_full varchar(75),
    incorporated_place varchar(25),
    major_city varchar(25),
    state varchar(2),
    lat float,
    lon float,
    block_group bigint,
    collection_datetime bigint,
    in_service varchar(10),
    provider  varchar(10),
    speed_down float,
    speed_up float,
    speed_unit varchar(5),
    price float,
    technology varchar(10),
    package varchar(50),
    fastest_speed_down float,
    fastest_speed_price float,
    fn varchar(75),
    redlining_grade varchar(10),
    closest_fiber_miles float,
    address_full_closest_fiber varchar(75),
    lat_closest_fiber float,
    lon_closest_fiber float,
    race_perc_non_white float,
    income_lmi float,
    ppl_per_sq_mile float,
    n_providers float,
    income_dollars_below_median float,
    internet_perc_broadband float,
    median_household_income int
);

-- copiere fisiere in container-ul de docker
-- docker cp C:\Users\vultu\Desktop\internet_service_offers_dataset\internet_service_offers_dataset_verizon.csv postgres-madlib:/tmp/

-- incarcare date train
COPY pgml.internet_service_offers_dataset_verizon
FROM '/tmp/internet_service_offers_dataset_verizon.csv'
DELIMITER ','
CSV HEADER;

-- add PK AI (corectie)
ALTER TABLE pgml.internet_service_offers_dataset_verizon ADD COLUMN id SERIAL PRIMARY KEY;

-- verifica date
SELECT * FROM pgml.internet_service_offers_dataset_verizon;

-- snapshots are automatically random ordered at creation, so this view is just for fun
DROP VIEW IF EXISTS pgml.internet_service_offers_dataset_verizon_view;
CREATE VIEW pgml.internet_service_offers_dataset_verizon_view AS SELECT *FROM pgml.internet_service_offers_dataset_verizon ORDER BY random()LIMIT 100;

-- Example of replacing NULL values in the column array column with default value 0
UPDATE pgml.internet_service_offers_dataset_verizon SET redlining_grade = COALESCE(redlining_grade, '0');
UPDATE pgml.internet_service_offers_dataset_verizon SET speed_unit = COALESCE(speed_unit, '0');
UPDATE pgml.internet_service_offers_dataset_verizon SET price = COALESCE(price, 0);
UPDATE pgml.internet_service_offers_dataset_verizon SET technology = COALESCE(technology, '0');
UPDATE pgml.internet_service_offers_dataset_verizon SET package = COALESCE(package, '0');
UPDATE pgml.internet_service_offers_dataset_verizon SET income_lmi = COALESCE(income_lmi, 0);
UPDATE pgml.internet_service_offers_dataset_verizon SET income_dollars_below_median = COALESCE(income_dollars_below_median, 0);
UPDATE pgml.internet_service_offers_dataset_verizon SET internet_perc_broadband = COALESCE(internet_perc_broadband, 0);

-- training
SELECT * FROM pgml.train(
    project_name => 'internet_service_offers_dataset_verizon',
    task => 'regression',
    relation_name => 'pgml.internet_service_offers_dataset_verizon',
    y_column_name => 'speed_down',
    algorithm=> 'random_forest',
    preprocess => '{
        "price": {"impute": "mean", "scale":"standard"},
        "income_lmi": {"impute": "mean", "scale":"standard"},
        "ppl_per_sq_mile": {"impute": "mean", "scale":"standard"},
        "income_dollars_below_median": {"impute": "mean", "scale":"standard"},
        "internet_perc_broadband": {"impute": "mean", "scale":"standard"},
        "address_full": {"impute": "mode", "scale":"standard"},
        "incorporated_place": {"impute": "mode", "scale":"standard"},
        "major_city": {"impute": "mode", "scale":"standard"},
        "state": {"impute": "mode", "scale":"standard"},
        "fn": {"impute": "mode", "scale":"standard"},
        "address_full_closest_fiber": {"impute": "mode", "scale":"standard"}
    }'
);

-- predictions
SELECT speed_down, pgml.predict('internet_service_offers_dataset_verizon', ARRAY[lat,lon,block_group,collection_datetime,speed_down,speed_up,price,fastest_speed_down,fastest_speed_price,closest_fiber_miles,lat_closest_fiber,lon_closest_fiber,race_perc_non_white,income_lmi,ppl_per_sq_mile,n_providers,income_dollars_below_median,internet_perc_broadband,median_household_income, id] || 20 || 21 || 23 || 24 || 25 || 26 || 27 || 28 || 29 || 30 || 31) AS prediction
FROM pgml.internet_service_offers_dataset_verizon LIMIT 20;

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
SELECT speed_down, pgml.predict('internet_service_offers_dataset_verizon', ARRAY[lat,lon,block_group,collection_datetime,speed_down,speed_up,price,fastest_speed_down,fastest_speed_price,closest_fiber_miles,lat_closest_fiber,lon_closest_fiber,race_perc_non_white,income_lmi,ppl_per_sq_mile,n_providers,income_dollars_below_median,internet_perc_broadband,median_household_income, id] || 20 || 21 || 23 || 24 || 25 || 26 || 27 || 28 || 29 || 30 || 31) AS prediction
FROM pgml.internet_service_offers_dataset_verizon LIMIT 20;