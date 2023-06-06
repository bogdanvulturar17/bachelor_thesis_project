-- mobile_price_prediction

-- creare tabel train
DROP TABLE IF EXISTS mobile_price_prediction;

CREATE TABLE IF NOT EXISTS mobile_price_prediction(
    Product_id int,
    Price int,
    Sale int,
    weight float,
    resoloution float,
    ppi int,
    cpu_core int,
    cpu_freq float,
    internal_mem float,
    ram float,
    RearCam float,
    Front_Cam float,
    battery int,
    thickness float
);

-- copiere fisiere in container-ul de docker
-- docker cp C:\Users\vultu\Desktop\mobile_price_prediction\mobile_price_prediction.csv postgres-madlib:/tmp/

-- incarcare date train
COPY mobile_price_prediction
FROM '/tmp/mobile_price_prediction.csv'
DELIMITER ','
CSV HEADER;

-- add PK AI (corectie)
ALTER TABLE mobile_price_prediction ADD COLUMN id SERIAL PRIMARY KEY;

-- verifica date
SELECT * FROM mobile_price_prediction;

SELECT train_test_split(
    'mobile_price_prediction', --Source Table
    'mobile_price_prediction_split', -- Output Table
    0.25, -- Sample proportion
    NULL, -- Sample proportion
    NULL, -- Strata definition
    '*', -- Columns to out
    FALSE, -- Sample without replacement
    TRUE --Do not separate output tables
);

DROP TABLE IF EXISTS mobile_price_prediction_split_train;

DROP TABLE IF EXISTS mobile_price_prediction_split_test;

SELECT * FROM mobile_price_prediction_split_train;

SELECT * FROM mobile_price_prediction_split_test;

-- antrenare https://madlib.apache.org/docs/latest/group__grp__decision__tree.html
DROP TABLE IF EXISTS mobile_price_prediction_split_train_out, mobile_price_prediction_split_train_out_group, mobile_price_prediction_split_train_out_summary;

SELECT forest_train(
    'mobile_price_prediction_split_train', -- source table
    'mobile_price_prediction_split_train_out', -- output model table
    'id', -- id column
    'price', -- response
    '"product_id", "sale", "weight", "resoloution", "ppi", "cpu_core", "cpu_freq", "internal_mem", "ram", "rearcam", "front_cam", "battery", "thickness"', -- features
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
SELECT * FROM mobile_price_prediction_split_train_out;

SELECT * FROM mobile_price_prediction_split_train_out_summary;

SELECT * FROM mobile_price_prediction_split_train_out_group;

SELECT get_tree('mobile_price_prediction_split_train_out',1,7,FALSE);

-- predictie
DROP TABLE IF EXISTS prediction_results_mobile_price_prediction;
SELECT forest_predict(
    'mobile_price_prediction_split_train_out', -- tree model
    'mobile_price_prediction', -- new data table
    'prediction_results_mobile_price_prediction', -- output table
    'response'); -- show response

-- view scoring
DROP TABLE IF EXISTS scoring_results_mobile_price_prediction;
CREATE TABLE scoring_results_mobile_price_prediction AS SELECT r.estimated_price, i.price FROM prediction_results_mobile_price_prediction r, mobile_price_prediction i WHERE r.id=i.id ORDER BY r.id;
SELECT * FROM scoring_results_mobile_price_prediction;

--r2 score
DROP TABLE IF EXISTS scoring_results_mobile_price_prediction_out_r2;
SELECT adjusted_r2_score('scoring_results_mobile_price_prediction', 'scoring_results_mobile_price_prediction_out_r2', 'estimated_price', 'price', 3, 100);
SELECT * FROM scoring_results_mobile_price_prediction_out_r2;

--mean abs percentage error
DROP TABLE IF EXISTS scoring_results_mobile_price_prediction_out_mean_sqrt_err;
SELECT mean_squared_error('scoring_results_mobile_price_prediction', 'scoring_results_mobile_price_prediction_out_mean_sqrt_err', 'estimated_price', 'price');
SELECT * FROM scoring_results_mobile_price_predictsion_out_mean_sqrt_err;