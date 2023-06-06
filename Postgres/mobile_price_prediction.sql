-- mobile_price_prediction

-- creare tabel train
DROP TABLE IF EXISTS pgml.mobile_price_prediction;

CREATE TABLE IF NOT EXISTS pgml.mobile_price_prediction(
    Product_id   int,
    Price        int,
    Sale         int,
    weight       float,
    resoloution  float,
    ppi          int,
    cpu_core     int,
    cpu_freq     float,
    internal_mem float,
    ram          float,
    RearCam      float,
    Front_Cam    float,
    battery      int,
    thickness    float
);

-- copiere fisiere in container-ul de docker
-- docker cp C:\Users\vultu\Desktop\mobile_price_prediction\mobile_price_prediction.csv 874afa31e56bbbd80b281c759efef70c455acbb968473f7cadc5768dca573146:/tmp/

-- incarcare date train
COPY pgml.mobile_price_prediction
FROM '/tmp/mobile_price_prediction.csv'
DELIMITER ','
CSV HEADER;

-- add PK AI (corectie)
ALTER TABLE pgml.mobile_price_prediction ADD COLUMN id SERIAL PRIMARY KEY;

-- verifica date
SELECT * FROM pgml.mobile_price_prediction;

-- snapshots are automatically random ordered at creation, so this view is just for fun
DROP VIEW IF EXISTS pgml.mobile_price_prediction_view;
CREATE VIEW pgml.mobile_price_prediction_view AS SELECT *FROM pgml.mobile_price_prediction ORDER BY random()LIMIT 100;

-- training
SELECT * FROM pgml.train(
  project_name => 'mobile_price_prediction',
  task => 'regression',
  relation_name => 'pgml.mobile_price_prediction',
  y_column_name => 'price',
  algorithm=> 'random_forest'
);

-- predictions
SELECT Price, pgml.predict('mobile_price_prediction', ARRAY[Product_id, Price, Sale, weight, resoloution, ppi, cpu_core, cpu_freq, internal_mem, ram, RearCam, Front_Cam, battery, thickness]) AS prediction
FROM pgml.mobile_price_prediction LIMIT 20;

-- ensembles
SELECT * FROM pgml.train('mobile_price_prediction', algorithm => 'random_forest', hyperparams => '{"n_estimators": 10}');

-- check out all that hard work
SELECT trained_models.* FROM pgml.trained_models
JOIN pgml.models on models.id = trained_models.id
ORDER BY models.metrics->>'f1' DESC LIMIT 5;

-- deploy the random_forest model for prediction use
SELECT * FROM pgml.deploy('mobile_price_prediction', 'most_recent', 'random_forest');

-- check out that throughput
SELECT * FROM pgml.deployed_models ORDER BY deployed_at DESC LIMIT 5;

-- do a hyperparam search on your favorite algorithm
SELECT pgml.train(
    'mobile_price_prediction',
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
SELECT * FROM pgml.deploy('mobile_price_prediction', 'best_score');
SELECT * FROM pgml.deploy('mobile_price_prediction', 'most_recent');
SELECT * FROM pgml.deploy('mobile_price_prediction', 'rollback');
SELECT * FROM pgml.deploy('mobile_price_prediction', 'best_score', 'svm');

-- improved predictions
SELECT Price, pgml.predict('mobile_price_prediction', ARRAY[Product_id, Price, Sale, weight, resoloution, ppi, cpu_core, cpu_freq, internal_mem, ram, RearCam, Front_Cam, battery, thickness]) AS prediction
FROM pgml.mobile_price_prediction;