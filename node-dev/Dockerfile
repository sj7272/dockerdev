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
ENV NODE_VERSION 9.2.0

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

# Instal Open SSH
sudo apt-get install -y openssh-server

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
    
### Add package.json and install deps
COPY package.json /usr/src/app/
RUN npm install

# ### Add app src
COPY . /usr/src/app
RUN cd /usr/src/app

#CMD [ "npm", "start" ]
CMD [ "bash" ]
