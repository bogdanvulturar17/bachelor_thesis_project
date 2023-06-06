-- telecom_churn_dataset_20_train

-- creare tabel train
DROP TABLE IF EXISTS telecom_churn_dataset_20_train;

CREATE TABLE IF NOT EXISTS telecom_churn_dataset_20_train(
    State varchar(2),
    Account_length int,
    Area_code int,
    International_plan boolean,
    Voice_mail_plan boolean,
    Number_vmail_messages int,
    Total_day_minutes float,
    Total_day_calls int,
    Total_day_charge float,
    Total_eve_minutes float,
    Total_eve_calls int,
    Total_eve_charge float,
    Total_night_minutes float,
    Total_night_calls int,
    Total_night_charge float,
    Total_intl_minutes float,
    Total_intl_calls int,
    Total_intl_charge float,
    Customer_service_calls int,
    Churn boolean);

-- copiere fisiere in container-ul de docker
-- docker cp C:\Users\vultu\Desktop\telecom_churn_dataset\telecom_churn_dataset_20_train.csv postgres-madlib:/tmp/

-- incarcare date train
COPY telecom_churn_dataset_20_train
FROM '/tmp/telecom_churn_dataset_20_train.csv'
DELIMITER ','
CSV HEADER;

-- add PK AI (corectie)
ALTER TABLE telecom_churn_dataset_20_train ADD COLUMN id SERIAL PRIMARY KEY;

-- verifica date
SELECT * FROM telecom_churn_dataset_20_train;

-- creare tabel test
DROP TABLE IF EXISTS telecom_churn_dataset_80_test;

CREATE TABLE IF NOT EXISTS telecom_churn_dataset_80_test(
    State varchar(2),
    Account_length int,
    Area_code int,
    International_plan boolean,
    Voice_mail_plan boolean,
    Number_vmail_messages int,
    Total_day_minutes float,
    Total_day_calls int,
    Total_day_charge float,
    Total_eve_minutes float,
    Total_eve_calls int,
    Total_eve_charge float,
    Total_night_minutes float,
    Total_night_calls int,
    Total_night_charge float,
    Total_intl_minutes float,
    Total_intl_calls int,
    Total_intl_charge float,
    Customer_service_calls int,
    Churn boolean);

-- copiere fisiere in container-ul de docker
-- docker cp C:\Users\vultu\Desktop\telecom_churn_dataset\telecom_churn_dataset_80_test.csv postgres-madlib:/tmp/

-- incarcare date train
COPY telecom_churn_dataset_80_test
FROM '/tmp/telecom_churn_dataset_80_test.csv'
DELIMITER ','
CSV HEADER;

-- add PK AI (corectie)
ALTER TABLE telecom_churn_dataset_80_test ADD COLUMN id SERIAL PRIMARY KEY;

-- verifica date
SELECT * FROM telecom_churn_dataset_80_test;

-- antrenare https://madlib.apache.org/docs/latest/group__grp__decision__tree.html
DROP TABLE IF EXISTS telecom_churn_dataset_80_test_out, telecom_churn_dataset_80_test_out_group, telecom_churn_dataset_80_test_out_summary;

SELECT forest_train(
    'telecom_churn_dataset_20_train', -- source table
    'telecom_churn_dataset_20_train_out', -- output model table
    'id', -- id column
    'churn', -- response
    '"state", "account_length", "area_code", "international_plan", "voice_mail_plan", "number_vmail_messages", "total_day_minutes", "total_day_calls", "total_day_charge", "total_eve_minutes", "total_eve_calls", "total_eve_charge", "total_night_minutes", "total_night_calls", "total_night_charge", "total_intl_minutes", "total_intl_calls", "total_intl_charge", "customer_service_calls"',
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
SELECT * FROM telecom_churn_dataset_20_train_out;

SELECT * FROM telecom_churn_dataset_20_train_out_summary;

SELECT get_tree('telecom_churn_dataset_20_train_out',1,7,FALSE);

-- predictie
DROP TABLE IF EXISTS prediction_results_telecom_churn;
SELECT forest_predict(
    'telecom_churn_dataset_20_train_out', -- tree model
    'telecom_churn_dataset_80_test', -- new data table
    'prediction_results_telecom_churn', -- output table
    'prob'); -- show response

SELECT * FROM prediction_results_telecom_churn;

-- view scoring
DROP TABLE IF EXISTS scoring_results_telecom_churn;
CREATE TABLE scoring_results_telecom_churn AS
    SELECT b ADV,
        a FALS,
        CASE
            WHEN greatest(a,b) = a THEN FALSE
            ELSE TRUE
        END AS obs
    FROM (select estimated_prob_false as a, estimated_prob_true as b from prediction_results_telecom_churn) x;
SELECT * FROM scoring_results_telecom_churn;

--binary classifier
DROP TABLE IF EXISTS scoring_results_mobile_price_classification_test_conf_matrx;
SELECT binary_classifier('scoring_results_telecom_churn', 'scoring_results_mobile_price_classification_test_conf_matrx', 'adv', 'obs');
SELECT * FROM scoring_results_mobile_price_classification_test_conf_matrx WHERE threshold=0.5;