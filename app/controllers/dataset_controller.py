from flask import render_template, request, redirect, Blueprint, session, jsonify, url_for

#Models 
from app.models import DatasetModels, QueryModels
from app.models import RedisCache
import time

dataset = Blueprint("dataset", __name__, url_prefix="/dataset", template_folder="views")

@dataset.route("/upload", methods = ['GET', 'POST'])
def upload():
    """
    Uploading a dataset with input parameters
    """
    
    if request.method == 'GET':
        return jsonify({'status': 'Error!', 'message': 'Please use POST request'})
    else:        
        modler = DatasetModels()
        url = RedisCache.fetchValue('dataset_map', '', 'dataset_url') 
        if not url:
            return jsonify({'status': 'Error!', 'message': 'Url not found'})

        file_name = RedisCache.fetchValue('dataset_map', '', 'dataset_name')    
        dataset_name = "{0}.csv".format(file_name)
        status_code = modler.upload_dataset(url, 'claims', dataset_name)
        if status_code != 200:
            return jsonify({'status': 'Error!', 'message': 'Dataset Not Uploaded'}) 

        dataset_name = RedisCache.fetchValue('dataset_map', '', 'dataset_name')
        current_dataset = modler.fetch_ids('claims')
        RedisCache.setKV('uploaded_datasets', current_dataset)
        time.sleep(15)
        modler.store_values(current_dataset)

        query_modler = QueryModels()
        stored_queries = RedisCache.getKeys('query_map')
        query = session['query']
        query = query_modler.closest_matching(query, stored_queries)
        if query == None:
            return jsonify({'status': 'Error!', 'message': 'No query found'})
        
        session['object_key'] = RedisCache.fetchValue(query, '', 'object_key')
        session['property_key'] = RedisCache.fetchValue(query, '', 'property_key')

        if session['object_key'] == None or session['property_key'] == None:
            return jsonify({'status': 'Error!', 'message': 'No dataset found'})
        else:    
            return redirect(url_for('query.parse_query'), code=307)