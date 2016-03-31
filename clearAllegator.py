'''
Clear Allegator Track
'''

from app.models import DatasetModels
from app.models import RunsetModels
import os

user_token = os.environ.get("USER_TOKEN", None)
print user_token

modeler = DatasetModels()
ids = modeler.fetch_ids('claims')
modeler.clear(ids)

modeler = RunsetModels()
ids = modeler.fetch_ids()
modeler.clear(ids)

print 'Removed Content from Allegator Track'