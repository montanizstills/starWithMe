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

# Wire Redis: define the server in redis.yml; cache_store.yml then reuses it
cat > config/redis.yml << 'EOF'
development:
  url:
  - redis://redis:6379
EOF

cat > config/cache_store.yml << 'EOF'
development:
  cache_store: redis_cache_store
EOF

# Store gems inside the volume so they survive container rebuilds
bundle config set --local path 'vendor/bundle'
bundle install

yarn install --pure-lockfile

# First run: seed DB, then compile assets (asset compile reads brand_configs from the DB).
# Each step has its own flag so a failed compile doesn't re-run DB setup.
if [ ! -f /data/.db_setup_complete ]; then
  echo "Setting up database..."
  bundle exec rails db:initial_setup
  touch /data/.db_setup_complete
fi

if [ ! -f /data/.setup_complete ]; then
  echo "First run — compiling assets (this takes ~30-60 min)..."
  bundle exec rails canvas:compile_assets
  touch /data/.setup_complete
  echo "Setup complete."
fi

exec bundle exec rails server -b 0.0.0.0 -p 3000
