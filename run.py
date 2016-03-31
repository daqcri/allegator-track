#Run Flask Application

from app import app
from redisTokenSeeder import RedisTokenSeed
import os
redisSeed = RedisTokenSeed()
redisSeed.putTokens()

if __name__ == '__main__': 
    app.run(debug=True, port = int(os.environ.get("PORT", None)))