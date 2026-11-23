#!/usr/bin/env bash
set -e

# Canvas, its gems and compiled assets are baked into the image (Dockerfile,
# SWM-229). This only sets up the database and starts the server or worker.
cd /canvas
CANVAS_REF=$(cat REVISION)

# Jobs worker: wait until web has set up (or migrated) the database for this
# Canvas commit, instead of running against a half-built schema.
if [ "$1" = "jobs" ]; then
  until [ "$(cat /data/.migrated_ref 2>/dev/null)" = "$CANVAS_REF" ]; do
    echo "Waiting for web to set up the database..."
    sleep 15
  done
  exec bundle exec script/delayed_job run
fi

# First run: seed the database
if [ ! -f /data/.db_setup_complete ]; then
  echo "Setting up database..."
  bundle exec rails db:initial_setup
  touch /data/.db_setup_complete
  echo "$CANVAS_REF" > /data/.migrated_ref
fi

# One Rails boot for both: migrate when the image's Canvas commit changed, and
# write the brand config CSS/JS, which lives in the container (public/dist)
tasks=(brand_configs:generate_and_upload_all)
if [ "$(cat /data/.migrated_ref 2>/dev/null)" != "$CANVAS_REF" ]; then
  echo "Migrating the database to Canvas ${CANVAS_REF:0:7}..."
  tasks=(db:migrate "${tasks[@]}")
fi
bundle exec rails "${tasks[@]}"
echo "$CANVAS_REF" > /data/.migrated_ref

# A crash or docker restart can leave server.pid in the container, and Rails
# then refuses to boot. One server per container, so any pid file here is
# stale. See docs/decisions/0001-stale-rails-pid-file.md for the trade-offs.
rm -f tmp/pids/server.pid
exec bundle exec rails server -b 0.0.0.0 -p 3000
