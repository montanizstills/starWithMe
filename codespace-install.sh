#!/bin/sh
git clone https://github.com/instructure/canvas-lms.git &&
cd canvas-lms/ &&
sudo apt-get update &&
sudo apt-get -y install postgresql-16 zlib1g-dev libldap2-dev libidn11-dev libxml2-dev \
    libsqlite3-dev libpq-dev libyaml-dev libxmlsec1-dev curl build-essential shared-mime-info
rvm autolibs disable
yes | rvm remove all
rvm install 3.4.1
rvm install "ruby-3.1.0"
rvm use 3.1.0 # & uncomment for background execution
# pid=$!; `wait pid`; echo $?
echo "$HOSTNAME ruby version: `ruby --version`\n\n\n"
gem install bundler:2.4.19 &&
gem install nokogumbo scrypt sanitize ruby-debug-ide && # can be deferred to bundle install
sudo chown -R codespace:codespace /workspaces/starWithMe/canvas-lms/ &&
sudo chown -R codespace:codespace /usr/local/rvm/rubies/ruby-3.4.1/lib/ruby/gems/3.4.0
# sudo chown -R codespace:codespace /usr/local/rvm/rubies/ruby-3.1.0/lib/ruby/gems/3.1.0 &&
bundle _2.4.19_ install &&
yarn install --pure-lockfile &&
for config in amazon_s3 delayed_jobs domain file_store outgoing_mail security external_migration dynamic_settings database; \
          do cp -v config/$config.yml.example config/$config.yml; done
sudo chown -R codespace:codespace /usr/local/rvm/rubies/ruby-3.1.0/lib/ruby/gems/3.1.0 &&
bundle _2.4.19_ update &&
sudo chown -R codespace:codespace /var/run/postgresql/ &&
export PGHOST=localhost &&
/usr/lib/postgresql/14/bin/initdb ~/postgresql-data/ -E utf8 &&
/usr/lib/postgresql/14/bin/pg_ctl -D ~/postgresql-data/ -l ~/postgresql-data/server.log start &&
/usr/lib/postgresql/14/bin/createdb canvas_development &&
bundle exec rails canvas:compile_assets &&
bundle exec rails db:initial_setup