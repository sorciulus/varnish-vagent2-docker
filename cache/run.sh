#! /bin/sh

echo Reading the source files
source /etc/varnish/varnish.params
echo Binding to $VARNISH_LISTEN_ADDRESS:$VARNISH_LISTEN_PORT
/usr/sbin/varnishd -F\
    -P /var/run/varnish.pid \
    -f /etc/varnish/default.vcl \
    -a :8080 \
    -T :6081 \
    -S /etc/varnish/secret \
    -s malloc,256m &

chmod 755 /etc/varnish/secret
chmod 777 /etc/varnish

varnish-agent -K /etc/varnish/agent_secret -p /etc/varnish/default.vcl -d