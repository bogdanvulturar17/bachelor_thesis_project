-- internet_service_offers_dataset_verizon

-- creare tabel train
DROP TABLE IF EXISTS internet_service_offers_dataset_verizon;

CREATE TABLE IF NOT EXISTS internet_service_offers_dataset_verizon(
    address_full varchar(75),
    incorporated_place varchar(25),
    major_city varchar(25),
    state varchar(2),
    lat float,
    lon float,
    block_group bigint,
    collection_datetime int,
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
COPY internet_service_offers_dataset_verizon
FROM '/tmp/internet_service_offers_dataset_verizon.csv'
DELIMITER ','
CSV HEADER;

-- add PK AI (corectie)
ALTER TABLE internet_service_offers_dataset_verizon ADD COLUMN id SERIAL PRIMARY KEY;

-- verifica date
SELECT * FROM internet_service_offers_dataset_verizon;

SELECT train_test_split(
    'internet_service_offers_dataset_verizon', --Source Table
    'internet_service_offers_dataset_verizon_split', -- Output Table
    0.25, -- Sample proportion
    NULL, -- Sample proportion
    NULL, -- Strata definition
    '*', -- Columns to out
    FALSE, -- Sample without replacement
    TRUE --Do not separate output tables
);

DROP TABLE IF EXISTS internet_service_offers_dataset_verizon_split_train;

DROP TABLE IF EXISTS internet_service_offers_dataset_verizon_split_test;

SELECT * FROM internet_service_offers_dataset_verizon_split_train;

SELECT * FROM internet_service_offers_dataset_verizon_split_test;

-- antrenare https://madlib.apache.org/docs/latest/group__grp__decision__tree.html
DROP TABLE IF EXISTS internet_service_offers_dataset_verizon_split_train_out, internet_service_offers_dataset_verizon_split_train_out_group, internet_service_offers_dataset_verizon_split_train_out_summary;

SELECT forest_train(
    'internet_service_offers_dataset_verizon_split_train',  -- source table
    'internet_service_offers_dataset_verizon_split_train_out', -- output model table
    'id', -- id column
    'speed_down', -- responce
    '"in_service", "speed_unit", "technology", "package", "price", "fastest_speed_down", "fastest_speed_price", "fn", "redlining_grade", "closest_fiber_miles", "race_perc_non_white", "income_lmi", "ppl_per_sq_mile", "n_providers", "income_dollars_below_median", "internet_perc_broadband", "median_household_income"',-- features
    NULL, -- exclude columns
    NULL, -- grouping columns
    10::integer,        -- number of trees
    2::integer,        -- number of random features
    TRUE::boolean,     -- variable importance
    1::integer,        -- num_permutations
    3::integer,        -- max depth
    2::integer,        -- min split
    1::integer,        -- min bucket
    3::integer,        -- number of splits per continuous variable
    'null_as_category=TRUE');

-- view model
SELECT * FROM internet_service_offers_dataset_verizon_split_train_out;

SELECT * FROM internet_service_offers_dataset_verizon_split_train_out_summary;

SELECT get_tree('internet_service_offers_dataset_verizon_split_train_out',1,7,FALSE);

-- predictie
DROP TABLE IF EXISTS prediction_results_verizon;
SELECT forest_predict(
    'internet_service_offers_dataset_verizon_split_train_out', -- tree model
    'internet_service_offers_dataset_verizon', -- new data table
    'prediction_results_verizon', -- output table
    'response'); -- show response

-- view scoring
DROP TABLE IF EXISTS scoring_results_internet_service_offers_dataset_verizon;
CREATE TABLE scoring_results_internet_service_offers_dataset_verizon AS SELECT i.speed_down, f.estimated_speed_down FROM internet_service_offers_dataset_verizon_split_train i, prediction_results_verizon f WHERE i.id=f.id ORDER BY i.id;
SELECT * FROM scoring_results_internet_service_offers_dataset_verizon;

--r2 score
DROP TABLE IF EXISTS scoring_results_internet_service_offers_dataset_verizon_out_r2;
SELECT adjusted_r2_score('scoring_results_internet_service_offers_dataset_verizon', 'scoring_results_internet_service_offers_dataset_verizon_out_r2', 'estimated_speed_down', 'speed_down', 3, 100);
SELECT * FROM scoring_results_internet_service_offers_dataset_verizon_out_r2;

--mean abs percentage error
DROP TABLE IF EXISTS scoring_results_internet_service_offers_dataset_verizon_out_mean_sqrt_err;
SELECT mean_squared_error('scoring_results_internet_service_offers_dataset_verizon', 'scoring_results_internet_service_offers_dataset_verizon_out_mean_sqrt_err', 'estimated_speed_down', 'speed_down');
SELECT * FROM scoring_results_internet_service_offers_dataset_verizon_out_mean_sqrt_err;

-- available memory
SHOW work_mem;
select * from pg_settings where name IN ('work_mem', 'shared_buffers');

-- changing values for shared_buffers and work_mem and restarts the service
ALTER SYSTEM SET shared_buffers TO 1079800;
ALTER SYSTEM SET work_mem TO 2096000;