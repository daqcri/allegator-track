from flask import Flask, render_template, make_response
import redis
import os, urlparse

app = Flask(__name__)

if 'REDIS_URL' in os.environ:
    redis_url = urlparse.urlparse(os.environ.get('REDIS_URL'))
    host = redis_url.hostname
    port = redis_url.port
else:
    host = 'localhost'
    port = 6379

app._redis = redis.StrictRedis(host=host, port=port)
app.secret_key = 'super secret key'

from app.controllers import dataset_controller
from app.controllers import query_controller
from app.controllers import runset_controller
from app.controllers import result_controller

app.register_blueprint(dataset_controller.dataset)
app.register_blueprint(query_controller.query)
app.register_blueprint(runset_controller.runset)
app.register_blueprint(result_controller.result)
 
@app.route('/')
def index():
    return make_response(open('app/templates/index.html').read())