'''
Redis Cache Handler
'''

import redis
from app import app

class RedisCache:

    #def __init__(self):
    #    self.db = redis.Redis('localhost')

    @staticmethod
    def isExists(hash_name, key):
        hash_key = hash_name + ':' + key
        status = app._redis.exists(hash_key)
        return status

    @staticmethod
    def createHash(hash_name, key, valueset):
        if key != '':
            hash_key = hash_name + ':' + key
        else:
            hash_key = hash_name
        app._redis.hmset(hash_key, valueset)

    @staticmethod
    def fetchValue(hash_name, key, value_key):
        if key != '':
            hash_key = hash_name + ':' + key
        else:
            hash_key = hash_name
        value = app._redis.hget(hash_key, value_key)
        return value

    @staticmethod
    def setKV(key, value):
        app._redis.set(key, value)   

    @staticmethod
    def getKV(key):
        value = app._redis.get(key)
        return value

    @staticmethod
    def clear():
        app._redis.flushall()

    @staticmethod
    def getKeys(key_type):
        keys = app._redis.keys()
        result = []
        for key in keys:
            if key_type in key:
                result.append(key)
        return result

if __name__ == '__main__':
    redis_cache = RedisCache()
    #status = redis_cache.isExists('dataset_map', 'people_killed_parisAttacks')     
    #print status
    #redis_cache.createHash('dataset_map', 'people_killed_bostonBombing', {'dataset_id': 1})
    #value = redis_cache.fetchValue('dataset_map', 'people_killed_bostonBombing', 'dataset_id')
    #print value