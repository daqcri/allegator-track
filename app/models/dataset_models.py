'''
Models pertaining to dataset
'''

import requests
import json
import os

from redis_cache import RedisCache

class DatasetModels:

    def __init__(self):
        self.user_token = os.environ.get("USER_TOKEN")
        self.base = os.environ.get("DAFNA_URL", None)
        
    def fetch_ids(self, dataset_type):
        url = self.base+'/datasets'
        r = requests.get(url, data = {'user_token': self.user_token, 'kind': dataset_type})
        data = r.json()
        sets = data['data']

        ids = []
        for dataset in sets:
            ids.append(dataset['id'])

        return ids

    def upload_dataset(self, dataset_url, dataset_type, original_filename):
        url = self.base+'/datasets'
        r = requests.post(url, data = {'user_token': self.user_token, 'kind': dataset_type, 'original_filename': original_filename, 'other_url': dataset_url})
        return r.status_code

    def clear(self, ids):
        for dataset_id in ids:
            base_url = self.base+'/datasets/'
            url = base_url+str(dataset_id)
            requests.delete(url, data = {'user_token': self.user_token})

    def store_values(self, uploaded_datasets):
        url = self.base+'/dataset_rows'
        new_values = {}
        for dataset in uploaded_datasets:
            dataset_string = "{0}{1}{2}{3}".format('datasets','[', dataset,']')
            r = requests.get(url, data = {"user_token": self.user_token, "search[regex]": "false", dataset_string: 1, "start": 0, "length": 1000})
            ds = r.json()
            d = ds['data']
            #print d
            for row in d:
                query = row['property_key']+'_'+row['object_key']
                if query not in new_values:
                    new_values[query] = {'property_key': row['property_key'], 'object_key': row['object_key']}
                    RedisCache.createHash('query_map', query, {'property_key': row['property_key'], 'object_key': row['object_key']})
            #print new_values

if __name__ == '__main__':
    modler = DatasetModels()
    #status_code = modler.upload_dataset('https://docs.google.com/spreadsheets/d/1BIUVypETaWmTCxfkvCcZlkAh4bNUP8zA94r7jPjBzbE/export?format=csv', 'claims', 'test.csv')     
    #print status_code
    ids = modler.fetch_ids('claims')
    modler.store_values(ids)
    #smodler.clear(ids)