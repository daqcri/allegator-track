'''
Save Source URL into redis
'''

import os
from app.models import RedisCache

directory = 'app/datasets'
for file in os.listdir(directory):
    init = True
    for line in open(directory+'/'+file):
        if not init:
            line = line.replace('"','')
            tokens = line.strip().split(',')
            object_id = tokens[0]
            property_name = tokens[1]
            property_value = tokens[2]
            source_id = tokens[3]
            source_url = tokens[4]
            key = property_name+'_'+object_id
            property_value = property_value.replace(' ', '_')
            RedisCache.createHash(key, property_value, {source_id: source_url})
        init = False