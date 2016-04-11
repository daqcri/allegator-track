from flask import render_template, request, redirect, Blueprint, session, jsonify, url_for
import requests, ast

#Models 
from app.models import RedisCache
from app.models import QueryModels, DatasetModels, ResultModels, RunsetModels

query = Blueprint("query", __name__, url_prefix="/query")

@query.route("", methods = ['GET', 'POST'])
def parse_query():
    """
    Fetch database_id of a given query
    """

    if request.method != 'POST':
        return jsonify({'status': 'Error!', 'message': 'Please use POST request'})
    else:   
        data = request.get_json()

        if data == None:
            return jsonify({'status': 'Error!', 'message': 'Please pass parameters'})
        else:           
            dataset_modler = DatasetModels()
            uploaded_datasets = dataset_modler.fetch_ids('claims')

            if uploaded_datasets == []:
                #return redirect(url_for('dataset.upload'), code=307)
                return jsonify({'status': 'Error!', 'message': 'No dataset found'})

            query = data['query'].lower()
            session['original_query'] = data['query']
            query_modler = QueryModels()
            clean_query = query_modler.clean_text(query)
            session['query'] = clean_query
            
            redis_datasets = RedisCache.getKV('uploaded_datasets')

            if redis_datasets == 'None':
                dataset_modler.store_values(uploaded_datasets)
                RedisCache.setKV('uploaded_datasets', uploaded_datasets)
            else:
                if uploaded_datasets != ast.literal_eval(redis_datasets):
                    dataset_modler.store_values(uploaded_datasets)
                    RedisCache.setKV('uploaded_datasets', uploaded_datasets)

            clean_query = query_modler.clean_text(query)
            stored_queries = RedisCache.getKeys('query_map')
            query = query_modler.closest_matching(clean_query, stored_queries)
            if query == None:
                return jsonify({'status': 'Error!', 'message': 'No query found'})

            session['object_key'] = RedisCache.fetchValue(query, '', 'object_key')
            session['property_key'] = RedisCache.fetchValue(query, '', 'property_key')

            if session['object_key'] == None or session['property_key'] == None:
                return jsonify({'status': 'Error!', 'message': 'No dataset found'})

            redis_datasets = RedisCache.getKV('uploaded_datasets')
            
            if redis_datasets == None:
                RedisCache.setKV('uploaded_datasets', uploaded_datasets)

            if uploaded_datasets == ast.literal_eval(redis_datasets):
                runset_modler = RunsetModels()
                created_runsets = runset_modler.fetch_ids()

                if created_runsets == []:
                    return redirect(url_for('runset.create_runset'), code=307)
                else:
                    current_runset = sorted(created_runsets, reverse = True)[0]
                    redis_runset = RedisCache.fetchValue('result_map', '', 'runset_id')

                    if redis_runset != 'None':
                        redis_runset = int(redis_runset )
                        if redis_runset == current_runset:
                            return redirect(url_for('result.show_result'), code=307)
                        else:
                            return redirect(url_for('runset.create_runset'), code=307)
                    else: 
                        RedisCache.createHash('result_map', '', {"runset_id": current_runset})
                        return redirect(url_for('result.show_result'), code=307)
            else:
                return redirect(url_for('runset.create_runset'), code=307)