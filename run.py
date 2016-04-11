#Run Flask Application

from flask import url_for
from app import app
from redisTokenSeeder import RedisTokenSeed
import os, argparse, ast
redisSeed = RedisTokenSeed()
redisSeed.putTokens()
import fetch_source

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('-p','--port', help='PORT', required=True)
    args = vars(parser.parse_args())
    app.run(debug=True, host='0.0.0.0', port = int(os.environ.get("PORT", None) or args['port']))