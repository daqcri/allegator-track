from flask import Flask, render_template, make_response, jsonify
import redis
import os, ast

app = Flask(__name__)
app._redis = redis.from_url(os.environ.get("REDIS_URL") or 'redis://localhost:6379/0')
app.secret_key = os.environ.get("FLASK_SECRET")

from app.controllers import dataset_controller
from app.controllers import query_controller
from app.controllers import runset_controller
from app.controllers import result_controller
from models import QueryModels, DatasetModels, ResultModels, RunsetModels, RedisCache

app.register_blueprint(dataset_controller.dataset)
app.register_blueprint(query_controller.query)
app.register_blueprint(runset_controller.runset)
app.register_blueprint(result_controller.result)
 
@app.route('/')
def index():
    dataset_modler = DatasetModels()
    uploaded_datasets = dataset_modler.fetch_ids('claims')

    if uploaded_datasets == []:
        #return redirect(url_for('dataset.upload'), code=307)
        return jsonify({'status': 'Error!', 'message': 'No dataset found'})

    redis_datasets = RedisCache.getKV('uploaded_datasets')
    #print redis_datasets
    #print uploaded_datasets

    #print uploaded_datasets
    if redis_datasets == 'None' or "[]":
        dataset_modler.store_values(uploaded_datasets)
        RedisCache.setKV('uploaded_datasets', uploaded_datasets)
    else:
        if uploaded_datasets != ast.literal_eval(redis_datasets):
            dataset_modler.store_values(uploaded_datasets)
            RedisCache.setKV('uploaded_datasets', uploaded_datasets)

    runset_modler = RunsetModels()
    runset_ids = runset_modler.fetch_ids()

    if runset_ids != []:
        current_id = RedisCache.fetchValue('result_map', '', 'runset_id')
        if current_id != 'None':
            runset_modler.clear_previous(runset_ids, int(current_id))
        else:
            current_id = sorted(runset_ids, reverse = True)[0]
            runset_modler.clear_previous(runset_ids, int(current_id))
            RedisCache.createHash('result_map', '', {'runset_id': current_id})

    return make_response(open('app/templates/index.html').read())