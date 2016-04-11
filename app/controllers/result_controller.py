from flask import render_template, request, redirect, Blueprint, session, jsonify, url_for
import requests, json, os

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
        base = os.environ.get("DAFNA_URL", None)
        token = os.environ.get("USER_TOKEN", None)
       
        query = session['query']
        object_key = session['object_key']
        property_key = session['property_key']

        hash_name = 'result_map'
        runset_id = RedisCache.fetchValue(hash_name, '', 'runset_id')
        if runset_id == 'None':
            return redirect(url_for('runset.create_runset'), code=307)

        #print runset_id
        modler = ResultModels()
        response = modler.show_result(int(runset_id))
        #print response.text

        #print '\n\n'
        #print session
        fetched_data = json.loads(response.text)
        #print '\n\n'
        #print fetched_data
        #print '\n\n'

        result_id = modler.get_resultId(int(runset_id))
        '''Changing dictionary key'''
        if len(fetched_data['data']) > 0: 
            items = fetched_data['data']
            new_data = []
            base_url = base+'/runs/'

            for item in items:

                if item['object_key'] == object_key and item['property_key'] == property_key:
                    obj = item['object_key'].replace('_', '')       
                    new_item = {}
                    filtered_item = {}
                        
                    for key, value in item.iteritems():
                        if str(key) == 'r'+str(result_id):
                            key = 'normalized'
                        if str(key) == 'r'+str(result_id)+'_bool':
                            key = 'value'
                        new_item[key] = value
                        
                    new_item['link'] = base_url+str(result_id)+'/explain?claim_id='+str(new_item['claim_id'])+'&user_token='+token
                    new_item['original_query'] = session['original_query']
                    if new_item['value'] == 't':
                        new_item['color'] = 'Green'
                        new_item['value'] = 'True'
                    else:
                        new_item['color'] = 'Red'
                        new_item['value'] = 'False'
                        
                    filtered_item['color'] = new_item['color']
                    filtered_item['link'] = new_item['link']
                    filtered_item['normalized'] = new_item['normalized']
                    filtered_item['unique_key'] = new_item['property_key']+'_'+new_item['object_key']
                    filtered_item['property_value'] = new_item['property_value']
                    filtered_item['source_id'] = new_item['source_id']
                    filtered_item['claim_id'] = new_item['claim_id']
                    filtered_item['key_value'] = str(filtered_item['unique_key'])+'_'+str(new_item['property_value'])
                    val = new_item['property_value']
                    val = val.replace(' ','_')
                    filtered_item['source_link'] = str(RedisCache.fetchValue(filtered_item['unique_key'], val, filtered_item['source_id']))
                    #filtered_item['source_link'] = '#'
                    filtered_item['value'] = new_item['value']
                    filtered_item['original_query'] = new_item['original_query']
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
                    current_value['len'] = len(current_value['combined_sources'][0].keys())
                    combined_data.append(current_value)
                else:
                    for item in combined_data:
                        if item['key_value'] == dat['key_value']:
                            for k,v in item.iteritems():
                                if k == 'combined_sources':
                                    item['combined_sources'].append({'id': dat['source_id'], 'link': dat['link'], 'source_link': dat['source_link']})                       
            fetched_data['data'] = combined_data
            #print combined_data

        if response.status_code != 200:
            return jsonify({'status': 'Error!', 'message': 'No result found'})
        else:
            return jsonify({'status': 'Success!', 'message': 'Result found', 'data': fetched_data['data']})