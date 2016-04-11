'''
Models relating to query
'''

import Levenshtein
import re, os

class QueryModels:

    def remove_stopWords(self, query):
        stopword_file = 'app/models/stopWords.txt'
        stopwordsList = [line.strip() for line in open(stopword_file, 'r')]
        tokens = str(query).split()
        clnTokens = [s.lower() for s in tokens if s.lower() not in stopwordsList]
        clnstr = " ".join(clnTokens)
        return clnstr

    def remove_single_character(self, query):
        tokens = str(query).split()
        cp_tokens = tokens
        for t in tokens:
            if len(t)==1:
                cp_tokens.remove(t)
        clnstr = " ".join(cp_tokens)
        return clnstr

    def clean_text(self, query):
        cleanedStr = " " + query
        # case-1
        # no-filtering!!!!
        # case-2
        cleanedStr = cleanedStr.replace("_URL_", " ")
        # case-1,2
        cleanedStr = cleanedStr.replace(" RT ", "")
        # case-3
        cleanedStr = cleanedStr.replace("_RT_", "")
        #cleanedStr = cleanedStr.replace(",", ";")
        cleanedStr = cleanedStr.replace("\"", "")
        # urls
        cleanedStr = re.sub(r'(http://\S*)', ' _URL_ ', cleanedStr)
        cleanedStr = re.sub(r'(https://\S*)', ' _URL_ ', cleanedStr)
        #cleanedStr = cleanedStr.replace("_URL_"," ")
        #numbers
        cleanedStr = re.sub(r'[\d-]+', '_NUM_', cleanedStr)
        cleanedStr = cleanedStr.replace("_NUM_"," ")
        #mentions
        # case-2
        cleanedStr = re.sub(r'(@\w+)', ' ', cleanedStr)
        # case-3
        cleanedStr = re.sub(r'(@\w+)', '_MENTION_', cleanedStr)
                
        cleanedStr = re.sub(r'[[^\w\s_#@%.,;-]]+', '', cleanedStr)
        cleanedStr = re.sub(r'[^\w\s_-]+', ' ', cleanedStr)
                
        #--CALL FOR STOPWORDS --
        cleanedStr = self.remove_stopWords(cleanedStr)
        #print cleanedStr
        
        #--CALL FOR SINGLE CHAR REMOVAL --
        cleanedStr = self.remove_single_character(cleanedStr)
        #print cleanedStr

        cleanedStr = re.sub(r'(\s+)', ' ', cleanedStr) #for multiple spaces
        cleanedStr = cleanedStr.replace(' ', '_')
        return cleanedStr

    def calculate_distance(self, query, another_query):
        return Levenshtein.distance(query, another_query)

    def closest_matching(self, cleaned_query, stored_queries):
        distance = {}
        for query in stored_queries:
            only_query = query.split(':')[1]
            dist = self.calculate_distance(cleaned_query, only_query)
            #print 'd'+dist
            if dist <= 15:    
                distance[query] = dist
            #distance[query] = dist
        if distance:
            query = min(distance, key=distance.get)
        else:
            query = None
        return query

if __name__ == '__main__':
    query_modler = QueryModels()
    print(query_modler.clean_text('number of people killed in paris bombings'))