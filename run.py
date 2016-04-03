#Run Flask Application

from app import app
from redisTokenSeeder import RedisTokenSeed
import os, argparse
redisSeed = RedisTokenSeed()
redisSeed.putTokens()

if __name__ == '__main__': 
    parser = argparse.ArgumentParser()
    parser.add_argument('-p','--port', help='PORT', required=True)
    args = vars(parser.parse_args())
    app.run(port = int(os.environ.get("PORT", None) or args['port']))