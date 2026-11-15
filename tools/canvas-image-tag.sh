#!/usr/bin/env bash
# Prints the content tag of the Canvas image for this checkout (SWM-229):
# build-<hash of the files that go into the image>. The build-image workflow
# publishes under it, and deploy-test pulls it, so a PR that changes the
# Dockerfile or entrypoint builds its own image instead of pulling a stale one.
set -euo pipefail
cd "$(dirname "$0")/.."
echo "build-$(cat Dockerfile entrypoint.sh | git hash-object --stdin | cut -c1-12)"
