'''
Models pertaining to a runset
'''

import requests, json
import os


class RunsetModels:

    def __init__(self):
        self.user_token = os.environ.get("USER_TOKEN", None)
        #self.user_token = 'fHRCD4f1ZLFsUN4DAqmm'

    def fetch_ids(self):
        r = requests.get("http://localhost:4000/runsets", data = {'user_token': self.user_token})
        data = r.json()

        ids = []
        for runset in data:
            ids.append(runset['id'])
        return ids
   
    def create_runset(self, dataset_id, checked_algo, general_config):
        url = "http://localhost:4000/runsets"
        data = {"user_token": self.user_token, "datasets": {dataset_id: "1"}, "checked_algo": checked_algo, "general_config": general_config}
        data = json.dumps(data)
        #print data
        r = requests.post(url, data = data, headers = {'Content-Type': 'application/json'})
        #print r.status_code 
        return r.status_code

    def clear(self, ids):
        for runset_id in ids:
            url = 'http://localhost:4000/runsets/'+str(runset_id)
            requests.delete(url, data = {'user_token': self.user_token  })

if __name__ == '__main__':
    modler = RunsetModels()
    status_code = modler.create_runset("57", {"Accu": ["0.2", "0", "100", "0.5", "false", "true", "true", "false"]}, ["0.001", "0.8", "1", "0.4"])     
    print status_code
    #ids = modler.fetch_ids()
    #print ids
    #modler.clear(ids)