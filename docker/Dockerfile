# Pull base image.
FROM gjyoung1974/aws-cli-tools:latest 

MAINTAINER Gordon Young <gjyoung1974@gmail.com>

ENV NOKOGIRI_USE_SYSTEM_LIBRARIES=1

ADD gemrc /root/.gemrc

RUN apk update \
&& apk add ruby \
           ruby-bigdecimal \
           ruby-bundler \
           ruby-io-console \
           ruby-irb \
           ca-certificates \
           libressl \
	   gnupg \
           tar \
	   curl \
           bash \
	   procps \
	   sudo \
	   graphviz \
	   ttf-freefont \
&& apk add --virtual build-dependencies \
           build-base \
           ruby-dev \
           libressl-dev \
\
&& bundle config build.nokogiri --use-system-libraries \
&& bundle config git.allow_insecure irue \
&& gem install json --no-rdoc --no-ri \
\
&& gem cleanup \
&& apk del build-dependencies \
&& rm -rf /usr/lib/ruby/gems/*/cache/* \
          /var/cache/apk/* \
          /tmp/* \
          /var/tmp/*

# Add the sgviz user
RUN adduser -u 1000 -G wheel -D sgviz
RUN echo "sgviz ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
WORKDIR /home/sgviz
RUN chown -R sgviz:users /home/sgviz
USER sgviz
RUN sudo cp -R /root/.aws . && sudo chown -R sgviz:users /home/sgviz/.aws
ADD gemrc /home/sgviz/.gemrc

# install RVM, Ruby, and Bundler
# Download and Build
RUN curl -sSL https://rvm.io/mpapis.asc | gpg2 --import -
RUN curl -L -o stable.tar.gz https://github.com/rvm/rvm/archive/stable.tar.gz && tar -xvf stable.tar.gz 
RUN cd ./rvm-stable && ./scripts/install
RUN /bin/bash -l -c "sudo gem install bundler --no-ri --no-rdoc"
RUN /bin/bash -l -c "sudo gem install sgviz --no-ri --no-rdoc"

