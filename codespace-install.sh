#!/usr/bin/env bash

set -e

echo "Starting Canvas LMS setup..."

# Source RVM (pre-installed in GitHub Codespaces universal image)
source /usr/local/rvm/scripts/rvm

# Workspace root — defaults to /workspaces/starWithMe in Codespaces
WORKSPACE="${WORKSPACE:-/workspaces/starWithMe}"
CANVAS_DIR="$WORKSPACE/canvas-lms"
CONTAINER_USER="${CONTAINER_USER:-codespace}"

# Clone Canvas if not present
if [ ! -d "$CANVAS_DIR" ]; then
  git clone https://github.com/instructure/canvas-lms.git "$CANVAS_DIR"
fi

cd "$CANVAS_DIR"

# Update Yarn GPG key
echo "Fixing Yarn repository..."
sudo rm -rf '/usr/share/keyrings/yarnkey.gpg'
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo gpg --dearmor -o /usr/share/keyrings/yarnkey.gpg
echo "deb [signed-by=/usr/share/keyrings/yarnkey.gpg] https://dl.yarnpkg.com/debian stable main" | sudo tee /etc/apt/sources.list.d/yarn.list

# Install system dependencies
echo "Installing system dependencies..."
sudo apt-get update
sudo apt-get install -y shared-mime-info build-essential libpq-dev libxml2-dev libxslt1-dev libidn11-dev \
  zlib1g-dev libldap2-dev libsqlite3-dev libyaml-dev libxmlsec1-dev pkg-config curl

# Install Ruby 3.4.1
echo "Setting up Ruby 3.4.1..."
rvm install 3.4.1
rvm use 3.4.1 --default

echo "Ruby version: $(ruby -v)"

gem install bundler:2.4.19
gem install scrypt sanitize ruby-debug-ide

# Fix permissions
sudo chown -R "$CONTAINER_USER:$CONTAINER_USER" . 2>/dev/null || true
sudo chown -R "$CONTAINER_USER:$CONTAINER_USER" /usr/local/rvm/rubies/ruby-3.4.1/lib/ruby/gems/3.4.1 2>/dev/null || true

bundle install
yarn install --pure-lockfile

# Copy example configs
for config in amazon_s3 delayed_jobs domain file_store outgoing_mail security external_migration dynamic_settings database; do
  cp -v config/$config.yml.example config/$config.yml 2>/dev/null || true
done

echo "Canvas LMS setup complete!"
