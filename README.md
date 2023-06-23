# bachelor_thesis_project

From a theoretical point of view, the work contains the study of the training of a Machine Learning model which involves several stages: targeting the data, their preprocessing, model training, model evaluation, transition to production. These stages assume a decoupling between the safety systems (databases) and the technologies used to train the model (usually based on Python, Matlab).
A solution to simplify the process is to perform the above steps in the systems that store the data (databases).
Within this topic, I want to evaluate the tools available in the market that allow In-Database Machine Learning and the implementation of models on various data sets.
By properly documenting the steps in using these tools, the resulting resources (documentation and source code) can be used in educational scenarios.
The API establishes a database connection by calling get_db_connection() and gets a cursor object for executing PostgreSQL queries to predict data.

Datasets: https://www.kaggle.com/

In-Database Machine Learning tools:
  <ul>
  <li>MADlib: https://madlib.apache.org/</li>
  <li id="bar">PostgresML: https://postgresml.org/</li>
</ul>
