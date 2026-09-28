# Deploying

One VPS, FazouraParty's. The relay is an OTP release with the built Flutter web app inside
it, and it has no database: everything it holds lives in memory. The host's own Caddy
terminates TLS. The container is run by [Kamal](https://kamal-deploy.org), driven by
[deploy-kit](https://github.com/AnisAbdellatif/deploy-kit), vendored in `.kamal/kit`.

**CI tests and builds; a person deploys.** A push to `main` runs every check, builds the
image, pushes it to `ghcr.io/anisabdellatif/triviarelay` tagged with the commit sha, and
signs a build attestation for it. CI holds no SSH key and no relay secret, and touches no
server. Deploying is `.kamal/kit/bin/kit deploy` from a checkout of `main`, which refuses
unless that exact commit passed CI and its image carries CI's attestation, then pulls it
and swaps the container with no downtime.

```
GitHub Actions                     the machine that deploys             the VPS
──────────────                     ────────────────────────             ────────────────────────────────────
server ─┐                          kit deploy                           caddy (the host's) :80 :443
app  ───┴─▶ image ─push─▶ ghcr.io   ├ gates: main, clean, pushed,        │  reverse_proxy, per site
            └─ attest               │   CI green, attestation      ssh    ▼
                                    ├ kamal deploy --skip-push   ──────▶ kamal-proxy  127.0.0.1:8080
                                    ├ drain seats (old container)        │  routes on Host, swaps containers
                                    └ smoke test through Caddy           ▼
                                                                         trivia-relay-web-<sha>  :4100
                                                                          └─ /app/web  the Flutter build
                                                                         fazoura-web-<sha>, fazoura-db
```

| File | What it is |
|---|---|
| [deploy.yml](deploy.yml) | Kamal's config: the relay and kamal-proxy's settings |
| [trivia-relay.caddy](trivia-relay.caddy) | the site for the host's Caddy, imported with the domain as its argument |
| [.env.example](.env.example) | the relay's secrets file, which lives only on the VPS |
| [Dockerfile](Dockerfile) | the image, built by CI |
| [`.kamal/kit.env`](../.kamal/kit.env) | the kit's settings: gates, the drain step, the image to verify |
| [`.kamal/steps/drain-seats`](../.kamal/steps/drain-seats) | tells every phone its seat is closing, before kamal-proxy cuts the sockets |
| [`.kamal/kit.local.env.example`](../.kamal/kit.local.env.example) | the server's address, the domain, the registry token: per machine, git-ignored |

Caddy proxies to **kamal-proxy on loopback** (deploy-kit's `behind-caddy` preset).
kamal-proxy routes on the Host header, so the relay and FazouraParty share it, and moves
traffic to a new container only once its `/health` answers. The relay publishes no port.

## One-time setup

The server already runs FazouraParty this way, so Docker, the `deploy` user, Caddy and
kamal-proxy are there. What the relay adds:

### 1. DNS

Point an A (and AAAA) record for the relay's domain at the VPS. Caddy gets the certificate
itself, so the record must resolve before the first deploy.

### 2. The directory and its secrets

`/srv/trivia-relay/.env` lives **only** on the VPS. Nothing that deploys ships, reads or
overwrites it: the container reads it there (`--env-file`).

```bash
ssh deploy@<host> 'install -d -m 700 /srv/trivia-relay'
scp deploy/.env.example deploy@<host>:/srv/trivia-relay/.env
ssh deploy@<host> 'chmod 600 /srv/trivia-relay/.env && vi /srv/trivia-relay/.env'
```

The deploy user must be able to read it: the Docker CLI, running as that user, opens it.
Docker reads it **literally**: no quotes around values, no `$VAR`, no `export`. Generate
`SECRET_KEY_BASE` locally with `mix phx.gen.secret` (in `server/`); `SPORCLE_API_KEY` is
explained in [`server/.env.example`](../server/.env.example).

### 3. Caddy

[trivia-relay.caddy](trivia-relay.caddy) is the whole site, with the domain as an argument:

```bash
scp deploy/trivia-relay.caddy <you>@<host>:/tmp/ && ssh -t <you>@<host> sudo install -m 644 /tmp/trivia-relay.caddy /etc/caddy/trivia-relay.caddy
```

```caddyfile
# /etc/caddy/Caddyfile, beside FazouraParty's site
import /etc/caddy/trivia-relay.caddy relay.example.com
```

```bash
sudo caddy validate --config /etc/caddy/Caddyfile && sudo systemctl reload caddy
```

The domain must be the same as `TRIVIA_RELAY_PUBLIC_HOST` (kamal-proxy routes on it) and
`PHX_HOST`. Nothing here writes to `/etc/caddy` or reloads Caddy, so when the site file
changes, copy it over and reload again.

The relay believes exactly two `X-Forwarded-For` entries (`TRUST_PROXY: 2` in
`deploy.yml`: Caddy's, then kamal-proxy's), which is honest only because kamal-proxy is
bound to loopback and the relay publishes nothing. If the domain is behind Cloudflare, the
site takes the player from `CF-Connecting-IP`, but only on a connection from Cloudflare's
published ranges; the file has the command that refreshes them.

**One kamal-proxy serves every Kamal app on the server.** Its `run` block in `deploy.yml`
is the server's, not the relay's, and is identical to FazouraParty's: keep them that way.

### 4. Your machine

Kamal 2.12 (`gem install kamal`), `gh` logged in (the CI and attestation gates ask GitHub),
git and curl. Then, in this checkout:

```bash
cp .kamal/kit.local.env.example .kamal/kit.local.env
$EDITOR .kamal/kit.local.env        # host, user, domain, registry token, smoke URL
.kamal/kit/bin/kit doctor
```

The registry token is a GitHub token with `read:packages` only (FazouraParty's works for
both). Kamal logs the server in to ghcr.io with it to pull, and that login stays on the
server, which is why it must not be able to write. CI pushes with its own short-lived
token. The attestation gate reads the image from ghcr.io too: `docker login ghcr.io -u
<you>` once with the same token, or make the package public.

### 5. GitHub

Nothing to configure for deploys: CI needs no secret to push or attest. Branch protection
on `main` matters: the CI gate is only as strong as what can reach `main`. The Android
release has its own setup (the top-level README, "Releasing the Android app").

## Every deploy

Merge `dev` into `main` through a pull request, then, from an up-to-date `main`:

```bash
git switch main && git pull
.kamal/kit/bin/kit deploy
```

The kit refuses unless the checkout is `main`, clean and pushed, CI passed for that commit
(it waits up to 30 minutes for a run still going), and the image carries CI's attestation.
It then deploys and checks `/health` through Caddy; if that fails it rolls back to the
build that was running. Kamal prints what each gate and step decided as it goes.

**A deploy ends every seat.** Seats live in the relay's memory, each holding a player's
connection to Sporcle, and the new container starts with none. They do not end in silence:
before the new container boots, the kit's `pre-app-boot` step
(`.kamal/steps/drain-seats`) sends the running relay `SIGUSR2`, and `Seats.Drain` closes
every seat with `shutdown`, so each phone says the relay restarted and offers to join
again. Deploy between games, and stop deploys while one is on:

```bash
.kamal/kit/bin/kit freeze "game night"
.kamal/kit/bin/kit unfreeze
```

Afterwards, from the checkout (with `.kamal/kit.local.env` loaded: `set -a;
. .kamal/kit.local.env; set +a`):

```bash
kamal app logs -f -c deploy/deploy.yml
kamal app details -c deploy/deploy.yml
```

## Rolling back

Kamal keeps the last five containers on the server, so going back is a restart, not a
rebuild:

```bash
kamal app containers -c deploy/deploy.yml     # the versions still there
kamal rollback <version> -c deploy/deploy.yml
```

A failed smoke test after a deploy does this by itself.
