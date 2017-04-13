FROM buildpack-deps:trusty

# ### Add Node user and group
RUN groupadd --gid 1000 node \
  && useradd --uid 1000 --gid node --shell /bin/bash --create-home node

# gpg keys listed at https://github.com/nodejs/node
RUN gpg --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 9554F04D7259F04124DE6B476D5A82AC7E37093B
RUN gpg --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 94AE36675C464D64BAFA68DD7434390BDBE9B9C5
RUN gpg --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 0034A06D9D9B0064CE8ADF6BF1747F4AD2306D93
RUN gpg --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys FD3A5288F042B6850C66B31F09FE44734EB7990E
RUN gpg --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 71DCFD284A79C3B38668286BC97EC7A07EDE3FC1
RUN gpg --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys DD8F2338BAE7501E3DD5AC78C273792F7D83545D
RUN gpg --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8
RUN gpg --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys B9AE9905FFD7803F25714661B63B535A4C206CA9

ENV NPM_CONFIG_LOGLEVEL info
ENV NODE_VERSION 7.2.0

RUN curl -SLO "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.xz" \
  && curl -SLO "https://nodejs.org/dist/v$NODE_VERSION/SHASUMS256.txt.asc" \
  && gpg --batch --decrypt --output SHASUMS256.txt SHASUMS256.txt.asc \
  && grep " node-v$NODE_VERSION-linux-x64.tar.xz\$" SHASUMS256.txt | sha256sum -c - \
  && tar -xJf "node-v$NODE_VERSION-linux-x64.tar.xz" -C /usr/local --strip-components=1 \
  && rm "node-v$NODE_VERSION-linux-x64.tar.xz" SHASUMS256.txt.asc SHASUMS256.txt \
  && ln -s /usr/local/bin/node /usr/local/bin/nodejs

# install yarn
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
sudo apt-get update && sudo apt-get install yarn

# Install latest git
sudo add-apt-repository ppa:git-core/ppa
sudo apt-get update
sudo apt-get install -y git
git config --global user.name "sj7272"
git config --global user.email "sj.7272@gmail.com"

# Let the container know that there is no tty
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update
# Avoid ERROR: invoke-rc.d: policy-rc.d denied execution of start.
RUN echo "#!/bin/sh\nexit 0" > /usr/sbin/policy-rc.d

RUN apt-get install -y software-properties-common git git-core 

RUN add-apt-repository universe 
RUN add-apt-repository main

RUN apt-get -y install s3cmd # needs to be configured - look at minio also for GCS

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

ARG NODE_ENV
ENV NODE_ENV $NODE_ENV

#  ### install npm packages
RUN npm install -g \
    polymer-cli \
    bower 
    
# ### ########## Section for CKAN installation - taken from http://docs.ckan.org/en/latest/maintaining/installing/install-from-package.html
# ### Needs trusty for package install, others should install from source
# ### Trying from package
RUN apt-get install -y nginx apache2 libapache2-mod-wsgi libpq5 redis-server
RUN echo "ServerName localhost" | sudo tee /etc/apache2/conf-available/fqdn.conf
RUN sudo a2enconf fqdn
RUN wget http://packaging.ckan.org/python-ckan_2.6-trusty_amd64.deb
RUN dpkg -i python-ckan_2.6-trusty_amd64.deb
RUN service apache2 reload
RUN apt-get install -y postgresql
# ### uncomment localhost setting in /etc/postgresql/9.3/main/postgresql.conf
RUN /etc/init.d/postgresql restart
RUN sudo -u postgres psql -l # check some dbs exist
RUN sudo -u postgres createuser -S -D -R -P ckan_default # add user - needs interactive shell to enter pw 
# ### You can do that using plain SQL after connecting as a superuser (e.g. postgres) to the database in question:
# ### create user user1 password 'foobar'
# ### If you need to do this from within a script you can put that into a sql file and then pass this to psql:
# ### » sudo -u postgres psql --file=create_user.sql
RUN sudo -u postgres createdb -O ckan_default ckan_default -E utf-8 # create database owned by this user
# ### Edit the sqlalchemy.url option in your CKAN configuration file (/etc/ckan/default/production.ini) file and set the correct password, database and database user


# ### mv data to different volume
# sudo service postgresql stop
# sudo pg_dropcluster 9.3 main
# sudo pg_createcluster -d /newdrive/postgresdbs/ 9.3 main
# sudo cp -a /olddrive/var/lib/postgresql/9.3/main/. /newdrive/postgresdbs/ # there was nothing to move on a fresh install
# sudo chown -R postgres:postgres /newdrive/postgresdbs/
# sudo service postgresql start

#RUN apt-get install -y solr-jetty
# ### Edit the Jetty configuration file (/etc/default/jetty) and change the following variables:

# NO_START=0            # (line 4)
# JETTY_HOST=127.0.0.1  # (line 16)
# JETTY_PORT=8983       # (line 19)

RUN service jetty start

RUN mv /etc/solr/conf/schema.xml /etc/solr/conf/schema.xml.bak
RUN ln -s /usr/lib/ckan/default/src/ckan/ckan/config/solr/schema.xml /etc/solr/conf/schema.xml
RUN service jetty restart
# ### Finally, change the solr_url setting in your CKAN configuration file (/etc/ckan/default/production.ini) to point to your Solr server, for example:
# ### solr_url=http://127.0.0.1:8983/solr

# ### Edit the CKAN configuration file (/etc/ckan/default/production.ini) to set up the following options:
# site_id
# Each CKAN site should have a unique site_id, for example:
# ckan.site_id = default
# site_url
# Provide the site’s URL. For example:
# ckan.site_url = http://demo.ckan.org  -- http://ckan.myproject72.com
# ### set up the site db
RUN ckan db init
# ### Optionally, setup the DataStore and DataPusher by following the instructions in DataStore extension. http://docs.ckan.org/en/latest/maintaining/datastore.html
# ### Also optionally, you can enable file uploads by following the instructions in FileStore and file uploads. http://docs.ckan.org/en/latest/maintaining/filestore.html
RUN service apache2 restart
RUN service nginx restart
# ### ########## End section for CKAN installation

# ### Add package.json and install deps
#COPY package.json /usr/src/app/
#RUN npm install

# ### Add app src
#COPY . /usr/src/app

#CMD [ "npm", "start" ]
CMD [ "bash" ]
