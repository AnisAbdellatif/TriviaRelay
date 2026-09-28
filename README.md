# Trivia Relay

Plays [Sporcle Party](https://www.sporcle.com/apps/party/) games through a relay that keeps
your place when your phone drops. Not made by Sporcle; you play with your own Sporcle
account.

- **relay** (`server/`): Phoenix, no database. It holds each player's connection to
  Sporcle's game server, folds what arrives into one state, and sends the phone a complete
  snapshot whenever it changes. A phone that drops keeps its seat for `SEAT_HOLD_SECONDS`;
  Sporcle never sees it leave.
- **app** (`app/`): Flutter, Android and Web. Sign in with Sporcle, join a game by its code or
  host one from Sporcle's pack catalog, and play through the final round.
- **protocol** (`protocol/`): [PROTOCOL.md](protocol/PROTOCOL.md) (app ↔ relay),
  [SPORCLE.md](protocol/SPORCLE.md) (what we know of Sporcle's own protocol), and the shared
  fixtures.

## Running it locally

```bash
cd app && flutter build web
cd ../server && mix deps.get && WEB_DIR=../app/build/web mix phx.server
```

Then open http://localhost:4100. To work on the app with hot reload instead, run the relay
as above and `flutter run -d chrome` in `app/`: a debug build talks to `localhost:4100`. Configuration (environment):

| variable | meaning |
|---|---|
| `SPORCLE_API_KEY` | **required.** The Sporcle Party app's API key; [`server/.env.example`](server/.env.example) says what it is and how to get it. In development, put it in `server/.env` |
| `SEAT_HOLD_SECONDS` | how long a seat stays in its game with no phone attached (default 300) |
| `WEB_DIR` | the built web app, served at `/` |
| `TRUST_PROXY` | how many `X-Forwarded-For` entries are our own proxies |
| `SECRET_KEY_BASE`, `PHX_HOST`, `PORT` | as for any Phoenix release |

## Checks

```bash
cd server && mix format --check-formatted && mix credo --strict && mix test
cd app && dart format --set-exit-if-changed lib test && flutter analyze && flutter test
```

## The spike console

`mix spike` (in `server/`) plays one Sporcle game from a terminal as one player and logs every
frame to `server/logs/`. It's useful for checking Sporcle's behaviour before building on it.
Credentials come from `~/dev/sporcle_scraper` (`sporcle token HOST > server/creds/host.json`).

```bash
mix spike host --cred host --pack 156070 --audience private --questions 5 --seconds 15
mix spike join <code> --cred join
```
