#!/usr/bin/env bash

set -e

usage() {
  cat << EOF
Usage: ./start.sh [OPTION]

Options:
  --local       Run Canvas locally via Docker Compose (Postgres + Redis + web),
                then add the example course once Canvas is up
  --codespace   Install Canvas inside a GitHub Codespace and start the Rails server
  --test        Run the local smoke tests against the running stack
  --status      Show each service's health and footprint (CPU, memory, disk, jobs)
  --stage-check <VM public IP> [ref]
                Prove staging from this machine: smoke tests on the VM over SSH,
                then an outside port check (only 22 may answer). IP is masked.
  --rotate-admin-password
                Give the local Canvas admin a new random password, kept only in
                .env, and remake the admin API token. Prints nothing.
  -h, --help    Show this help message

Examples:
  ./start.sh --local
  ./start.sh --codespace
  ./start.sh --test
  ./start.sh --status
  ./start.sh --stage-check 203.0.113.10
  ./start.sh --rotate-admin-password
EOF
}

if [ $# -eq 0 ]; then
  usage
  exit 0
fi

case "$1" in
  --local)
    # Add the example course once Canvas is up, without holding up the logs (SWM-207)
    tools/apply-example-course.sh &
    trap 'kill $! 2>/dev/null' EXIT
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
  --status)
    exec tests/local/status.sh
    ;;
  --stage-check)
    # SWM-10: the staging proof from SWM-38 (infra/oci/staging-proof.sh)
    exec infra/oci/staging-proof.sh "${@:2}"
    ;;
  --rotate-admin-password)
    # SWM-228: Canvas must be running (./start.sh --local)
    exec tools/rotate-admin-password.sh
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
