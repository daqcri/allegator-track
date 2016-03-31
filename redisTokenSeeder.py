'''
Saving values into redis db
'''

from app.models import RedisCache

class RedisTokenSeed(object):
    
    def clearDB(self):
        """
        Flush database
        """
        RedisCache.clear()

    def putTokens(self):
        """
        Saving query and concerned database value
        """
        RedisCache.createHash('dataset_map','people_killed_parisbombing', {'dataset_url': 'https://docs.google.com/spreadsheets/d/15S1ywe6UEefs3k9j103ZlYWNsfvOOXVZSTX4H5Pch5M/export?format=csv', 'dataset_id': None})
        RedisCache.createHash('runset_map','people_killed_parisbombing', {"runset_id": None, "dataset_id": None, "checked_algo": {"Accu": ["0.2", "0", "100", "0.5", "false", "true", "true", "false"]}, "general_config": ["0.001", "0.8", "1", "0.4"]})


        """
        Saving sources into database
        """
        RedisCache.createHash('source_map','people_killed_parisbombing', {'wikipedia.org': 'https://en.wikipedia.org/wiki/November_2015_Paris_attacks'})
        RedisCache.createHash('source_map','people_killed_parisbombing', {'news.sky.com': 'http://news.sky.com/story/1591289/number-of-paris-attacks-victims-rises-to-130'})
        RedisCache.createHash('source_map','people_killed_parisbombing', {'usatoday.com': 'http://www.usatoday.com/story/news/world/2015/11/13/multiple-deaths-reported-after-shootings-explosions-paris/75727746'})
        RedisCache.createHash('source_map','people_killed_parisbombing', {'news.yahoo.com': 'http://news.yahoo.com/latest-authorities-warn-paris-suburb-residents-052202969.html'})
        RedisCache.createHash('source_map','people_killed_parisbombing', {'wsj.com': 'http://localhost:8000/#/not_found'})
        RedisCache.createHash('source_map','people_killed_parisbombing', {'reuters.com': 'http://www.reuters.com/article/us-france-shooting-idUSKBN0KG0Y120150107'})
        RedisCache.createHash('source_map','people_killed_parisbombing', {'cnn.com': 'http://edition.cnn.com/2015/11/13/world/paris-shooting/'})
        RedisCache.createHash('source_map','people_killed_parisbombing', {'independent.co.uk': 'http://www.independent.co.uk/news/world/europe/paris-attack-victims-list-french-government-identifies-all-129-people-killed-in-paris-terrorist-a6739116.html'})
        RedisCache.createHash('source_map','people_killed_parisbombing', {'theguardian.com': 'http://www.theguardian.com/world/2015/nov/15/paris-attacks-identities-of-victims-from-more-than-a-dozen-countries-emerge'})
        