FROM ruby
RUN gem install --no-rdoc --no-ri zenweb
RUN mkdir /www
RUN cd /www && gem unpack zenweb && mv zenweb-*/example-site/* . && rm -rf zenweb-* && touch .isolate.rb
RUN cd /www && rake
ADD nginx.site.conf /etc/nginx/sites-enabled/zenweb.conf
EXPOSE 11001:80
CMD /usr/sbin/nginx