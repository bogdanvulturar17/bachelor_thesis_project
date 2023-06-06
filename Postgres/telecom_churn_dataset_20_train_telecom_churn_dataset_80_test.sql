-- telecom_churn_dataset_20_train && telecom_churn_dataset_80_test

DROP TABLE IF EXISTS pgml.telecom_churn_dataset_20_train;
CREATE TABLE IF NOT EXISTS pgml.telecom_churn_dataset_20_train(
    State text,
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
-- docker cp C:\Users\vultu\Desktop\telecom_churn_dataset\telecom_churn_dataset_20_train.csv 874afa31e56bbbd80b281c759efef70c455acbb968473f7cadc5768dca573146:/tmp/

-- incarcare date train
COPY pgml.telecom_churn_dataset_20_train
FROM '/tmp/telecom_churn_dataset_20_train.csv'
DELIMITER ','
CSV HEADER;

-- add PK AI (corectie)
ALTER TABLE pgml.telecom_churn_dataset_20_train ADD COLUMN id SERIAL PRIMARY KEY;

-- VIEW THE DATASET test
SELECT * FROM pgml.telecom_churn_dataset_20_train;

-- creare tabel test
DROP TABLE IF EXISTS pgml.telecom_churn_dataset_80_test;
CREATE TABLE IF NOT EXISTS pgml.telecom_churn_dataset_80_test(
    State text,
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
-- docker cp C:\Users\vultu\Desktop\telecom_churn_dataset\telecom_churn_dataset_80_test.csv 874afa31e56bbbd80b281c759efef70c455acbb968473f7cadc5768dca573146:/tmp/

-- incarcare date train
COPY pgml.telecom_churn_dataset_80_test
FROM '/tmp/telecom_churn_dataset_80_test.csv'
DELIMITER ','
CSV HEADER;

-- add PK AI (corectie)
ALTER TABLE pgml.telecom_churn_dataset_80_test ADD COLUMN id SERIAL PRIMARY KEY;

-- verifica date
SELECT * FROM pgml.telecom_churn_dataset_80_test;

-- snapshots are automatically random ordered at creation, so this view is just for fun
DROP VIEW IF EXISTS pgml.telecom_churn_dataset_20_train_view;
CREATE VIEW pgml.telecom_churn_dataset_20_train_view AS SELECT * FROM pgml.telecom_churn_dataset_20_train ORDER BY random() LIMIT 100;

-- training
SELECT * FROM pgml.train(
  project_name => 'telecom_churn_dataset_20_train',
  task => 'classification',
  relation_name => 'pgml.telecom_churn_dataset_20_train',
  y_column_name => 'churn',
  algorithm=> 'random_forest'
);

-- predictions
SELECT churn, pgml.predict('telecom_churn_dataset_20_train', ARRAY[Account_length, Area_code, CAST(International_plan AS integer), CAST(Voice_mail_plan AS integer), Number_vmail_messages, Total_day_minutes, Total_day_calls, Total_day_charge, Total_eve_minutes, Total_eve_calls, Total_eve_charge, Total_night_minutes, Total_night_calls, Total_night_charge, Total_intl_minutes, Total_intl_calls, Total_intl_charge, Customer_service_calls, CAST(churn AS integer)] || 20) AS prediction
FROM pgml.telecom_churn_dataset_80_test LIMIT 20;

-- ensembles
SELECT * FROM pgml.train('telecom_churn_dataset_20_train', algorithm => 'random_forest', hyperparams => '{"n_estimators": 10}');

-- check out all that hard work
SELECT trained_models.* FROM pgml.trained_models
JOIN pgml.models on models.id = trained_models.id
ORDER BY models.metrics->>'f1' DESC LIMIT 5;

-- deploy the random_forest model for prediction use
SELECT * FROM pgml.deploy('telecom_churn_dataset_20_train', 'most_recent', 'random_forest');

-- check out that throughput
SELECT * FROM pgml.deployed_models ORDER BY deployed_at DESC LIMIT 5;

-- do a hyperparam search on your favorite algorithm
SELECT pgml.train(
    'telecom_churn_dataset_20_train',
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
SELECT * FROM pgml.deploy('telecom_churn_dataset_20_train', 'best_score');
SELECT * FROM pgml.deploy('telecom_churn_dataset_20_train', 'most_recent');
SELECT * FROM pgml.deploy('telecom_churn_dataset_20_train', 'rollback');
SELECT * FROM pgml.deploy('telecom_churn_dataset_20_train', 'best_score', 'svm');

-- improved predictions
SELECT churn, pgml.predict('telecom_churn_dataset_20_train', ARRAY[Account_length, Area_code, CAST(International_plan AS integer), CAST(Voice_mail_plan AS integer), Number_vmail_messages, Total_day_minutes, Total_day_calls, Total_day_charge, Total_eve_minutes, Total_eve_calls, Total_eve_charge, Total_night_minutes, Total_night_calls, Total_night_charge, Total_intl_minutes, Total_intl_calls, Total_intl_charge, Customer_service_calls, CAST(churn AS integer)] || 20) AS prediction
FROM pgml.telecom_churn_dataset_80_test LIMIT 20;