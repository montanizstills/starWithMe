#!/bin/bash

set -e

echo "Starting Canvas LMS setup..."

# Source RVM so it's available as a function
source /usr/local/rvm/scripts/rvm

# Clone Canvas if not exists
if [ ! -d "canvas-lms" ]; then
  git clone https://github.com/instructure/canvas-lms.git
fi

cd canvas-lms

# Fix Yarn GPG key FIRST
echo "Fixing Yarn repository..."
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo gpg --dearmor -o /usr/share/keyrings/yarnkey.gpg
echo "deb [signed-by=/usr/share/keyrings/yarnkey.gpg] https://dl.yarnpkg.com/debian stable main" | sudo tee /etc/apt/sources.list.d/yarn.list

# Now install dependencies
echo "Installing system dependencies..."
sudo apt-get update
sudo apt-get install -y shared-mime-info build-essential libpq-dev libxml2-dev libxslt1-dev

# Install Ruby 3.3.6
echo "Setting up Ruby 3.3.6..."
rvm install 3.3.6
rvm use 3.3.6 --default

# Verify Ruby version
echo "Ruby version: $(ruby -v)"

# Install bundler
gem install bundler:2.4.19

# Install gems
gem install scrypt sanitize ruby-debug-ide

# Fix permissions
sudo chown -R codespace:codespace . 2>/dev/null || true
sudo chown -R codespace:codespace /usr/local/rvm/rubies/ruby-3.3.6/lib/ruby/gems/3.3.0 2>/dev/null || true

# Bundle install
bundle install

# Yarn install
yarn install --pure-lockfile

# Copy config files
for config in amazon_s3 delayed_jobs domain file_store outgoing_mail security external_migration dynamic_settings database; do
  cp -v config/$config.yml.example config/$config.yml 2>/dev/null || true
done

echo "✅ Canvas LMS setup complete!"

# #!/bin/sh
# git clone https://github.com/instructure/canvas-lms.git &&
# cd canvas-lms/ &&
# sudo apt-get update &&
# sudo apt-get -y install postgresql-16 zlib1g-dev libldap2-dev libidn11-dev libxml2-dev \
#     libsqlite3-dev libpq-dev libyaml-dev libxmlsec1-dev curl build-essential shared-mime-info
# rvm autolibs disable
# yes | rvm remove all
# rvm cleanup
# rvm install 3.4.1
# rvm install "ruby-3.1.0"
# rvm use 3.1.0 # & uncomment for background execution
# # pid=$!; `wait pid`; echo $?
# echo "$HOSTNAME ruby version: `ruby --version`\n\n\n"
# gem install bundler:2.4.19 &&
# gem install nokogumbo scrypt sanitize ruby-debug-ide && # can be deferred to bundle install
# sudo chown -R codespace:codespace /workspaces/starWithMe/canvas-lms/ &&
# sudo chown -R codespace:codespace /usr/local/rvm/rubies/ruby-3.4.1/lib/ruby/gems/3.4.0 &&
# sudo chown -R codespace:codespace /usr/local/rvm/rubies/ruby-3.1.0/lib/ruby/gems/3.1.0 &&
# bundle _2.4.19_ install #&&
# bundle install &&
# yarn install --pure-lockfile &&
# for config in amazon_s3 delayed_jobs domain file_store outgoing_mail security external_migration dynamic_settings database; \
#           do cp -v config/$config.yml.example config/$config.yml; done
# sudo chown -R codespace:codespace /usr/local/rvm/rubies/ruby-3.1.0/lib/ruby/gems/3.1.0 &&
# bundle _2.4.19_ update &&
# sudo chown -R codespace:codespace /var/run/postgresql/ &&
# export PGHOST=localhost &&
# /usr/lib/postgresql/14/bin/initdb ~/postgresql-data/ -E utf8 &&
# /usr/lib/postgresql/14/bin/pg_ctl -D ~/postgresql-data/ -l ~/postgresql-data/server.log start &&
# /usr/lib/postgresql/14/bin/createdb canvas_development &&
# bundle exec rails canvas:compile_assets &&
# bundle exec rails db:initial_setup