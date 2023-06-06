-- mobile_price_classification_test && mobile_price_classification_train

-- creare tabel test
DROP TABLE IF EXISTS mobile_price_classification_test;

CREATE TABLE IF NOT EXISTS mobile_price_classification_test(
    id serial PRIMARY KEY,
    battery_power int,
    blue boolean,
    clock_speed float,
    dual_sim boolean,
    fc int,
    four_g boolean,
    int_memory int,
    m_dep float,
    mobile_wt int,
    n_cores int,
    pc int,
    px_height int,
    px_width int,
    ram int,
    sc_h int,
    sc_w int,
    talk_time int,
    three_g boolean,
    touch_screen boolean,
    wifi boolean
);

-- copiere fisiere in container-ul de docker
-- docker cp C:\Users\vultu\Desktop\mobile_price_classificaton\mobile_price_classificaton_test.csv postgres-madlib:/tmp/

-- incarcare date test
COPY mobile_price_classification_test
FROM '/tmp/mobile_price_classificaton_test.csv'
DELIMITER ','
CSV HEADER;

-- vizualizare date tabel test
SELECT * FROM mobile_price_classification_test LIMIT 10;

-- creare tabel train
DROP TABLE IF EXISTS mobile_price_classification_train;

CREATE TABLE IF NOT EXISTS mobile_price_classification_train(
    battery_power int,
    blue boolean,
    clock_speed float,
    dual_sim boolean,
    fc int,
    four_g boolean,
    int_memory int,
    m_dep float,
    mobile_wt int,
    n_cores int,
    pc int,
    px_height int,
    px_width int,
    ram int,
    sc_h int,
    sc_w int,
    talk_time int,
    three_g boolean,
    touch_screen boolean,
    wifi boolean,
    price_range int
);

-- copiere fisiere in container-ul de docker
-- docker cp C:\Users\vultu\Desktop\mobile_price_classificaton\mobile_price_classificaton_train.csv postgres-madlib:/tmp/

-- incarcare date train
COPY mobile_price_classification_train
FROM '/tmp/mobile_price_classificaton_train.csv'
DELIMITER ','
CSV HEADER;

-- add PK AI (corectie)
ALTER TABLE mobile_price_classification_train ADD COLUMN id SERIAL PRIMARY KEY;

-- verifica date
SELECT * FROM mobile_price_classification_train LIMIT 10;

-- antrenare https://madlib.apache.org/docs/latest/group__grp__decision__tree.html
DROP TABLE IF EXISTS mobile_price_classification_train_out, mobile_price_classification_train_out_group, mobile_price_classification_train_out_summary;
SELECT forest_train(
    'mobile_price_classification_train', -- source table
    'mobile_price_classification_train_out', -- output model table
    'id', -- id column
    'price_range', -- response
    '"battery_power", "blue", "clock_speed", "dual_sim", "fc", "four_g", "int_memory", "m_dep", "mobile_wt", "n_cores", "pc", "px_height", "px_width", "ram", "sc_h", "sc_w", "talk_time", "three_g", "touch_screen", "wifi"', -- features
    NULL, -- exclude columns
    NULL, -- grouping columns
    20::integer, -- number of trees
    2::integer, -- number of random features
    TRUE::boolean, -- variable importance
    1::integer, -- num_permutations
    8::integer, --max depth
    3::integer, --min split
    1::integer,  --min bucket
    10::integer  --number of splits per continuous variable
);

-- view model
SELECT * FROM mobile_price_classification_train_out;

SELECT * FROM mobile_price_classification_train_out_summary;

SELECT get_tree('mobile_price_classification_train_out',1,7,FALSE);

-- predictie
DROP TABLE IF EXISTS prediction_results_mobile_price_class;
SELECT forest_predict(
    'mobile_price_classification_train_out', -- tree model
    'mobile_price_classification_test', -- new data table
    'prediction_results_mobile_price_class', -- output table
    'prob'); -- show probability

-- view scoring
DROP TABLE IF EXISTS scoring_results_mobile_price_classification;
CREATE TABLE scoring_results_mobile_price_classification AS
    SELECT a prob0,
        b prob1,
        c prob2,
        d prob3,
        CASE
            WHEN greatest(a,b,c,d) > 0.5 THEN TRUE
            ELSE FALSE
        END AS obs
    FROM (select estimated_prob_0 as a, estimated_prob_1 as b, estimated_prob_2 as c, estimated_prob_3 as d from prediction_results_mobile_price_class) x;
SELECT * FROM scoring_results_mobile_price_classification;

--binary classifier
DROP TABLE IF EXISTS scoring_results_mobile_price_classification_bin_class;
SELECT binary_classifier('scoring_results_mobile_price_classification', 'scoring_results_mobile_price_classification_bin_class', 'prob0', 'obs');
SELECT * FROM scoring_results_mobile_price_classification_bin_class WHERE threshold=0.5;