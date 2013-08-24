FROM buildessential
RUN apt-add-repository ppa:nginx/stable
RUN apt-get update
RUN apt-get -y install nginx
ADD nginx.conf /etc/nginx/nginx.conf
RUN rm -f /etc/nginx/sites-enabled/default
