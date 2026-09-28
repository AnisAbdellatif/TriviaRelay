# Trivia Relay

Plays [Sporcle Party](https://www.sporcle.com/apps/party/) games through a relay that keeps
your place when your phone drops. Not made by Sporcle; you play with your own Sporcle
account.

- **relay** (`server/`): Phoenix, no database. It holds each player's connection to
  Sporcle's game server, folds what arrives into one state, and sends the phone a complete
  snapshot whenever it changes. A phone that drops keeps its seat for `SEAT_HOLD_SECONDS`;
  Sporcle never sees it leave.
- **app** (`app/`): Flutter, Android and Web. Sign in with Sporcle, join a game by its code or
  host one from Sporcle's pack catalog, and play through the final round. The web app is
  served by the relay; the Android app is an APK released on GitHub.
- **protocol** (`protocol/`): [PROTOCOL.md](protocol/PROTOCOL.md) (app ↔ relay),
  [SPORCLE.md](protocol/SPORCLE.md) (what we know of Sporcle's own protocol), and the shared
  fixtures.
- **deploy** (`deploy/`, `.kamal/`): the Docker image and the Kamal config, deployed with
  [deploy-kit](https://github.com/AnisAbdellatif/deploy-kit). See
  [deploy/README.md](deploy/README.md).

The look (palette, type, the mark, the app icon) comes from the
[Trivia Relay design canvas](https://claude.ai/artifact/Paezq4BHSeaUd4XLqfiZTt).

## Running it locally

```bash
cd app && flutter build web
cd ../server && mix deps.get && WEB_DIR=../app/build/web mix phx.server
```

Then open http://localhost:4100. To work on the app with hot reload instead, run the relay
as above and `flutter run -d chrome` in `app/`: a debug build talks to `localhost:4100`.

Configuration (environment):

| variable | meaning |
|---|---|
| `SPORCLE_API_KEY` | **required.** The Sporcle Party app's API key; [`server/.env.example`](server/.env.example) says what it is and how to get it. In development, put it in `server/.env` |
| `SEAT_HOLD_SECONDS` | how long a seat stays in its game with no phone attached (default 300) |
| `WEB_DIR` | the built web app, served at `/` |
| `TRUST_PROXY` | how many `X-Forwarded-For` entries are our own proxies |
| `SECRET_KEY_BASE`, `PHX_HOST`, `PORT` | as for any Phoenix release |

## Checks

Everything CI runs is in [`scripts/ci.sh`](scripts/ci.sh), and runs the same way locally:

```bash
scripts/ci.sh            # server + app + image, what a pull request runs
scripts/ci.sh server     # mix compile, format, credo, test
scripts/ci.sh app        # dart format, flutter analyze, flutter test, flutter build web
scripts/ci.sh image      # the production Docker image (after `app`)
```

The toolchain CI uses is pinned at the top of that script (Elixir 1.20.4 on OTP 29,
Flutter 3.47.4); a different local version runs the checks with a warning.

## Deploying

The relay runs on a VPS with [Kamal](https://kamal-deploy.org), behind the host's Caddy,
driven by [deploy-kit](https://github.com/AnisAbdellatif/deploy-kit) (vendored in
`.kamal/kit`). **CI tests and builds; a person deploys.** A push to `main` runs every check,
builds the image, pushes it to `ghcr.io/anisabdellatif/triviarelay` and signs a build
attestation for it. Deploying is one command, from an up-to-date `main`:

```bash
.kamal/kit/bin/kit deploy
```

It refuses unless the checkout is `main`, clean and pushed, CI passed for that commit, and
the image carries CI's attestation; then it swaps the container with no downtime and checks
`/health` from outside, rolling back if that fails. A deploy ends every seat (they live in
memory), so deploy between games, and `kit freeze` while one is on. The one-time setup of
the server, Caddy, secrets and your machine is in [deploy/README.md](deploy/README.md).

## Releasing the Android app

The web app is reloaded from the relay; the Android app is on no store, so it carries its
own update check. Tagging is the whole release process:

```bash
# bump `version:` in app/pubspec.yaml first — both halves, name and build number
git tag -a v0.2.0 -m "What changed, in a line"
git push origin v0.2.0
```

That runs both suites, builds a signed universal APK, and publishes it as a GitHub release
with a small `android.json` manifest. An installed app reads that manifest from
`releases/latest/download/android.json` at most once every six hours, and offers the
download on the home screen and in Settings. Tapping it opens the APK in the browser;
the app never installs anything itself. A tag with a suffix (`v1.0.0-rc.1`) is published
as a pre-release, which `latest` skips.

`scripts/ci.sh apk` refuses to build unless the tag matches `app/pubspec.yaml`, the build
number is above the last release's, and the tagged commit is on `main`.

### The signing key

Every release must be signed with the **same** key, or Android refuses to install one over
another and every user has to uninstall and reinstall. Generate one once and keep it safe:

```bash
keytool -genkeypair -v -keystore trivia-relay-release.jks -alias trivia-relay -keyalg RSA -keysize 2048 -validity 10000
```

`keytool` writes PKCS12, which has one password for the store and the key: give both the
same one. Then add it to the repository's **production** environment, as secrets:

| Secret | What it is |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | `base64 -w0 trivia-relay-release.jks` |
| `ANDROID_KEYSTORE_PASSWORD` | the keystore password |
| `ANDROID_KEY_ALIAS` | `trivia-relay` |
| `ANDROID_KEY_PASSWORD` | the same password |

The APK also needs to know which relay to talk to (Android has no origin to infer one
from), so set the `PUBLIC_HOST` repository variable to the relay's domain.

The release job runs in the `production` environment so the key is not a repository-wide
secret. In *Settings → Environments → production*, allow `main` and the tag pattern `v*`
and nothing else, and add a tag ruleset for `v*` that only maintainers can create.

To build one locally, put the same values in `app/android/key.properties` (`storeFile`,
`storePassword`, `keyAlias`, `keyPassword`; git-ignored) and run:

```bash
SERVER_URL=https://your.relay scripts/ci.sh apk
```

Anything built another way (`flutter run`, a hand-run `flutter build apk`) is a development
build: it installs as **Trivia Relay Dev** (`com.triviarelay.app.dev`), beside the release
rather than over it.

## The spike console

`mix spike` (in `server/`) plays one Sporcle game from a terminal as one player and logs every
frame to `server/logs/`. It's useful for checking Sporcle's behaviour before building on it.
Credentials come from `~/dev/sporcle_scraper` (`sporcle token HOST > server/creds/host.json`).

```bash
mix spike host --cred host --pack 156070 --audience private --questions 5 --seconds 15
mix spike join <code> --cred join
```

## Licence

[MIT](LICENSE). The bundled fonts (`app/assets/fonts/`) are under the SIL Open Font
Licence, each with its `OFL-*.txt`; the vendored deploy-kit (`.kamal/kit/`) carries its own
licence. Sporcle and Sporcle Party are Sporcle's; this project is not affiliated with them.
