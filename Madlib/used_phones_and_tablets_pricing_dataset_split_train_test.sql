-- used_phones_and_tablets_pricing_dataset

-- creare tabel train
DROP TABLE IF EXISTS used_phones_and_tablets_pricing_dataset;

CREATE TABLE IF NOT EXISTS used_phones_and_tablets_pricing_dataset(
device_brand varchar(20),
os varchar(10),
screen_size float,
four_g boolean,
five_g boolean,
rear_camera_mp float,
front_camera_mp float,
internal_memory float,
ram float,
battery float,
weight float,
release_year int,
days_used int,
normalized_used_price float,
normalized_new_price float
);

-- copiere fisiere in container-ul de docker
-- docker cp C:\Users\vultu\Desktop\used_phones_and_tablets_pricing_dataset\used_phones_and_tablets_pricing_dataset.csv postgres-madlib:/tmp/

-- incarcare date train
COPY used_phones_and_tablets_pricing_dataset
FROM '/tmp/used_phones_and_tablets_pricing_dataset.csv'
DELIMITER ','
CSV HEADER;

-- add PK AI (corectie)
ALTER TABLE used_phones_and_tablets_pricing_dataset ADD COLUMN id SERIAL PRIMARY KEY;

-- verifica date
SELECT * FROM used_phones_and_tablets_pricing_dataset;

SELECT train_test_split(
    'used_phones_and_tablets_pricing_dataset', --Source Table
    'used_phones_and_tablets_pricing_dataset_split', -- Output Table
    0.25, -- Sample proportion
    NULL, -- Sample proportion
    NULL, -- Strata definition
    '*', -- Columns to out
    FALSE, -- Sample without replacement
    TRUE --Do not separate output tables
);

DROP TABLE IF EXISTS used_phones_and_tablets_pricing_dataset_split_train;

DROP TABLE IF EXISTS used_phones_and_tablets_pricing_dataset_split_test;

SELECT * FROM used_phones_and_tablets_pricing_dataset_split_train;

SELECT * FROM used_phones_and_tablets_pricing_dataset_split_test;

-- antrenare https://madlib.apache.org/docs/latest/group__grp__decision__tree.html
DROP TABLE IF EXISTS used_phones_and_tablets_pricing_dataset_split_train_out, used_phones_and_tablets_pricing_dataset_split_train_out_group, used_phones_and_tablets_pricing_dataset_split_train_out_summary;

SELECT forest_train(
    'used_phones_and_tablets_pricing_dataset_split_train', -- source table
    'used_phones_and_tablets_pricing_dataset_split_train_out', -- output model table
    'id', -- id column
    'normalized_new_price', -- response
    '"device_brand", "os", "screen_size", "four_g", "five_g", "rear_camera_mp", "front_camera_mp", "internal_memory", "ram", "battery", "weight", "release_year", "days_used", "normalized_used_price"', -- features
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
    'null_as_category=TRUE'
);

-- view model
SELECT * FROM used_phones_and_tablets_pricing_dataset_split_train_out;

SELECT * FROM used_phones_and_tablets_pricing_dataset_split_train_out_summary;

SELECT get_tree('used_phones_and_tablets_pricing_dataset_split_train_out',1,7,FALSE);

-- predictie
DROP TABLE IF EXISTS prediction_results_used_phones_and_tablets;
SELECT forest_predict(
    'used_phones_and_tablets_pricing_dataset_split_train_out', -- tree model
    'used_phones_and_tablets_pricing_dataset', -- new data table
    'prediction_results_used_phones_and_tablets', -- output table
    'response'); -- show response

-- view scoring
DROP TABLE IF EXISTS scoring_results_used_phones_and_tablets_pricing_dataset;
CREATE TABLE scoring_results_used_phones_and_tablets_pricing_dataset AS SELECT  i.normalized_new_price, p.estimated_normalized_new_price FROM used_phones_and_tablets_pricing_dataset i, prediction_results_used_phones_and_tablets p WHERE i.id=p.id ORDER BY p.id;
SELECT * FROM scoring_results_used_phones_and_tablets_pricing_dataset;

--r2 score
DROP TABLE IF EXISTS scoring_results_used_phones_and_tablets_pricing_dataset_out_r2;
SELECT adjusted_r2_score('scoring_results_used_phones_and_tablets_pricing_dataset', 'scoring_results_used_phones_and_tablets_pricing_dataset_out_r2', 'estimated_normalized_new_price', 'normalized_new_price', 3, 100);
SELECT * FROM scoring_results_used_phones_and_tablets_pricing_dataset_out_r2;

--mean abs percentage error
DROP TABLE IF EXISTS scoring_results_used_phones_and_tablets_pricing_dataset_out_mean_sqrt_err;
SELECT mean_squared_error('scoring_results_used_phones_and_tablets_pricing_dataset', 'scoring_results_used_phones_and_tablets_pricing_dataset_out_mean_sqrt_err', 'estimated_normalized_new_price', 'normalized_new_price');
SELECT * FROM scoring_results_used_phones_and_tablets_pricing_dataset_out_mean_sqrt_err;