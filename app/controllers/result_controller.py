from flask import render_template, request, redirect, Blueprint, session, jsonify
import requests, json

#Models 
from app.models import RedisCache
from app.models import ResultModels
import json, ast, pickle

result = Blueprint("result", __name__, url_prefix="/result")

@result.route("/show", methods = ['GET', 'POST'])
def show_result():
    """
    Show runset result
    """
    if request.method == 'GET':        
        return jsonify({'status': 'Error!', 'message': 'Please use POST request'})
    else:
        data = session['data']
        arg1 = data['arg1'].lower()
        rel = data['rel'].lower()
        arg2 = data['arg2'].lower()
        where = arg2.split(' ')[0]
        arg2 = arg2.replace(' ','')

        hash_name = 'runset_map'
        hash_key = '{0}_{1}_{2}'.format(arg1, rel, arg2)
        runset_id = RedisCache.fetchValue(hash_name, hash_key, 'runset_id')
        modler = ResultModels()
        response = modler.show_result(int(runset_id))
        fetched_data = json.loads(response.text)

        result_id = modler.get_resultId(int(runset_id))
        '''Changing dictionary key'''
        if len(fetched_data['data']) > 0: 
            items = fetched_data['data']
            new_data = []

            for item in items:

                obj = item['object_key'].replace('_', '')

                if where.lower() in obj.lower() and rel.lower() in item['property_key'].lower():               
                    new_item = {}
                    filtered_item = {}
                    for key, value in item.iteritems():
                        if str(key) == 'r'+str(result_id):
                            key = 'normalized'
                        if str(key) == 'r'+str(result_id)+'_bool':
                            key = 'value'
                        new_item[key] = value
                    new_item['link'] = 'http://localhost:4000/runs/'+str(result_id)+'/explain?claim_id='+str(new_item['claim_id'])
                    if new_item['value'] == 't':
                        new_item['color'] = 'Green'
                    else:
                        new_item['color'] = 'Red'
                    
                    filtered_item['color'] = new_item['color']
                    filtered_item['link'] = new_item['link']
                    filtered_item['normalized'] = new_item['normalized']
                    filtered_item['unique_key'] = new_item['property_key']+'_'+new_item['object_key']
                    filtered_item['property_value'] = new_item['property_value']
                    filtered_item['source_id'] = new_item['source_id']
                    filtered_item['claim_id'] = new_item['claim_id']
                    filtered_item['key_value'] = str(filtered_item['unique_key'])+'_'+str(new_item['property_value'])
                    filtered_item['source_link'] = str(RedisCache.fetchValue('source_map', hash_key, filtered_item['source_id']))

                    new_data.append(filtered_item)

            fetched_data['data'] = new_data

        '''Sorting Keys'''
        if len(fetched_data['data']) > 0:
            items = fetched_data['data']
            positive = []
            negative = []
            for item in items:
                if item['color'] == 'Green':
                    positive.append(item)
                else:
                    negative.append(item)

            positive = sorted(positive, key=lambda k: k['normalized'], reverse = True) 
            negative = sorted(negative, key=lambda k: k['normalized'], reverse = True) 
            newlist = positive + negative
            fetched_data['data'] = newlist

        '''Combining Sources'''
        if len(fetched_data['data']) > 0:
            extracted_data = fetched_data['data']
            combined_data = []
            for dat in extracted_data:
                value = filter(lambda item: item['key_value'] == dat['key_value'], combined_data)
                if len(value) == 0:
                    current_value = dat
                    current_value['combined_sources'] = []
                    current_value['combined_sources'].append({'id': dat['source_id'], 'link': dat['link'], 'source_link': dat['source_link']})
                    combined_data.append(current_value)
                else:
                    for item in combined_data:
                        if item['key_value'] == dat['key_value']:
                            for k,v in item.iteritems():
                                if k == 'combined_sources':
                                    item['combined_sources'].append({'id': dat['source_id'], 'link': dat['link'], 'source_link': dat['source_link']})
            fetched_data['data'] = combined_data

        if response.status_code != 200:
            return jsonify({'status': 'Error!', 'message': 'No result found'})
        else:
            return jsonify({'status': 'Success!', 'message': 'Result found', 'data': fetched_data['data']})