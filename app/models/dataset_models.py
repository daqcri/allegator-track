'''
Models pertaining to dataset
'''

import requests
import json
import os

class DatasetModels:

    def __init__(self):
        self.user_token = os.environ.get("USER_TOKEN", None)
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
            requests.delete(url, data = {'user_token': self.user_token  })

if __name__ == '__main__':
    modler = DatasetModels()
    #status_code = modler.upload_dataset('https://docs.google.com/spreadsheets/d/1BIUVypETaWmTCxfkvCcZlkAh4bNUP8zA94r7jPjBzbE/export?format=csv', 'claims', 'test.csv')     
    #print status_code
    ids = modler.fetch_ids('claims')
    print ids
    #smodler.clear(ids)