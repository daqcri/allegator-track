from flask import Flask, render_template, make_response
import redis
import os

app = Flask(__name__)
app._redis = redis.from_url(os.environ.get("REDIS_URL") or 'redis://localhost:6379/0')
app.secret_key = os.environ.get("FLASK_SECRET")

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