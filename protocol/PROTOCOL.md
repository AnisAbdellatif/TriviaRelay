# Trivia Relay — phone ↔ relay protocol

The contract between the Trivia Relay app and the relay server (`server/`). What the relay
says to Sporcle is in [SPORCLE.md](SPORCLE.md); this document never depends on it.

## 1. Conventions

- JSON everywhere, keys in `snake_case`. Times are Unix milliseconds on the relay's clock.
- Every fixed number both sides share is in [`fixtures/constants.json`](fixtures/constants.json),
  and each side's tests require its own constants to equal that file.

### 1.1 Versioning

The version is `major.minor` (`constants.json` → `protocol_version`), and only the major is
on the wire. A relay refuses a channel join whose major differs from its own
(`version_mismatch`) and accepts any minor. Changing or removing something an app already
relies on is a major. Anything a correct app of that major already copes with (a new
optional field, a new enum value, a new intent) is a minor. Both sides always report the
same `major.minor`.

## 2. Transport

- HTTP: `https://<relay>/api/…`.
- WebSocket: `wss://<relay>/socket/websocket?vsn=2.0.0`, Phoenix channels (V2 JSON
  serializer), permessage-deflate offered by the relay.

## 3. HTTP

Errors are `{"code": "...", "message": "..."}`. The app branches on the code; the message
is for a person. Every endpoint below is rate-limited per address, and answers
`429 rate_limited` with `retry-after` when over. Since 1.2, an IPv6 address is limited per
/64 and again (with more room) per /48.

Every endpoint that asks Sporcle something may also answer `503 relay_busy` with
`retry-after`: the relay is already waiting on as many Sporcle calls as it allows, and
refuses at once rather than queueing. (Since 1.2.)

Sporcle credentials ("the player") are `{player_id, token, device_id, handle, name}`:
- `player_id` and `token` are the Party credentials a login returns.
- `device_id` is a random 16-hex id the app makes once per install: 16 lowercase hex digits,
  anything else is refused (`400 invalid_player`, or `invalid_request` for a login; since
  1.2).
- `handle` is the player's Sporcle handle, as the login returned it.
- `name`, optional, is the name other players see in a game; without one (or when nothing of
  it is left once cleaned: control, bidi and zero-width characters go, at most 40
  characters), they see the handle. Only taking a seat (§3.3) uses it. (Since 1.2; before,
  the handle was that name.)

The relay uses them for the one Sporcle call a request makes and keeps none of them.

Where an endpoint below takes the player "in headers", they are `x-player-id`,
`x-player-token`, `x-device-id` and `x-player-handle`, never the URL.

Since 1.2, an endpoint that asks Sporcle to do something for the player (§3.2's pack
actions, §3.5, §3.6, §3.7) answers `409 sporcle_refused` when Sporcle turns it down with a
refusal of its own, and `401 sporcle_auth` when the sign-in has expired.

### 3.1 `POST /api/login`

`{email, password}` → `200 {player_id, token, handle}`. Only the web build uses this, since a
browser may not call sporcle.com itself; the Android app runs the same chain on the phone.
The password goes to Sporcle and nowhere else, and is never logged.

The request must come from the relay's own web app: its `Origin` is the relay's (since 1.2).

Errors:
- `400 invalid_request`: no email or password, or a `device_id` that isn't 16 hex digits.
- `401 login_failed`: the email and password don't match an account.
- `403 forbidden_origin`: the request didn't come from the relay's own web app.
- `429 rate_limited`: besides the per-address limit, failed logins are limited per email, and
  across the relay: after too many failures in a minute from anywhere, every login is
  refused until the minute ends. (Since 1.2.)
- `502 sporcle_unavailable`: Sporcle didn't answer.

### 3.2 `GET /api/packs?q=<text>&list=<list>&page=<n>`

The player goes in headers, never the URL: `x-player-id`, `x-player-token`, `x-device-id`,
`x-player-handle`.

`list` is one of `pack_lists` in `constants.json` (`popular`, `fresh`, `bookmarked`,
`created`, `friends`, `purchased`, `free`, `all`), the official app's pack-screen tabs; the
personal ones are the player's own. With a `list`, `q` may be empty: the list is browsed.
Without one, `q` searches the whole catalog. Pages start at 0 and hold up to 20.

Returns `200 {packs: [{id, name, description, image_url, num_questions, has_images,
play_count, bookmarked, subscribed}], next_page}`. `image_url` is null for a pack without a
picture. `next_page` is null once a page comes back empty, the end of the list.
`400 invalid_list` for an unknown `list`.

`bookmarked` and `subscribed` are whether this player bookmarked the pack and subscribed to
it, or null when the relay can't say: always null in the lists everybody sees (`popular`
and `fresh` browsed without a search), which the relay keeps a minute for everybody.
(Since 1.2.)

A pack, and what a player does to one (since 1.2; the player in headers):
- `GET /api/packs/<id>` → `200 {pack}`, one pack as above, `bookmarked` and `subscribed`
  included when Sporcle says. `404 pack_not_found`.
- `GET /api/packs/random` → `200 {pack}`: whatever pack the catalog picks this time, which
  a host may then host or switch to like any other.
- `POST /api/packs/<id>/bookmark` `{bookmarked: bool}` → `200 {bookmarked}`: bookmark the
  pack, or stop. Bookmarks are the player's own (`list=bookmarked`); Sporcle limits how
  many a player keeps, and refuses past it (`409 sporcle_refused`).
- `POST /api/packs/<id>/subscribe` `{subscribed: bool}` → `200 {subscribed}`: Sporcle tells
  a subscriber when somebody hosts the pack, in Sporcle Party's own app.
- `POST /api/packs/<id>/report` `{reason, details}` → `204`: report the pack to Sporcle.
  `reason` is one of `pack_report_reasons` in `constants.json` (`harassment`, `offensive`,
  `spam`, `inaccurate`, `other`), and `details` is what is wrong, 1–200 characters; else
  `400 invalid_request`. Reports are limited per Sporcle account as well as per address
  (`429 rate_limited`).

### 3.3 Taking a seat

- `POST /api/seats` `{code, player}`: join the Sporcle game `code` (4–8 digits).
- `POST /api/seats/host` `{pack_id, options, player}`: create a game of the pack and seat its
  host. `options` is `{questions_per_game, question_seconds, audience, spectate}`, each one
  of the values in `constants.json`. `audience` is `private` (invite only), `friends` or
  `anyone` (listed publicly: strangers join within seconds). `spectate` is optional and
  false when missing: true hosts the game without playing it (§6.4; since 1.2).

Both answer `201 {seat_id, seat_token, game_code, poppers}`. The relay now holds the
player's place in the game. The app joins `seat:<seat_id>` with the token (§4.1), and
presents the same token every time it reconnects. `poppers` is how many Party Poppers
Sporcle says the player had as they took the seat, or null (since 1.2; §3.5).

`POST /api/seats/pack` `{seat_token, pack_id, player}`: a pack chosen in the `lobby`. The
relay fetches the pack with the player's credentials. The host's changes the game's pack,
and everyone's next snapshot carries it; anybody else's is a vote for it (`pack_votes`,
§6.5; since 1.2). Answers `204`, or `401 invalid_token`, `404 seat_not_found`, or `409` with
`wrong_phase`, `not_live`, `too_many_votes` or `draft_pack` (the player's own pack that
isn't live yet), besides the errors below.

Errors:
- `400 invalid_code`, `invalid_player` or `invalid_options`.
- `404 pack_not_found`.
- `401 sporcle_auth`: the Sporcle sign-in has expired; log in again.
- `409 game_refused`: Sporcle answered without a place in the game, and `message` is what it
  said.
- `409 insufficient_poppers`: the game has pictures, joining it costs a player who isn't its
  host a Party Popper, and the player has none left (§3.5). (Since 1.2; before, this was a
  `game_refused`.)
- `429 rate_limited`: besides the per-address limits, each Sporcle account may create and
  join only so many games in a while, and joins Sporcle refuses (a wrong code) are limited
  more tightly, per account and per address. (Since 1.2.)
- `502 sporcle_unavailable`.
- `503 seats_full`: the relay holds as many seats as it can; try again later. Checked before
  Sporcle is asked, so the player has not been seated. (Since 1.2.)

A seat with no app connected is held for a time the deployment sets (`SEAT_HOLD_SECONDS`,
default 300). While it is held, the player stays in the game as far as Sporcle and everyone
else can tell, and when a question's time runs out the relay answers for them the way the
official app does (§6.3). Then the seat leaves the game.

Limits on a seat (since 1.2):
- An app joins its new seat (§4.1) right away: until one has, the seat is held for only a
  short time the deployment sets (30 s by default), never longer than the hold.
- A seat lives at most a day, as its token does, app or no app (`seat_closed` `expired`).
- A player has one seat at a time. A new seat for the same Sporcle account ends the one
  they had (`seat_closed` `left` with `replaced`, §5.2); in the same game, the new seat
  keeps what the old one spent: the questions answered, the wagers used, the final vote and
  wager.
- A few apps may be joined to a seat at once (3 by default). One more joining closes the channel of the
  one that joined first, with no `seat_closed` (it is not the seat that ended), so that app
  stops rejoining.

### 3.4 `GET /api/games`

The games the player could join, as the official app's join screen lists them. The player
goes in headers, as for §3.2. Joining one is `POST /api/seats` with its `code` (§3.3).

Returns `200 {games: [{code, list, pack, host, player_count, stage, question_number,
has_images}]}`:
- `list` is one of `game_lists` in `constants.json`: `invited` (the player was invited),
  `friends` (a friend's game) or `public` (a game hosted for `anyone`). Games come in that
  order. Within each list, games still in their lobby come first, then the games with the
  most players. A game in more than one list is listed once, in the first.
- `pack` is `{id, name, description, image_url}`, or null.
- `host` is the host's name. `player_count` counts everybody in the game.
- `stage` is where the game is: `lobby`, `question` (`question_number` is the question it is
  on, from 1), `final`, or `playing` when the relay can't tell. Joining after the lobby
  seats the player mid-game. (Since 1.2.)
- `has_images`: the game has pictures, and joining it costs a player one Party Popper
  (§3.5).

### 3.5 Party Poppers

A game with pictures costs everyone but its host one Party Popper to join; Sporcle refuses
a player with none (`409 insufficient_poppers`, §3.3). Sporcle gives one back every 4
hours, up to 5, once the player claims them. Buying more is for Sporcle Party's own app.
The relay learns the count from a seat (`poppers`, §3.3) and from a claim. (Since 1.2.)
While the player is in a game, the seat's snapshot counts the Popper off when Sporcle
spends it (`you.poppers`, §5.1).

`POST /api/poppers/claim`, the player in headers → `200 {poppers, last_claim}`: claims
whatever has been given back, and says how many the player has now and when they last
claimed (ms), either null when Sporcle doesn't say. A claim with nothing to give back
changes nothing and answers the same way.

### 3.6 Friends and invitations

Since 1.2, the player in headers:
- `GET /api/friends?page=<n>` → `200 {friends: [{id, name, handle}], next_page}`: the
  player's Sporcle friends (accepted ones, not requests), by name. `id` is what an
  invitation takes. Pages start at 0; `next_page` is null after an empty page.
- `POST /api/invites` `{seat_token, code, pack_id, friend_id}` → `204`: Sporcle tells the
  friend `friend_id`, or every friend when it is null, that the player is in game `code`
  with pack `pack_id`. Only from a seat this player holds: `401 invalid_token`,
  `404 seat_not_found`. `400 invalid_code` or `invalid_request` for a code or friend id
  that can't be one. Limited per Sporcle account as well as per address, invitations to
  everybody more tightly (`429 rate_limited`).

### 3.7 `POST /api/names/check`

`{name}`, the player in headers → `200 {name, allowed}`: `name` cleaned as the relay would
pass it on (§3), and whether Sporcle accepts it as a name to show, as its own app asks
before saving one. `400 invalid_request` when nothing of the name is left. The app keeps
the name and sends it with each seat it takes; the relay keeps nothing. (Since 1.2.)

### 3.8 Invite links

`https://<relay>/join/<code>`, with a game code (4–8 digits): the relay's web app, which
offers to join that game once the player is signed in, and never joins without them saying
so. Anything else under `/join/` is `404`. The Android app opens these links itself when
the relay vouches for it: `GET /.well-known/assetlinks.json` names the released app and its
signing key's fingerprints, from the deployment's `ANDROID_CERT_SHA256`, and is `404`
without them. (Since 1.2.)

## 4. App → relay

### 4.1 `phx_join` on `seat:<seat_id>`

`{seat_token, protocol_version: <major>}`. On success the relay pushes a `state` at once.
Failures:
- `version_mismatch`.
- `invalid_token`.
- `seat_not_found`: the seat has ended; this is final.
- `rate_limited`: failed joins are limited to 30 a minute per address; joins that work are
  never counted.

The WebSocket itself may be refused (`403` on the upgrade) when an address opens too many,
or holds too many open at once, and a message larger than 16 KB, sent whole or in fragments,
closes it (`1009`). (Since 1.2.)

### 4.2 Intents

Pushed on the seat channel; each replies `ok` or an error `{code, message}`. They are
checked against the seat's state, so an app may send any of them at any time:

| event | payload | when |
|---|---|---|
| `ready` | `{ready: bool}` | any time the game is live; one that changes nothing is `ok` and not passed on |
| `draft` | `{text, wager}` | while typing; what the relay answers with if time runs out |
| `answer` | `{text, wager}` | `question`: `wager` must be in `you.wager_choices`. `final_question`: the final wager is used, whatever is sent. The text is trimmed and cut to `answer_max_length` (80; since 1.2, 200 before) |
| `final_vote` | `{choice}`, one of `final_votes` (`easy`, `medium`, `hard`) | `final_vote`, once |
| `final_wager` | `{amount}` | `final_wager`, once; one of `final_wagers` |
| `play_again` | `{}` | `final_scores`, once (again is `ok` and does nothing); the host's starts the next game |
| `rate` | `{rating}`: 1 (thumb up), -1 (down) or 0 (neither) | while `you.can_rate`: the question on screen, once answered and while revealed. One that changes nothing is `ok` and not passed on. Since 1.2 |
| `report` | `{reason}`, one of `question_report_reasons` (`inaccurate`, `typo`, `offensive`) | while `you.can_rate`, once a question (again is `ok` and does nothing). Since 1.2 |
| `pack_vote` | `{pack_id, vote: bool}` | `lobby`, not the host: a vote for one of `pack_votes`, or taking one's own back. A pack nobody voted for yet is voted for with `POST /api/seats/pack` (§3.3). At most `max_pack_votes` (5) packs a game (`too_many_votes`); a vote that changes nothing is `ok`. Since 1.2 |
| `leave` | `{}` | any time: the seat leaves the game and closes |
| `chat_open` | `{}` | any time: this app shows the chat (§6.6). Since 1.2 |
| `chat_close` | `{}` | any time: this app no longer shows it. Since 1.2 |
| `chat_send` | `{text}` | any time: a message to everyone in the game, cleaned (control, bidi and zero-width characters go) and cut to `chat_max_length` (256); nothing left is `invalid_intent`. Since 1.2 |
| `chat_typing` | `{typing: bool}` | while the chat is open: the player started or stopped typing. One that changes nothing, or a start with the chat closed, is `ok` and not passed on. Since 1.2 |
| `chat_more` | `{}` | earlier messages, `chat.has_more` (§6.6). Since 1.2 |
| `honk` | `{peer_id}` | any time: the goose, to one other player who is in the game (§6.7). Since 1.2 |
| `react` | `{peer_id, type}` | the same, with a sound of `reaction_types` (only `goose` so far); another is `invalid_intent`. Since 1.2 |

A host who spectates (`you.spectating`) plays no part: `draft`, `answer`, `final_vote` and
`final_wager` are refused with `spectating` (since 1.2).

Host only (`you.host`); anybody else gets `not_host`:

| event | payload | when |
|---|---|---|
| `start` | `{}` | `lobby` |
| `options` | `{questions_per_game, question_seconds, audience, spectate}` | `lobby`. `spectate` is optional (since 1.2): missing, the host keeps spectating or playing as now |
| `reveal` | `{}` | `question`, `final_question`, once `you.can_reveal` |
| `judge` | `{peer_id, correct: bool}` | `reveal`, `final_reveal`: mark one of `players` (anybody else is `invalid_intent`) |
| `judge_submit` | `{}` | `reveal`, `final_reveal`: settle the marks and the scores |
| `next` | `{}` | `reveal`: next question (after the last one, into the final). `final_vote`: move on before everyone voted. `final_wager`: ask the final question. `final_reveal`: show the final scores |
| `remove` | `{peer_id, ban: bool}` | any phase: take a player out of the game, free to join again, or for good (`ban`). Since 1.2 |
| `make_host` | `{peer_id}` | any phase: hand the host to a player. Since 1.2 |
| `to_lobby` | `{}` | any phase but `lobby`: end the game, everyone back to the lobby of the same game. Since 1.2 |

`remove` and `make_host` name another player who is in the game and connected; anybody else
(the host themselves, a player who is away, nobody) is `invalid_intent`.

Other error codes:
- `not_live`: the relay isn't connected to the game yet.
- `wrong_phase`.
- `already_answered`, `already_voted`, `already_wagered`.
- `not_everyone_answered`: a `reveal` before `you.can_reveal`.
- `invalid_wager`, `invalid_options`, `invalid_intent`.
- `spectating`, `too_many_votes`, `draft_pack` (since 1.2).
- `rate_limited`: 60 intents per 10 s, per connection and again per seat (all its apps
  together). Since 1.2, what reaches other players is limited again per seat: 5
  `chat_send` per 10 s, 10 `chat_typing` per 10 s, 10 `chat_more` a minute, and 15
  reactions (`honk`, `react`) a minute, at most one every `reaction_gap_ms` (2 s).

## 5. Relay → app

### 5.1 `state`

A complete snapshot every time, never a delta. At most one every `broadcast_interval_ms`;
changes in between are folded into the next.

```
protocol_version, protocol_minor, server_time, game_code,
status:   connecting | live | lost | removed
phase:    lobby | question | reveal | final_vote | final_wager |
          final_question | final_reveal | final_scores
pack:     {id, name, description, image_url, num_questions, has_images} | null
options:  {questions_per_game, question_seconds}
rounds:   [{index, percent}]        percent of players who get each question right
question: {index, text, category, difficulty, image_url, final} | null
deadline: ms | null                 when the open question, vote or wager closes
players:  [{peer_id, name, host, connected, ready, ready_for_next_game, spectating, score,
            answered, guess, final_wagered, reactions: {total, recent: [type]}}]
you:      {peer_id, host, can_reveal, answer: {text, wager} | null, wager_choices: [int],
           judgements: {"<peer_id>": bool}, judged, played_again, spectating, can_rate,
           rating, reported, poppers}
reveal:   {answer, answers: [{peer_id, text, wager, correct, score}]} | null
final:    {votes: {easy, medium, hard}, picked, vote, wager, wagers: [{peer_id, wager}],
           next_game_code} | null
notice:   {kind, level, title, message, until} | null
countdown: {kind, until} | null
pack_votes: [{pack, votes, voters: [peer_id], you}]
chat:     {messages: [{id, peer_id, name, text, image_url, system, at, own}], unread,
           typing: [name], open, has_more, loading}
reactions: [{id, peer_id, type, until}]
```

- `status`:
  - `lost` means the relay's connection to the game failed; the seat can't recover it yet.
  - `removed` means the host removed the player (`seat_closed` follows).
- `players[].answered` is set only while a question is open. `guess` is that player's answer
  text, or null (§6.2). `final_wagered` is set only while wagering.
- `you.can_reveal` is set for the host while a question is open and may be revealed: once
  every player who is playing (not spectating, still connected) has answered, or 5 s after
  `deadline`, as the official app allows.
- `you.judgements` holds the host's marks so far (empty for anybody else). `you.judged` is
  set once they are submitted for this question.
- `final.wager` is this seat's final wager, placed from the app or listed by Sporcle.
  `final.wagers` is everybody's, except during `final_vote` and `final_wager`: then it holds
  this seat's own at most, and `players[].final_wagered` says who else has wagered (§6.2).
  (Since 1.2.)

Since 1.2:
- `players[].spectating`: a host who hosts without playing (§6.4). `players[].ready_for_next_game`
  is Sporcle's own flag, passed on as it comes; what sets it isn't confirmed, and the app
  doesn't show it.
- `you.spectating` is this seat's own. `you.can_rate` is set while the question on screen may
  be rated and reported (once answered, and while revealed); `you.rating` (1, -1, 0) and
  `you.reported` are this seat's for it.
- `final.next_game_code`: on the final scores, the code of the next game when it started
  without this seat (§6.1). Null otherwise.
- `notice` is something to tell the player for a moment, shown until `until` (and gone from
  the snapshot after it). `kind` is `to_lobby` (the host returned everyone to the lobby; the
  host isn't told), `promoted` (the host handed this player the game), `host_left` (the
  host left, and the game is this player's), `popper_spent` (joining this game with
  pictures cost the player a Party Popper, spent as play starts), or `server`, a message
  from the game itself:
  then `title` and `message` are its words (at most 200 and 2000 characters), and `level`
  is `info`, `warn`, `error` or `success`. `level` is `info` for the others, whose words
  are the app's. An app shows a `kind` it doesn't know only if it has a `title` or
  `message`.
- `countdown`: the count down before the open question shows, on every phone at once:
  `kind` is `start` (the game's first question, `start_countdown_ms`) or `final` (the
  final question, `final_countdown_ms`). The question's clock starts at `until`, so
  `deadline` is `until` plus the question's seconds. Null once it has passed.
- `pack_votes`: in the `lobby`, the packs players voted for, the most voted first (then by
  name). `pack` is as the snapshot's `pack`; `voters` are the peer ids of the voters still
  in the game, `votes` counts all of them; `you` is set when this seat's player voted for it.
  Empty outside the lobby.
- `you.poppers`: the Party Poppers Sporcle said the player had as they took the seat (as
  §3.3's `poppers`), less any it has spent since; null when Sporcle didn't say.
- `chat` (§6.6): the latest messages, oldest first, the last 20 until the app asks for
  more (`chat_more`), from the last 50 the relay keeps. `id` is the message's own;
  `peer_id` is the sender's while they are in the game, else null; `name` is the name the
  message carries (null for a `system` message, which is the game's own); `text` may be
  empty when there is a picture (`image_url`, https only); `at` is when it arrived, or for
  history when it says it was written (never later than it arrived); `own` marks this
  player's. `unread` counts other players' messages since the chat was last open on any
  app, at least 1 when Sporcle says there is something new without saying what. `typing`
  names the others typing. `open` is whether the chat is open for this seat (an app has
  it open); `has_more` whether there is more before the first message; `loading` while
  the relay waits on Sporcle for it.
- `reactions` (§6.7): reactions other players sent this one, each shown until `until` and
  gone from the snapshot after it; `peer_id` is the sender, `type` one of
  `reaction_sounds` (or another, which an app plays as the goose). `id` grows with each
  one, so an app plays each once.
- `players[].reactions`: the reactions each player has had in this game, as Sporcle counts
  them (`total`), and the latest few `reaction_sounds` among them (`recent`, oldest first).

### 5.2 `seat_closed`

`{reason, can_rejoin, replaced}`, after which the channel closes and the seat no longer
exists:

| reason | meaning |
|---|---|
| `left` | the player left. With `replaced: true`, the same player took another seat, on this app or another (since 1.2; an app that doesn't know it reads it as left) |
| `expired` | no app came back within the hold, or the seat reached its maximum age (a day) |
| `removed` | the host removed the player. `can_rejoin` is false when Sporcle won't let them back in: the host kicked them for good, or they were kicked before and this was them trying to join again. Only with `removed`; since 1.2, and an app treats it missing as true |
| `shutdown` | the relay is restarting |

## 6. The game

### 6.1 Phases

- `lobby`: players gather and mark themselves ready. The host sets the options and starts.
- `question`: open for `options.question_seconds`. Each player answers once, with a wager.
- `reveal`: the host has revealed the question. The host marks each answer right or wrong,
  submits, then moves on.
- The final round:
  1. `final_vote`: everyone votes for an easy, medium or hard final question.
  2. `final_wager`: once every vote is in, everyone wagers.
  3. `final_question`: the host asks it.
  4. `final_reveal`: the host reveals and judges it.
  5. `final_scores`: the end of the game, once the marks are submitted (or the host's
     `next` skips them).
- Anybody may `play_again` (`you.played_again` once they have). The host's brings everyone
  back to `lobby`, in the same game. When the next game starts without this seat (Sporcle
  gives it a code of its own), `final.next_game_code` carries it: playing again is then
  joining it, `POST /api/seats` with that code (since 1.2).
- The host may send everyone back to the `lobby` from anywhere in a game (`to_lobby`), and
  everybody else is told (`notice`). (Since 1.2.)
- The game's first question comes after a count down of `start_countdown_ms`, the final
  question after one of `final_countdown_ms` (`countdown`): every official app counts down
  from the question's arrival and starts its clock after, and so does the relay. (Since
  1.2.)
- A seat that joins a game under way (a late join, or a rejoin) lands where the game is:
  on the open question with the time it has left, or on its reveal, the final's vote or
  wagers, the final question or the scores; the wagers the player already used are gone
  from `you.wager_choices`, and a question they already answered shows as answered.
  (Since 1.2.)

### 6.2 Visibility

While a question is open (`question`, `final_question`), `reveal` is null: nobody sees the
correct answer until the host reveals. Until a player has answered, they see who has answered
and nothing of what. Once they have, `players[].guess` carries everybody's guess as it comes
in, as the official app shows it on its waiting screen. Sporcle sends all of this on every
submission; the relay withholds what the official app would not show. (Since 1.1.)

Final wagers are the same: Sporcle lists every amount as it is placed, and until the final
question is asked a seat sees only its own, so nobody wagers knowing the others'. (Since
1.2.)

### 6.3 Wagers and scoring

- Each of 1..`questions_per_game` can be wagered once a game; `you.wager_choices` is what is
  left.
- A right answer scores `+wager`; a wrong one scores 0.
- The final wager is one of `final_wagers`. A wrong final answer scores `−wager`.
- The host's marks are final: the relay reports scores, never computes them.
- The wagers used are the ones this seat sent and the ones Sporcle lists as used, whichever
  seat or app sent them. (Since 1.2.)
- When a question closes and the player hasn't answered, the relay answers for them with the
  last `draft` (or nothing) and its wager if still available, else the lowest wager left.
  This is what the official app does, and it means an absent player never loses a turn.

### 6.4 Hosting as a spectator

(Since 1.2.) A host may run the game without playing it (`options.spectate`), as the
official app's "Host this game as a spectator": no answer, no final vote and no final
wager (`spectating`), and the relay never answers for them when time runs out. They still
reveal, mark, and move the game on; nobody waits for their answer, vote or wager. While a
question is open they see who has answered, not what (§6.2). They come last in the
standings, with no score, and can't win.

### 6.5 Pack votes

(Since 1.2.) In the lobby, players other than the host vote for packs they would rather
play, up to `max_pack_votes` a game, as in the official app: a new pack with
`POST /api/seats/pack` (§3.3), one already voted for with `pack_vote`, which also takes a
vote back. The host sees the tallies (`pack_votes`) and plays one with the same
`POST /api/seats/pack`. Nobody votes for their own pack that isn't live yet (`draft_pack`).

### 6.6 Chat

(Since 1.2.) Everyone in the game shares one chat, as in the official app. An app says when
it shows the chat (`chat_open`) and when it stops (`chat_close`); the relay has the chat open
with the game while any app joined to the seat shows it, and closes it when the last one
stops or goes, so a seat held with no app never opens it. Opening loads the latest
messages and reads the unread ones. Messages still arrive while it is closed, counted in
`chat.unread`. The official app offers the chat everywhere but while a player answers a
question or votes for the final; the relay takes a message at any time.

### 6.7 Reactions

(Since 1.2.) A player sends a sound to another (`honk`, `react`), which that player's app
plays, naming the sender (`reactions`), and which the game counts for everyone to see
(`players[].reactions`). The official app sells more sounds in packs; the relay sends only
the free one, the goose, and passes on whatever sound another player sends.

## 7. Fixtures

- [`fixtures/constants.json`](fixtures/constants.json): the shared numbers.
- [`fixtures/sporcle/hosted_game.json`](fixtures/sporcle/hosted_game.json): a real game, as
  its host's Sporcle connection received it, with ids and names replaced. The relay's state
  tests replay it.
