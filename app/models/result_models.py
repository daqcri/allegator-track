'''
Models pertaining to a runset result
'''

import os
import requests, json


class ResultModels:

    def __init__(self):
        self.user_token = os.environ.get("USER_TOKEN", None)
   
    def show_result(self, runset_id):
        url = "http://localhost:4000/runsets/"+str(runset_id)+"/results"
        data = {"user_token": self.user_token, "extra_normalized": 1}
        data = json.dumps(data)
        #print data
        r = requests.get(url, data = data, headers = {'Content-Type': 'application/json'})
        return r

    def get_resultId(self, runset_id):
        #print runset_id
        url = "http://localhost:4000/runsets"
        data = {"user_token": self.user_token}
        data = json.dumps(data)
        #print data
        r = requests.get(url, data = data, headers = {'Content-Type': 'application/json'})
        #print r.text
        response = json.loads(r.text)
        #print response

        result_id = None
        for responses in response:
            #print responses['id']
            #print runset_id
            if responses['id'] == runset_id:
                result_id = responses['runs'][0]['id']
        return result_id

if __name__ == '__main__':
    modler = ResultModels()
    #response = modler.show_result(83)
    result = modler.get_resultId(83)
    print result
    #print response  
    #print response
    #print response.text
    #ids = modler.fetch_ids()
    #print ids
    #modler.clear(ids)