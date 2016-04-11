'''
Models pertaining to a runset
'''

import requests, json
import os
from dataset_models import DatasetModels


class RunsetModels:

    def __init__(self):
        self.user_token = os.environ.get("USER_TOKEN", None)
        self.base = os.environ.get("DAFNA_URL", None)

    def fetch_ids(self):
        url = self.base+'/runsets'
        r = requests.get(url, data = {'user_token': self.user_token})
        data = r.json()

        ids = []
        for runset in data:
            ids.append(runset['id'])
        return ids
   
    def create_runset(self, datasets, checked_algo, general_config):
        modler = DatasetModels()
        url = self.base + "/runsets"
        combined_datasets = {}
        for dataset in datasets:
            combined_datasets[str(dataset)] = "1"
        data = {"user_token": self.user_token, "datasets": combined_datasets, "checked_algo": checked_algo, "general_config": general_config}
        data = json.dumps(data)
        #print data
        r = requests.post(url, data = data, headers = {'Content-Type': 'application/json'})
        #print r.status_code 
        return r.status_code

    def clear(self, ids):
        for runset_id in ids:
            base_url = self.base+'/runsets/'
            url = base_url+str(runset_id)
            requests.delete(url, data = {'user_token': self.user_token  })

    def clear_previous(self, ids, current_id):
        for runset_id in ids:
            if runset_id != current_id:
                base_url = self.base+'/runsets/'
                url = base_url+str(runset_id)
                requests.delete(url, data = {'user_token': self.user_token  })

if __name__ == '__main__':
    modler = RunsetModels()
    status_code = modler.create_runset("57", {"Accu": ["0.2", "0", "100", "0.5", "false", "true", "true", "false"]}, ["0.001", "0.8", "1", "0.4"])     
    print status_code
    #ids = modler.fetch_ids()
    #print ids
    #modler.clear(ids)