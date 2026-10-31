#!/usr/bin/env bash
set -e

CANVAS_DIR=/canvas
# Pinned Canvas LMS commit, so every build gets the same code. To upgrade, change
# this, then recreate the canvas-src volume (or check out the new ref in it).
CANVAS_REF=1c9f0bb8013ed69c4f2efe11fd483025469b7e6c

# Fetch the pinned Canvas commit on first run
if [ ! -f "$CANVAS_DIR/Gemfile" ]; then
  echo "Fetching Canvas LMS at $CANVAS_REF..."
  git init -q "$CANVAS_DIR"
  git -C "$CANVAS_DIR" fetch -q --depth 1 https://github.com/instructure/canvas-lms.git "$CANVAS_REF"
  git -C "$CANVAS_DIR" checkout -q FETCH_HEAD
fi

cd "$CANVAS_DIR"

if [ "$(git rev-parse HEAD 2>/dev/null)" != "$CANVAS_REF" ]; then
  echo "WARNING: /canvas is at $(git rev-parse --short HEAD 2>/dev/null), not pinned $CANVAS_REF"
fi

# Jobs worker: shares the web container's code volume, so wait for web to finish
# installing deps and first-run setup instead of racing it.
if [ "$1" = "jobs" ]; then
  until [ -f /data/.setup_complete ]; do
    echo "Waiting for web first-run setup to finish..."
    sleep 15
  done
  exec bundle exec script/delayed_job run
fi

# Copy example configs (skip if already present)
for config in amazon_s3 delayed_jobs domain file_store outgoing_mail security external_migration dynamic_settings; do
  [ -f "config/$config.yml" ] || cp "config/$config.yml.example" "config/$config.yml"
done

# Write database config pointing at the postgres service. The password stays in
# the environment (DB_PASSWORD, from .env); Rails evaluates the ERB at boot.
cat > config/database.yml << 'EOF'
development:
  adapter: postgresql
  database: canvas_development
  host: db
  port: 5432
  username: canvas
  password: <%= ENV.fetch("DB_PASSWORD") %>
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

# Gems live in the volume (BUNDLE_PATH, set in the Dockerfile) so they survive container rebuilds
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
