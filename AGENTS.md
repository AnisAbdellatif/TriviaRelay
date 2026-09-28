# AGENTS.md — rules for AI agents

The single source of truth for how agents work in this repo. When the owner gives a new rule,
add it here.

## 1. What this is

**Trivia Relay** plays Sporcle Party games through our own relay. The relay holds each player's
connection to Sporcle's game server, so a phone that drops and comes back never shows as
disconnected, and gets one complete snapshot of everything it missed. It is a third-party
client: not made by Sporcle, and never presented as Sporcle's (no Sporcle name, logo or
branding in the app; its text may say it works with Sporcle Party). It is released as an APK
on GitHub, not on Google Play.

- `protocol/`: the contracts.
  - `PROTOCOL.md` is the phone ↔ relay contract (ours).
  - `SPORCLE.md` is what we know of Sporcle's own protocol, all of it reverse-engineered and
    confirmed live.
  - `fixtures/` holds what both sides test against.
- `server/`: the relay, Elixir/Phoenix, no database. It also holds `mix spike`, the console
  that plays a Sporcle game from a terminal and logs every frame (`server/creds/`,
  `server/logs/`, both git-ignored).
- `app/`: the Flutter app, Android + Web, built from FazouraParty's app
  (`~/dev/FazouraParty/app`).
- `deploy/`, `.kamal/`: the image and the Kamal config, deployed with deploy-kit to
  FazouraParty's VPS (`deploy/README.md`). `.kamal/kit/` is vendored: change it only with
  `kit update`.
- `scripts/ci.sh`: every check CI runs, runnable locally; `.github/workflows/ci.yml` only
  calls it.

## 2. Git

- Work on `dev`; `main` is what gets released. Open a PR to `main` only when a set of changes
  is done and tested.
- Never commit without the owner asking. Never add an AI as author or co-author.
- Never commit credentials, tokens, frame logs, `decisions.md`, `.kamal/kit.local.env` or a
  signing key.
- Never deploy, push a tag or publish a release without the owner asking. CI never deploys;
  a person runs `kit deploy` from `main`.

## 3. The contracts

- `protocol/PROTOCOL.md` is frozen: a change updates the spec, the fixtures and both sides
  together. The version is `major.minor` and only the major is on the wire. Removing or
  changing what an app relies on is a major; anything an app of that major copes with is a
  minor.
- Every number both sides share is in `protocol/fixtures/constants.json`, and each side's
  tests hold its own constants to it.
- The snapshots in `protocol/fixtures/snapshots/` are rendered by the relay
  (`UPDATE_FIXTURES=1 mix test`) and parsed by the app's tests. Regenerate them only for a
  deliberate change.
- A snapshot is always complete, never a delta, and paced (at most one per
  `broadcast_interval_ms`). Deadlines are absolute relay timestamps: Sporcle sends none, so
  the relay times each question from its arrival.
- Anything learned about Sporcle goes into `SPORCLE.md` with how it was confirmed (live, or
  decompiled only).

## 4. The relay

- **Credentials pass through, never stay.**
  - A player's Sporcle token comes with each request and is used for that one Sporcle call.
  - The web build's login passes the password through `/api/login` and nowhere else.
  - Neither is stored or logged: `password`, `token` and `player` are filtered from logs,
    and channel joins are never logged.
  - Pack search takes credentials in headers, never the URL.
- **One `Seat` process per player** (no per-game process: seats never interact). It owns the
  upstream socket and folds Sporcle's events into a pure `Seats.State`. `Seats.View` builds
  the snapshot and `Seats.Intents` turns phone intents into Sporcle messages. Keep game
  knowledge in those pure modules, not in the GenServer or the channel.
- **The relay enforces what the official app enforces on the device** (one use per wager, one
  answer per question), because Sporcle's server does not.
- **Hide what the official app hides**: the answer stays out of a snapshot until the host
  reveals, and other players' guesses until the player has answered.
- **A seat with no phone is held for `SEAT_HOLD_SECONDS`** (a deployment setting, default
  300). While held, the relay answers for the player when a question's time runs out, as the
  official app does.
- The relay's own socket to Sporcle failing is reported as `lost`. Recovering from it (a new
  `joinGame` with the player's token) is deliberately not built yet.
- **Games are invite-only (`private`) unless the host chooses otherwise.** `anyone` is public,
  and strangers join within seconds; the spike console requires `--audience` for the same
  reason.
- Must pass: `mix format --check-formatted`, `mix compile --warnings-as-errors`,
  `mix credo --strict`, `mix test` (all of them: `scripts/ci.sh server`).

## 5. The app

- Built from FazouraParty's app:
  - its `Fz*` widgets, motion and navigation (`lib/shared/`), restyled to the Trivia Relay
    design canvas (https://claude.ai/artifact/Paezq4BHSeaUd4XLqfiZTt): its own palette,
    fonts and mark;
  - the Phoenix connection pattern (`PhoenixSeatConnection`);
  - the update mechanism (`lib/core/update/`).
  Follow that app's conventions: Riverpod + freezed, feature-first folders, `reduceMotion`,
  `FzDirection` for anything a person wrote.
- `lib/core` outside `providers/` and `storage/` is pure Dart.
- Providers depend on `SeatConnection`, never on the transport.
- The app keeps the Party credentials a login returns and a random device id, never a
  password. Android logs in on the device (`SporcleLogin`); the web build asks the relay.
- Closing the game screen does not leave the game (the relay holds the seat). Only the leave
  button leaves.
- Agents test the app on the Web build only (`flutter test`, `flutter build web`). Never
  drive the Android emulator.
- Must pass: `dart format --set-exit-if-changed`, `flutter analyze`, `flutter test` (all of
  them, and the web build: `scripts/ci.sh app`).

## 6. Decision log

`decisions.md` at the root (git-ignored) records why things are the way they are, one section
per topic, current state only. Check it before non-trivial work and update it when a choice
is made.
