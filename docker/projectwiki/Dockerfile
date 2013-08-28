FROM gollum
ADD supervisor.conf /etc/supervisor/conf.d/gollum.conf
RUN mkdir /wiki.git
CMD /usr/bin/supervisord -n
