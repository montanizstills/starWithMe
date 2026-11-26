# Staging VM scripts (OCI)

Everything needed to build the StarWithMe staging VM (`swm-staging`, OCI us-chicago-1) from nothing, in order. Each step is one line. The scripts never print a secret and are safe to re-run.

Base URL for every script below (the repo is public, so no token is needed):

```
R=https://raw.githubusercontent.com/montanizstills/starWithMe/dev/infra/oci
```

Jira: [SWM-36](https://star-with-me.atlassian.net/browse/SWM-36) (the VM), [SWM-202](https://star-with-me.atlassian.net/browse/SWM-202) (staging setup). The full runbooks, with the secret inventory and rotation dates, live on Confluence: [Staging runbook](https://star-with-me.atlassian.net/wiki/spaces/STARWITHME/pages/6094850) and [Secrets and token rotation runbook](https://star-with-me.atlassian.net/wiki/spaces/STARWITHME/pages/4489217/Secrets+and+token+rotation+runbook). Secret values never go in this repo.

## Where each script runs

| Script | Runs in | Once per |
| --- | --- | --- |
| `create-budget-alert.sh` | OCI Cloud Shell | **account** |
| `launch-staging-vm.sh` | OCI Cloud Shell | VM |
| `bootstrap-vm.sh` | the VM, as `ubuntu` | VM |
| `setup-staging-env.sh` | the VM, as `ubuntu` | VM |
| `set-staging-secrets.sh` | your Mac, with `gh` signed in | account (partly per VM, see step 5) |
| `staging.sh` | the VM, as `ubuntu` | every deploy or test |
| `staging-proof.sh` | your Mac (outside the tailnet's addresses) | proof run: smoke tests plus the outside port check (SWM-38) |

## One time per account

Skip these when you are only replacing the VM.

**A. Budget alert.** A $1/month budget on the whole tenancy, with email alerts at 1% actual and 100% forecast. In Cloud Shell:

```
bash <(curl -fsSL $R/create-budget-alert.sh) you@example.com
```

It reuses the budget `swm_1_dollar` if it exists and skips alert rules that exist.

**B. Accounts and tokens outside OCI.** These are made by hand, not by a script. See the secrets runbook for where each one lives and when it expires.

* A Tailscale account, and a Tailscale OAuth client for CI (`TS_OAUTH_CLIENT_ID`, `TS_OAUTH_SECRET`).
* A GitHub token with `read:packages`, used for the GHCR login in step 3.

## A new VM, in order

**1. Launch the VM** (Cloud Shell). Put your SSH public key in `~/swm-oracle.pub` first (`cat > ~/swm-oracle.pub`, paste, Ctrl-D). Then:

```
bash <(curl -fsSL $R/launch-staging-vm.sh)
```

It retries every availability domain until A1 capacity frees up, and stops if `swm-staging` already exists. It prints the public IP. Don't use Oracle's AI assistant for this: it fails on `areLegacyImdsEndpointsDisabled`.

**2. Bootstrap** (on the VM, after `ssh -i ~/.ssh/swm_oracle ubuntu@<public IP>`):

```
bash <(curl -fsSL $R/bootstrap-vm.sh)
```

Installs Docker with compose, Tailscale and an 8 GB swap file, then starts Tailscale. Open the link it prints and sign in. Log out and back in so the `docker` group applies.

**3. Log in to GHCR** (on the VM, by hand). `docker login ghcr.io -u montanizstills --password-stdin`, then paste the token from step B and press Ctrl-D. The token is read from stdin, so it isn't saved in shell history.

**4. Clone the repo and write `.env`** (on the VM):

```
bash <(curl -fsSL $R/setup-staging-env.sh) admin@example.com
```

The argument is the Canvas admin email for staging. It makes a blobless clone in `~/starWithMe` with progress (the full history is about 2 GB), and restarts a clone that was cut off. It writes `.env` with new random passwords, mode 600, and never overwrites an existing one.

**5. Fill the GitHub `staging` environment** (on your Mac):

```
bash <(curl -fsSL $R/set-staging-secrets.sh) ubuntu@<public IP>
```

It finds your key at `~/.ssh/swm-oracle` or `~/.ssh/swm_oracle` (or set `SSH_KEY=`). It sets `STAGING_HOST`, `STAGING_SSH_KEY`, `TEST_STUDENT_PASSWORD`, `TS_OAUTH_CLIENT_ID` and `TS_OAUTH_SECRET`, and skips any that already exist.

> **Rebuilding the VM:** `STAGING_HOST` and `STAGING_SSH_KEY` already exist from the old VM, so the script skips them, but the new VM has a new Tailscale IP and doesn't have the CI key. Delete those two first (`gh secret delete STAGING_HOST --env staging -R montanizstills/starWithMe`, the same for `STAGING_SSH_KEY`), then run step 5 again. Changing secrets needs the human's OK (C5).

**6. Deploy and test** (on the VM):

```
bash <(curl -fsSL $R/staging.sh) deploy  [ref] [image_tag]   # default: dev latest
bash <(curl -fsSL $R/staging.sh) inject  [ref] [course]      # default: dev courses/example-playwright-browser-use
bash <(curl -fsSL $R/staging.sh) student [ref]               # default: dev
bash <(curl -fsSL $R/staging.sh) status
bash <(curl -fsSL $R/staging.sh) check                       # proof for SWM-202 / SWM-36, no secrets
bash <(curl -fsSL $R/staging.sh) smoke   [ref]               # smoke tests on the VM's stack (SWM-38, SWM-201)
```

The first `deploy` sets up the database and can take up to 30 minutes. `check` prints the setup proof to paste into Jira: Oracle metadata, memory, Docker and Tailscale versions, `.env` names only, containers, the health check and listening ports.

From your Mac, `./start.sh --stage-check <VM public IP>` (or `bash <(curl -fsSL $R/staging-proof.sh) <VM public IP>` without a checkout) runs `smoke` on the VM over SSH, then probes the public IP from outside: only 22 may answer. The IP is masked in the output.

To test from your own Mac or phone over Tailscale, see sections 4 to 7 of the [Staging runbook](https://star-with-me.atlassian.net/wiki/spaces/STARWITHME/pages/6094850).

## If the VM goes down

The full version, with expiry dates, is the [Staging VM lifecycle runbook](https://star-with-me.atlassian.net/wiki/spaces/STARWITHME/pages/5931025).

How long it can stay up: indefinitely. The account is Pay As You Go, so Oracle doesn't reclaim it for being idle, and the A1 shape stays inside Always Free. Three things expire on their own:

* the Tailscale key of `swm-staging`, after 180 days by default (choose **Disable key expiry** for it in the Tailscale admin console);
* the GHCR token, which `deploy` needs to pull (see the secrets runbook for the date);
* nothing else. The budget alert emails you if it ever costs money.

**Rebooted or stopped and started** (same VM, same boot volume). Data persists: the database, uploads, `.env`, the GHCR login and the Tailscale sign-in are all on disk. Docker and Tailscale start at boot, and every container has `restart: unless-stopped`, so Canvas comes back by itself within a few minutes. Check with `staging.sh status`. If Canvas isn't healthy, run `staging.sh deploy`. The public IP and the Tailscale IP both stay the same.

**Terminated** (the VM or its boot volume is gone). Do a full rebuild: steps 1 to 6 above. The Tailscale IP will be new, so delete `STAGING_HOST` and `STAGING_SSH_KEY` and run `set-staging-secrets.sh` again (step 5), and update the Tailscale testing runbook's address. The database is lost: the course and test student come back from `staging.sh inject`, but anything made by hand in Canvas doesn't. Backups are [SWM-224](https://star-with-me.atlassian.net/browse/SWM-224).

## Overlap with SWM-239 and SWM-240

Two open stories will make parts of this redundant. Update this README when either lands.

* **[SWM-239](https://star-with-me.atlassian.net/browse/SWM-239)** moves every staging secret into the GitHub `staging` environment and has `deploy-staging` write the VM's `.env`. Once it ships, step 4 shrinks to the clone only (the `.env` part of `setup-staging-env.sh` goes away), and step 5's `set-staging-secrets.sh` also sets `POSTGRES_PASSWORD`, `CANVAS_ADMIN_EMAIL`, `CANVAS_ADMIN_PASSWORD` and `WEB_BIND`, with `--rotate`. The VM's `.env` and the environment hold the same values twice until then.
* **[SWM-240](https://star-with-me.atlassian.net/browse/SWM-240)** decides whether `dev` becomes the default branch. `staging.sh` repeats the `deploy-staging`, `inject-course` and `student-test-staging` workflows ([PR #12](https://github.com/montanizstills/starWithMe/pull/12)) only because GitHub can't start them while the default branch is `prod`. If option 1 or 2 is picked, step 6 becomes "run the workflows from GitHub", and `staging.sh` stays as a fallback or is removed.
