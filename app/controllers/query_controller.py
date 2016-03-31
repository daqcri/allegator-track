from flask import render_template, request, redirect, Blueprint, session, jsonify, url_for
import requests

#Models 
from app.models import RedisCache

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
            query = data['query'].lower()

            if 'people' in query.lower() and 'killed' in query.lower() and 'bombing' in query.lower():
                arg1 = 'people'
                rel = 'killed'
                arg2 = 'parisbombing'
                session['data'] = {'arg1': arg1, 'arg2': arg2, 'rel': rel}
            else:
                arg1 = 'none'
                rel = 'none'
                arg2 = 'none'

            hash_name = 'dataset_map'
            hash_key = '{0}_{1}_{2}'.format(arg1, rel, arg2)

            if not RedisCache.isExists(hash_name, hash_key):
                return jsonify({'status': 'Error!', 'message': 'Key does not exists'})
            else:
                value = RedisCache.fetchValue(hash_name, hash_key, 'dataset_id')

                if value == 'None':
                    return redirect(url_for('dataset.upload'), code = 307)
                else:

                    return redirect(url_for('runset.create_runset'), code=307)