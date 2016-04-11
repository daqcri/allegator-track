from flask import render_template, request, redirect, Blueprint, session, jsonify, url_for
import requests, json

#Models 
from app.models import RedisCache
from app.models import RunsetModels, DatasetModels
import json, ast, pickle

runset = Blueprint("runset", __name__, url_prefix="/runset")

@runset.route("/create", methods = ['GET', 'POST'])
def create_runset():
    """
    Create a runset with specific parameters
    """
    if request.method != 'POST':
        return jsonify({'status': 'Error!', 'message': 'Please use POST request'})
    else:

        hash_name = 'runset_map'
        modler = RunsetModels()
        current_ids = modler.fetch_ids()
        checked_algo = ast.literal_eval(RedisCache.fetchValue(hash_name, '', 'checked_algo'))
        general_config = ast.literal_eval(RedisCache.fetchValue(hash_name, '', 'general_config'))

        dataset_modler = DatasetModels()
        uploaded_datasets = dataset_modler.fetch_ids('claims')
        status = modler.create_runset(uploaded_datasets, checked_algo, general_config)

        if status != 200:
            return jsonify({'status': 'Error!', 'message': 'Could not create runset'})
        else:        
            new_ids = modler.fetch_ids()
            latest_id = list(set(new_ids) - set(current_ids))
            RedisCache.createHash('result_map', '', {'runset_id': latest_id[0]})
            return redirect(url_for('result.show_result'), code=307)