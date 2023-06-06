-- used_phones_and_tablets_pricing_dataset

-- creare tabel train
DROP TABLE IF EXISTS pgml.used_phones_and_tablets_pricing_dataset;

CREATE TABLE IF NOT EXISTS pgml.used_phones_and_tablets_pricing_dataset(
device_brand text,
os text,
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
-- docker cp C:\Users\vultu\Desktop\used_phones_and_tablets_pricing_dataset\used_phones_and_tablets_pricing_dataset.csv 874afa31e56bbbd80b281c759efef70c455acbb968473f7cadc5768dca573146:/tmp/

-- incarcare date train
COPY pgml.used_phones_and_tablets_pricing_dataset
FROM '/tmp/used_phones_and_tablets_pricing_dataset.csv'
DELIMITER ','
CSV HEADER;

-- add PK AI (corectie)
ALTER TABLE pgml.used_phones_and_tablets_pricing_dataset ADD COLUMN id SERIAL PRIMARY KEY;

-- verifica date
SELECT * FROM pgml.used_phones_and_tablets_pricing_dataset;

-- snapshots are automatically random ordered at creation, so this view is just for fun
DROP VIEW IF EXISTS pgml.used_phones_and_tablets_pricing_dataset_view;
CREATE VIEW pgml.used_phones_and_tablets_pricing_dataset_view AS SELECT *FROM pgml.used_phones_and_tablets_pricing_dataset ORDER BY random()LIMIT 100;

-- Example of replacing NULL values in the column array column with default value 0
UPDATE pgml.used_phones_and_tablets_pricing_dataset SET rear_camera_mp = COALESCE(rear_camera_mp, 0);
UPDATE pgml.used_phones_and_tablets_pricing_dataset SET front_camera_mp = COALESCE(front_camera_mp, 0);
UPDATE pgml.used_phones_and_tablets_pricing_dataset SET ram = COALESCE(ram, 0);
UPDATE pgml.used_phones_and_tablets_pricing_dataset SET internal_memory = COALESCE(internal_memory, 0);
UPDATE pgml.used_phones_and_tablets_pricing_dataset SET battery = COALESCE(battery, 0);
UPDATE pgml.used_phones_and_tablets_pricing_dataset SET device_brand = COALESCE(device_brand, 0);
UPDATE pgml.used_phones_and_tablets_pricing_dataset SET weight = COALESCE(weight, 0);

-- training
SELECT * FROM pgml.train(
    project_name => 'used_phones_and_tablets_pricing_dataset',
    task => 'regression',
    relation_name => 'pgml.used_phones_and_tablets_pricing_dataset',
    y_column_name => 'normalized_new_price',
    algorithm=> 'random_forest',
    preprocess => '{
        "rear_camera_mp": {"impute": "mean", "scale":"standard"},
        "front_camera_mp": {"impute": "mean", "scale":"standard"},
        "internal_memory": {"impute": "mean", "scale":"standard"},
        "ram": {"impute": "mean", "scale":"standard"},
        "battery": {"impute": "mean", "scale":"standard"},
        "device_brand": {"impute": "mode", "scale":"standard"},
        "weight": {"impute": "mean", "scale":"standard"}
    }'
);

-- predictions
SELECT normalized_new_price, pgml.predict('used_phones_and_tablets_pricing_dataset', ARRAY[screen_size,CAST(four_g AS integer),CAST(five_g AS integer),rear_camera_mp,front_camera_mp,internal_memory,ram,battery,weight,release_year,days_used,normalized_used_price,normalized_new_price, id] || 15) AS prediction
FROM pgml.used_phones_and_tablets_pricing_dataset;

-- ensembles
SELECT * FROM pgml.train('used_phones_and_tablets_pricing_dataset', algorithm => 'random_forest', hyperparams => '{"n_estimators": 10}');

-- check out all that hard work
SELECT trained_models.* FROM pgml.trained_models
JOIN pgml.models on models.id = trained_models.id
ORDER BY models.metrics->>'f1' DESC LIMIT 5;

-- deploy the random_forest model for prediction use
SELECT * FROM pgml.deploy('used_phones_and_tablets_pricing_dataset', 'most_recent', 'random_forest');

-- check out that throughput
SELECT * FROM pgml.deployed_models ORDER BY deployed_at DESC LIMIT 5;

-- do a hyperparam search on your favorite algorithm
SELECT pgml.train(
    'used_phones_and_tablets_pricing_dataset',
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
SELECT * FROM pgml.deploy('used_phones_and_tablets_pricing_dataset', 'best_score');
SELECT * FROM pgml.deploy('used_phones_and_tablets_pricing_dataset', 'most_recent');
SELECT * FROM pgml.deploy('used_phones_and_tablets_pricing_dataset', 'rollback');
SELECT * FROM pgml.deploy('used_phones_and_tablets_pricing_dataset', 'best_score', 'svm');

-- improved predictions
SELECT normalized_new_price, pgml.predict('used_phones_and_tablets_pricing_dataset', ARRAY[screen_size,CAST(four_g AS integer),CAST(five_g AS integer),rear_camera_mp,front_camera_mp,internal_memory,ram,battery,weight,release_year,days_used,normalized_used_price,normalized_new_price, id] || 15) AS prediction
FROM pgml.used_phones_and_tablets_pricing_dataset LIMIT 20;