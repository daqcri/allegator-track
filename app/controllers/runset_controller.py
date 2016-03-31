from flask import render_template, request, redirect, Blueprint, session, jsonify, url_for
import requests, json

#Models 
from app.models import RedisCache
from app.models import RunsetModels
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

        data = session['data']
        arg1 = data['arg1'].lower()
        rel = data['rel'].lower()
        arg2 = data['arg2'].lower()
        arg2 = arg2.replace(' ','')

        hash_name = 'runset_map'

        hash_key = '{0}_{1}_{2}'.format(arg1, rel, arg2)

        runset_id = RedisCache.fetchValue(hash_name, hash_key, 'runset_id')

        if runset_id == 'None':
            modler = RunsetModels()
            current_ids = modler.fetch_ids()

            checked_algo = ast.literal_eval(RedisCache.fetchValue(hash_name, hash_key, 'checked_algo'))
            general_config = ast.literal_eval(RedisCache.fetchValue(hash_name, hash_key, 'general_config'))
            dataset_id = ast.literal_eval(RedisCache.fetchValue(hash_name, hash_key, 'dataset_id'))
            status = modler.create_runset(dataset_id, checked_algo, general_config)

            if status != 200:
                return jsonify({'status': 'Error!', 'message': 'Could not create runset'})
            else:        
                new_ids = modler.fetch_ids()
                latest_id = list(set(new_ids) - set(current_ids))
                RedisCache.createHash(hash_name, hash_key, {'runset_id': latest_id[0]})
                return redirect(url_for('result.show_result'), code=307)
                #return jsonify({'status': 'Success!', 'message': 'Runset created', 'runset_id': latest_id[0]})
        else:
            return redirect(url_for('result.show_result'), code=307)
            #return jsonify({'status': 'Success!', 'message': 'Runset found', 'runset_id': runset_id})
