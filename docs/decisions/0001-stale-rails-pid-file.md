# 0001: Delete stale Rails pid file on web startup

- **Status:** Accepted (local/dev only). Cons tracked for a later epic story.
- **Date:** 2026-11-02
- **Change:** `entrypoint.sh` runs `rm -f tmp/pids/server.pid` right before
  `exec bundle exec rails server`. The jobs path (`entrypoint.sh jobs`) exits
  earlier and never runs it.

## Problem

Docker Desktop (or the Mac) restarted while the stack was up. Every container
exited with code 255, with no clean shutdown. Rails had written
`/canvas/tmp/pids/server.pid`, and `/canvas` is the persistent `canvas-src`
volume, so the file survived. On the next `./start.sh --local`, db, redis and
jobs came back, but web printed

    A server is already running (pid: 1, file: /canvas/tmp/pids/server.pid).
    Exiting

and `localhost:3000` could not be reached. Fixing it by hand meant deleting
the file from the volume.

## Decision

Delete the pid file each time the web container starts.

## Why this fix for now

- **It is correct for the current setup.** Exactly one Rails server runs per
  web container, and the entrypoint starts it. When the entrypoint runs, no
  server can be running in that container yet, so any pid file it finds is
  stale.
- **It is the standard pattern.** Docker's own Rails/Compose guide uses it.
- **It costs almost nothing.** One line, no new dependencies, nothing to
  migrate. Removing it later is trivial.
- **It unblocks Ship 1.** Every Docker Desktop restart, laptop sleep crash or
  OOM kill was turning into a manual repair step. The real fixes (below) belong
  with the Ship 2 image redesign, not in the middle of Ship 1 work.
- **It is harmless in the cloud.** On a fresh, temporary container filesystem
  there is never a pid file, so the line does nothing.

## Cons

1. **It treats the symptom, not the cause.** The cause is that the Canvas
   source tree, including `tmp/`, lives in a persistent volume. That is a dev
   convenience (avoids re-fetching Canvas and re-installing gems), not a
   production layout.
2. **It removes Rails' "already running" guard.** That guard exists to stop
   two servers from running against the same app directory. With this line,
   anything that runs the entrypoint while web is up deletes the live
   server's pid file and starts a second server.
3. **It hard-codes the pid path.** If the pid location ever moves (Puma
   `pidfile` config, `-P` flag, `PIDFILE` env), the `rm` silently stops
   matching and the original bug comes back.
4. **It hides crash evidence.** A pid file at startup is a sign that the last
   shutdown was not clean. We now delete that sign without logging it.

## Scenarios where it comes back to bite

### Con 2: the removed guard

- **`docker compose run web …` while the stack is up.** `run` starts a *new*
  container with the same entrypoint and the same `canvas-src` volume. It
  rewrites `config/*.yml`, runs `bundle install` and `yarn install` into the
  shared volume (while the live server is reading it), deletes the live
  server's pid file, then boots a second Rails server. Inside its own
  container port 3000 is free, so nothing stops it. Result: two servers
  sharing one `tmp/cache`, bootsnap cache and gem directory, and possibly
  corrupted installs if the dependency steps overlap. Before this fix, Rails
  would have refused to start the second server. Safe alternatives:
  `docker compose exec web …` (does not run the entrypoint), or
  `docker compose run --rm --no-deps --entrypoint <cmd> web …`.
- **Scaling web locally (`docker compose up --scale web=2`).** Today the
  second replica fails on the host port `3000:3000` clash, which is loud and
  harmless. If someone removes the fixed host port to make scaling work (a
  common next step), both replicas share `canvas-src`. Each deletes the
  other's pid file on boot, and both write to the same `tmp/`, caches and
  compiled assets.
- **Multiple servers on shared storage in the cloud.** If Ship 2 copies this
  layout to several replicas (horizontal scaling) mounting one network volume
  (EFS, NFS, a Render disk), every replica sees one shared
  `tmp/pids/server.pid`. Without the `rm`, replica B refuses to start because
  of replica A's file. With the `rm`, B starts but deletes A's file, and
  replicas race on the shared `tmp/`, caches and asset compile. The `rm`
  turns a loud failure into a quiet, intermittent one.
- **A future restart policy plus a real double start.** With
  `restart: unless-stopped` and a manual `run`, two servers can keep
  restarting and cleaning up after each other with no error pointing at the
  cause.

### Cons 1, 3 and 4

- **Moving the pid file breaks the fix silently.** Someone adds a Puma config
  with `pidfile "/canvas/tmp/puma.pid"` (or a different path). The `rm` still
  targets `tmp/pids/server.pid`, the next crash leaves the new file behind,
  and web stops booting again, with nothing pointing at this line.
- **Unclean shutdowns go unnoticed.** Repeated OOM kills or Docker Desktop
  crashes used to show up as "server already running". Now they leave no trace
  in the web logs.
- **The volume layout gets copied to the cloud.** The fix makes the
  persistent-source-volume layout "just work" locally, so it is easy to carry
  into Ship 2 unchanged. There, a single persistent disk blocks horizontal
  scaling (Render disks attach to one instance), and running from source
  instead of a built image makes deploys slow and hard to reproduce.

## Follow-up (later epic story)

- Build the Canvas source, gems and compiled assets into the Docker image for
  Ship 2. No source volume; only real data (uploads) on persistent storage.
- Keep the pid file on the container's temporary filesystem (or
  `-P /tmp/server.pid`) so nothing stale can survive a new container, and
  keep the `rm` only as belt-and-braces.
- Log a warning when a stale pid file is found, instead of deleting it
  silently.
- Make `docker compose run web` safe or documented. For example, a separate
  `tools` service for one-off commands, or entrypoint modes that skip the
  install and server steps.
- Revisit or remove this decision once the above lands.
