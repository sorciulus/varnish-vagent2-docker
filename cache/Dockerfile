FROM ubuntu:14.04


RUN apt-get update
RUN apt install -y apt-transport-https
RUN apt-get install -y curl gnupg 
RUN curl -L https://packagecloud.io/varnishcache/varnish41/gpgkey | sudo apt-key add -
RUN apt-get install -y debian-archive-keyring
RUN echo "deb https://packagecloud.io/varnishcache/varnish41/ubuntu/ trusty main" > /etc/apt/sources.list.d/varnish-cache.list
RUN echo "deb-src https://packagecloud.io/varnishcache/varnish41/ubuntu/ trusty main" >> /etc/apt/sources.list.d/varnish-cache.list
RUN apt-get update 
RUN apt-get install -y unzip autoconf make pkg-config libmicrohttpd-dev libvarnishapi1 libvarnishapi-dev libcurl4-gnutls-dev python-docutils

RUN curl -o /etc/vagent2.zip https://codeload.github.com/varnish/vagent2/zip/master
RUN unzip -d /etc/ /etc/vagent2.zip
RUN cd /etc/vagent2-master && /etc/vagent2-master/autogen.sh \
    && ./configure \
    && make clean && make install

RUN apt-get install -y varnish
RUN echo admin:admin > /etc/varnish/agent_secret

EXPOSE 6081 6085 8080
ADD run.sh /
COPY ./varnish.vcl /etc/varnish/default.vcl
RUN chmod 777 /run.sh
CMD ["/run.sh"]