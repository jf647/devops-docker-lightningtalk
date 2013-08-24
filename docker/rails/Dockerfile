FROM ruby
RUN apt-get install -y libsqlite3-dev
RUN gem install --no-rdoc --no-ri rails
RUN cd / && rails new www
RUN cd /www && perl -pi -e "s|^# gem 'therubyracer'|gem 'therubyracer'|" Gemfile
RUN cd /www && perl -pi -e "s|^# gem 'unicorn'|gem 'unicorn'|" Gemfile
RUN cd /www && bundle install --no-deployment
ADD unicorn.rb /www/config/unicorn.rb
EXPOSE 12001:80
CMD cd /www && bundle exec unicorn -p 80 -c config/unicorn.rb
