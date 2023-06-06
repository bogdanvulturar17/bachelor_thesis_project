-- mobile_price_classification_test && mobile_price_classification_train
-- creare tabel test
DROP TABLE IF EXISTS pgml.mobile_price_classification_test;
CREATE TABLE IF NOT EXISTS pgml.mobile_price_classification_test(
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
-- docker cp C:\Users\vultu\Desktop\mobile_price_classificaton\mobile_price_classificaton_test.csv 874afa31e56bbbd80b281c759efef70c455acbb968473f7cadc5768dca573146:/tmp/

-- incarcare date test
COPY pgml.mobile_price_classification_test
FROM '/tmp/mobile_price_classification_test.csv'
DELIMITER ','
CSV HEADER;

-- VIEW THE DATASET test
SELECT * FROM pgml.mobile_price_classification_test LIMIT 10;

-- creare tabel train
DROP TABLE IF EXISTS pgml.mobile_price_classification_train;
CREATE TABLE IF NOT EXISTS pgml.mobile_price_classification_train(
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
-- docker cp C:\Users\vultu\Desktop\mobile_price_classification\mobile_price_classification_train.csv 874afa31e56bbbd80b281c759efef70c455acbb968473f7cadc5768dca573146:/tmp/

-- copiere fisiere din container
COPY pgml.mobile_price_classification_train
FROM '/tmp/mobile_price_classification_train.csv'
DELIMITER ','
CSV HEADER;

-- add PK AI (corectie)
ALTER TABLE pgml.mobile_price_classification_train ADD COLUMN id SERIAL PRIMARY KEY;

-- VIEW THE DATASET train
SELECT * FROM pgml.mobile_price_classification_train LIMIT 10;

-- snapshots are automatically random ordered at creation, so this view is just for fun
DROP VIEW IF EXISTS pgml.mobile_price_classification_train_view;
CREATE VIEW pgml.mobile_price_classification_train_view AS SELECT * FROM pgml.mobile_price_classification_train ORDER BY random() LIMIT 100;

-- training
SELECT * FROM pgml.train(
  project_name => 'mobile_price_classification',
  task => 'classification',
  relation_name => 'pgml.mobile_price_classification_train',
  y_column_name => 'price_range',
  algorithm=> 'random_forest'
);

-- predictions
SELECT price_range, pgml.predict('mobile_price_classification', ARRAY[battery_power, CAST(blue AS integer), clock_speed, CAST(dual_sim AS integer), fc, CAST(four_g AS integer), int_memory, m_dep, mobile_wt, n_cores, pc, px_height, px_width, ram, sc_h, sc_w, talk_time, CAST(three_g AS integer), CAST(touch_screen AS integer), CAST(wifi AS integer), id]) AS prediction
FROM pgml.mobile_price_classification_train LIMIT 20;

-- ensembles
SELECT * FROM pgml.train('mobile_price_classification_train', algorithm => 'random_forest', hyperparams => '{"n_estimators": 10}');

-- check out all that hard work
SELECT trained_models.* FROM pgml.trained_models
JOIN pgml.models on models.id = trained_models.id
ORDER BY models.metrics->>'f1' DESC LIMIT 5;

-- deploy the random_forest model for prediction use
SELECT * FROM pgml.deploy('mobile_price_classification_train', 'most_recent', 'random_forest');

-- check out that throughput
SELECT * FROM pgml.deployed_models ORDER BY deployed_at DESC LIMIT 5;

-- do a hyperparam search on your favorite algorithm
SELECT pgml.train(
    'mobile_price_classification_train',
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
SELECT * FROM pgml.deploy('mobile_price_classification_train', 'best_score');
SELECT * FROM pgml.deploy('mobile_price_classification_train', 'most_recent');
SELECT * FROM pgml.deploy('mobile_price_classification_train', 'rollback');
SELECT * FROM pgml.deploy('mobile_price_classification_train', 'best_score', 'svm');

-- improved predictions
SELECT price_range, pgml.predict('mobile_price_classification', ARRAY[battery_power, CAST(blue AS integer), clock_speed, CAST(dual_sim AS integer), fc, CAST(four_g AS integer), int_memory, m_dep, mobile_wt, n_cores, pc, px_height, px_width, ram, sc_h, sc_w, talk_time, CAST(three_g AS integer), CAST(touch_screen AS integer), CAST(wifi AS integer), id]) AS prediction
FROM pgml.mobile_price_classification_train LIMIT 20;