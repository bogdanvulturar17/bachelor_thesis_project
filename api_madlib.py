import psycopg2
from flask import Flask, jsonify, request


app = Flask(__name__)


def get_db_connection():
    conn = psycopg2.connect(host='localhost', user='postgres', dbname='postgres', port=5432)
    return conn


@app.route('/get_data', methods=['POST'])
def get_data():
    # get json payload from request
    parameters = request.get_json()

    # connect to the database
    conn = get_db_connection()
    cur = conn.cursor()

    #parameter creation
    mobile_price_prediction = parameters['mobile_price_prediction']
    mobile_price_prediction_api = parameters['mobile_price_prediction_api']
    prediction_results_mobile_price_prediction = parameters['prediction_results_mobile_price_prediction']

    #creating a copy of the initial table, running the prediction algorithm, showing the scoring results
    insert = f"CREATE TABLE IF NOT EXISTS {mobile_price_prediction_api} AS SELECT * FROM {mobile_price_prediction}"
    delete_prediction_results = f"DROP TABLE IF EXISTS {prediction_results_mobile_price_prediction}"
    prediction = f"SELECT forest_predict('mobile_price_prediction_split_train_out', '{mobile_price_prediction_api}', '{prediction_results_mobile_price_prediction}','response');"
    scoring = f"SELECT r.id, r.estimated_price, i.price FROM {mobile_price_prediction_api} i, {prediction_results_mobile_price_prediction} r WHERE i.id=r.id ORDER BY r.id LIMIT 20;"

    #cursors that executes every instrucrion
    cur.execute(insert)
    cur.execute(delete_prediction_results)
    cur.execute(prediction)
    cur.execute(scoring)

    results = cur.fetchall()
    return jsonify(results)


if __name__ == '__main__':
    app.run(debug=True)
