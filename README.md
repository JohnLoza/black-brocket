# Black Brocket's ecommerce app

How to set it up:

## 1. [*Install Ruby on Rails*](https://www.digitalocean.com/community/tutorials/how-to-install-ruby-on-rails-with-rbenv-on-ubuntu-18-04)

## 2. Install and configure the database manager
[Install Mysql Server](https://www.digitalocean.com/community/tutorials/how-to-install-mysql-on-ubuntu-18-04) for development machines.

[Install PostgreSql](https://www.digitalocean.com/community/tutorials/how-to-install-and-use-postgresql-on-ubuntu-18-04) for a production server.

## 3. Install Mysql Client as a dependency for mysql2 gem.

    apt install mysql-client

## 4. Install RMagick dependencies

    apt install imagemagick libmagickwand-dev

## 5. Bundle install gems
### For a development machine
    $ bundle install --without production

### Or a production server
    $ bundle install --deployment --without development test

## 6. Setup database
### For a development machine
    $ rails db:create
    $ rails db:migrate
    $ rails db:seed

### Or a production server
    $ rails db:create RAILS_ENV=production
    $ rails db:migrate RAILS_ENV=production
    $ rails db:seed RAILS_ENV=production

## 7. Execute the sql scripts in vendor
### For MySql
    $ mysql -u <username> -p
    mysql > use black-brocket_development
    mysql > source /path_to_project/vendor/states.sql
    mysql > source /path_to_project/vendor/cities.sql

### And for PostgreSql
    $ psql -U <username> -d <database> -a -f /path_to_project/vendor/states.sql
    $ psql -U <username> -d <database> -a -f /path_to_project/vendor/cities.sql

or login to the psql console and execute the files there.

    $ psql -U <username> -d <database>
    =# \i /path_to_project/vendor/states.sql
    =# \i /path_to_project/vendor/cities.sql


## 8. Run the Web Server
Once the steps above are completed just run the app on a web server
either webrick, puma, apache, nginx, etc. In the login page use the credentials
below to log in as the admin. These credentials can be changed once inside
the app.

    username: admin@example.com
    password: foobar

If the app is running on a production server you might need to precompile
the project assets.

    rails assets:precompile RAILS_ENV=production
