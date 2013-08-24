FROM java
RUN apt-get install -y --no-install-recommends git curl
RUN curl -Lks http://www.atlassian.com/software/stash/downloads/binary/atlassian-stash-2.7.0.tar.gz -o /root/stash.tar.gz
RUN mkdir /opt/stash
RUN groupadd -g 998 stash
RUN useradd -u 998 -g stash -d /opt/stash-home -s /bin/bash stash
RUN tar zxf /root/stash.tar.gz --strip=1 -C /opt/stash
RUN chown -R stash:stash /opt/stash/logs /opt/stash/temp /opt/stash/work
RUN echo "127.0.0.1 stash" > /etc/hosts
ADD server.xml /opt/stash/conf/server.xml
ADD setenv.sh /opt/stash/bin/setenv.sh
ADD supervisor.conf /etc/supervisor/conf.d/stash.conf
ENV TZ America/Los_Angeles
ENV STASH_HOME /opt/stash-home
EXPOSE 7990:7990 7999:7999
CMD /usr/bin/supervisord -n
