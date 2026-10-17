#!/usr/bin/env bash
set -e

CANVAS_DIR=/canvas

# Clone Canvas LMS on first run
if [ ! -f "$CANVAS_DIR/Gemfile" ]; then
  echo "Cloning Canvas LMS..."
  git clone --depth 1 https://github.com/instructure/canvas-lms.git "$CANVAS_DIR"
fi

cd "$CANVAS_DIR"

# Copy example configs (skip if already present)
for config in amazon_s3 delayed_jobs domain file_store outgoing_mail security external_migration dynamic_settings; do
  [ -f "config/$config.yml" ] || cp "config/$config.yml.example" "config/$config.yml"
done

# Write database config pointing at the postgres service
cat > config/database.yml << 'EOF'
development:
  adapter: postgresql
  database: canvas_development
  host: db
  port: 5432
  username: canvas
  password: canvas
  timeout: 5000
EOF

# Wire Redis for caching
cat > config/cache_store.yml << 'EOF'
development:
  cache_store: redis_cache_store
  redis_url: redis://redis:6379
EOF

# Store gems inside the volume so they survive container rebuilds
bundle config set --local path 'vendor/bundle'
bundle install

yarn install --pure-lockfile

# First run: compile assets + seed DB (guarded by a flag file)
if [ ! -f /data/.setup_complete ]; then
  echo "First run — compiling assets (this takes ~30-60 min)..."
  bundle exec rails canvas:compile_assets

  echo "Setting up database..."
  bundle exec rails db:initial_setup

  touch /data/.setup_complete
  echo "Setup complete."
fi

exec bundle exec rails server -b 0.0.0.0 -p 3000
