# Installation Instructions

## Install system dependancies

### System libraries

```
apt-get install curl libpq-dev postgresql git sendmail
```

### RVM and Ruby

    curl -sSL https://get.rvm.io | bash -s stable --ruby=2.1.3
    gem install bundler

## Get code and install required gems

    git clone git@github.com:Qatar-Computing-Research-Institute/dafna-viz.git
    cd dafna-viz
    bundle

## Setup environment

### Setup database (not required for Heroku setup, except for the CREATE EXTENSION statement)

Before running the foreman commands below, make sure the database credentials match the actual parameters you have used, depending on your environment (see below).

    sudo -u postgres psql postgres
    $ create role dafnaviz with createdb login password 'dafnaviz';
    $ \q

    foreman run rake db:create
    foreman run rake db:migrate
    foreman run rake db:seed

Note we don't use `db:setup` because we have hard-coded indices in migrations that are not reflected in schema.rb.
The `db:migrate` command is always needed whenever you update the code and have new files in `db/migrate` folder.

Load the `intarray` extension so that some sql functions work (idx for example), must be database super user:

    CREATE EXTENSION intarray;

Choose one of the following sub-sections, depending on your installation environment.

### 1- Development
The database credentials are found in `config/database.yml` and should match those in the database setup step.
Copy `.env-development` to `.env` and add [AWS S3](http://aws.amazon.com/documentation/s3/) keys to access the bucket defined in `S3_BUCKET` variable. The keys should allow both GetObject and PutObject for the bucket. Manage the keys from [AWS IAM](http://aws.amazon.com/documentation/iam/) service. Here is an example policy for the keys you should generate for a bucket named `allegatortrack-dev`:

    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Sid": "Stmt1412245103000",
          "Effect": "Allow",
          "Action": [
            "s3:GetObject",
            "s3:PutObject"
          ],
          "Resource": [
            "arn:aws:s3:::allegatortrack-dev/*"
          ]
        }
      ]
    }

Moreover, the bucket should have a CORS Configuration as follows:

    <?xml version="1.0" encoding="UTF-8"?>
    <CORSConfiguration xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
        <CORSRule>
            <AllowedOrigin>http://localhost:4000</AllowedOrigin>
            <AllowedMethod>POST</AllowedMethod>
            <AllowedHeader>*</AllowedHeader>
        </CORSRule>
    </CORSConfiguration>

Modify the `AllowedOrigin` tag as necessary if you run the rails server on a different port.

Finally start the application server using the development configuration:

`foreman start`

This will start the app on the default port 5000, if you want to change the port, for example to 4000:

`PORT=4000 foreman start`

### 2- Production

#### 2.1- Linux Server
Do the same as development, but start from `.env-production` and use a different bucket. Set the `AllowedOrigin` tag to the production URL. Also you need to create an account on [Pusher](http://pusher.com) and get the keys to be put in `.env`. The database credentials are configured through the environment variables and should match those in the database setup step. Finally precompile assets using the following:

    foreman run rake assets:precompile

Finally start the application server using the production configuration:

`foreman start`

This will start 1 web process and 1 worker process, to start more:

`foreman start worker=3,web=1`

Note that you need a web server to proxy the requests from the Internet to this internal port. You can use either nginx or Apache, on the same machine or on another machine in the same network.

#### 2.2- Heroku
You need first to provision the following add-ons:

- Postgres
- Pusher
- Sendgrid

These add-ons will configure the environment accordingly. Verify by typing `heroku config` and note the corresponding environment variables. You need to add 3 more configuration variables for AWS:

    AWS_ACCESS_KEY_ID
    AWS_SECRET_ACCESS_KEY
    S3_BUCKET

Generate the keys the same way that is mentioned in the Linux Server section. Do this by typing: `heroku config-set AWS_ACCESS_KEY_ID=XXX`, same for other 2.

Adjust the number of web and worker dynos using the `heroku ps` command on through the web dashboard.

## Updating instructions

### Development and Production (Linux server)

    Ctrl+C # to stop the app server
    git pull # get latest code
    bundle # if Gemfile/Gemfile.lock are updated
    foreman run rake db:migrate # if new files added in db/migrate
    foreman run rake assets:precompile # Production only, if new assets added/modified in app/assets, lib/assets or vendor/assets.
    foreman start # start the app server again

### Heroku
Whenever you push code to the `heroku` remote, the app will be automatically updated and restarted. You only need to run the `db:migrate` task if necessary.

## Updating DAFNA-EA core
Whenever you update in the DAFNA-EA core, just run there:

    mvn clean install

then copy the generated `target/DAFNA-EA-1.0-jar-with-dependencies.jar` into `dafna-viz/vendor/DAFNA-EA-1.0-jar-with-dependencies.jar`
