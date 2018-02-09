# Docker - Cache server
Docker container for Varnish 4.1.x with [Varnish Agent2](https://github.com/varnish/vagent2)

## Start

As cache consists of multiple components, we provide a `docker-compose.yml` to bring up and connect all the services.  
Use the following command:

    docker-compose up -d

When all the services are started, you can try the magic of the varnish by calling the test html page via Postman or through the browser.
On port 80 ngnix respond providing html page. On the 8080 port respond Varnish  will respond by making a call to the nginx backend and returning the result

## Without Varnish

![alt text](https://raw.githubusercontent.com/sorciulus/varnish-vagent2-docker/master/images/without.png)

## With Varnish

![alt text](https://raw.githubusercontent.com/sorciulus/varnish-vagent2-docker/master/images/with.png)
