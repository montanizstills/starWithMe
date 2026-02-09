#!/bin/bash
bash ./codespace-install.sh 2&>log.txt &
wait $!
cd canvas-lms
docker compose start postgres
docker compose up -d
bundle exec rails server


# start_canvas="docker compose exec web bundle exec rails server"
# start_postgres"docker compose start postgres"
# stop_postgres="docker compose stop postgres"
# restart_postgres="docker compose restart postgres"
