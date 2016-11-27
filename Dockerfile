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

# Let the conatiner know that there is no tty
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get -y update
RUN apt-get -y install software-properties-common 

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

# ### ########## Section for CKAN installation
# ### Needs trusty for package install, others should install from source
# ### Trying from package
RUN apt-get install -y nginx apache2 libapache2-mod-wsgi libpq5 redis-server git-core
RUN wget http://packaging.ckan.org/python-ckan_2.6-trusty_amd64.deb
RUN dpkg -i python-ckan_2.6-trusty_amd64.deb
RUN apt-get install -y postgresql
RUN sudo -u postgres psql -l
RUN apt-get install -y solr-jetty
# ### ########## End section for CKAN installation

# ### Add package.json and install deps
#COPY package.json /usr/src/app/
#RUN npm install
# bower install --allow-root # likely to need this as polymer init tries to run bower without the root flag

# ### Add app src
#COPY . /usr/src/app

#CMD [ "npm", "start" ]
CMD [ "bash" ]
