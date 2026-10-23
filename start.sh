#!/usr/bin/env bash

set -e

usage() {
  cat << EOF
Usage: ./start.sh [OPTION]

Options:
  --local       Run Canvas locally via Docker Compose (Postgres + Redis + web)
  --codespace   Install Canvas inside a GitHub Codespace and start the Rails server
  --test        Run the local smoke tests against the running stack
  -h, --help    Show this help message

Examples:
  ./start.sh --local
  ./start.sh --codespace
  ./start.sh --test
EOF
}

if [ $# -eq 0 ]; then
  usage
  exit 0
fi

case "$1" in
  --local)
    docker compose up
    ;;
  --codespace)
    bash ./codespace-install.sh 2>&1 | tee log.txt
    cd "${WORKSPACE:-/workspaces/starWithMe}/canvas-lms"
    bundle exec rails server
    ;;
  --test)
    exec tests/local/smoke.sh "${@:2}"
    ;;
  -h|--help)
    usage
    exit 0
    ;;
  *)
    echo "Unknown option: $1"
    echo ""
    usage
    exit 1
    ;;
esac
