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
`429 rate_limited` with `retry-after` when over.

Sporcle credentials ("the player") are `{player_id, token, device_id, handle}`:
- `player_id` and `token` are the Party credentials a login returns.
- `device_id` is a random 16-hex id the app makes once per install.
- `handle` is the name other players see.

The relay uses them for the one Sporcle call a request makes and keeps none of them.

### 3.1 `POST /api/login`

`{email, password}` → `200 {player_id, token, handle}`. Only the web build uses this, since a
browser may not call sporcle.com itself; the Android app runs the same chain on the phone.
The password goes to Sporcle and nowhere else, and is never logged.

Errors:
- `401 login_failed`: the email and password don't match an account.
- `502 sporcle_unavailable`: Sporcle didn't answer.

### 3.2 `GET /api/packs?q=<text>&list=<list>&page=<n>`

The player goes in headers, never the URL: `x-player-id`, `x-player-token`, `x-device-id`,
`x-player-handle`.

`list` is one of `pack_lists` in `constants.json` (`popular`, `fresh`, `bookmarked`,
`created`, `friends`, `purchased`, `free`, `all`), the official app's pack-screen tabs; the
personal ones are the player's own. With a `list`, `q` may be empty: the list is browsed.
Without one, `q` searches the whole catalog. Pages start at 0 and hold up to 20.

Returns `200 {packs: [{id, name, description, image_url, num_questions, has_images,
play_count}], next_page}`. `image_url` is null for a pack without a picture. `next_page` is
null once a page comes back empty, the end of the list. `400 invalid_list` for an unknown
`list`.

### 3.3 Taking a seat

- `POST /api/seats` `{code, player}`: join the Sporcle game `code` (4–8 digits).
- `POST /api/seats/host` `{pack_id, options, player}`: create a game of the pack and seat its
  host. `options` is `{questions_per_game, question_seconds, audience}`, each one of the
  values in `constants.json`. `audience` is `private` (invite only), `friends` or `anyone`
  (listed publicly: strangers join within seconds).

Both answer `201 {seat_id, seat_token, game_code}`. The relay now holds the player's place in
the game. The app joins `seat:<seat_id>` with the token (§4.1), and presents the same token
every time it reconnects.

`POST /api/seats/pack` `{seat_token, pack_id, player}`: the host changes the pack while in the
`lobby`. The relay fetches the pack with the player's credentials and the game switches to
it; everyone's next snapshot carries it. Answers `204`, or `401 invalid_token`,
`404 seat_not_found`, or `409` with `not_host`, `wrong_phase` or `not_live`, besides the
errors below.

Errors:
- `400 invalid_code`, `invalid_player` or `invalid_options`.
- `404 pack_not_found`.
- `401 sporcle_auth`: the Sporcle sign-in has expired; log in again.
- `409 game_refused`: Sporcle answered without a place in the game, and `message` is what it
  said.
- `502 sporcle_unavailable`.

A seat with no app connected is held for a time the deployment sets (`SEAT_HOLD_SECONDS`,
default 300). While it is held, the player stays in the game as far as Sporcle and everyone
else can tell, and when a question's time runs out the relay answers for them the way the
official app does (§6.3). Then the seat leaves the game.

## 4. App → relay

### 4.1 `phx_join` on `seat:<seat_id>`

`{seat_token, protocol_version: <major>}`. On success the relay pushes a `state` at once.
Failures:
- `version_mismatch`.
- `invalid_token`.
- `seat_not_found`: the seat has ended; this is final.
- `rate_limited`: failed joins are limited to 30 a minute per address; joins that work are
  never counted.

### 4.2 Intents

Pushed on the seat channel; each replies `ok` or an error `{code, message}`. They are
checked against the seat's state, so an app may send any of them at any time:

| event | payload | when |
|---|---|---|
| `ready` | `{ready: bool}` | any time the game is live |
| `draft` | `{text, wager}` | while typing; what the relay answers with if time runs out |
| `answer` | `{text, wager}` | `question`: `wager` must be in `you.wager_choices`. `final_question`: the final wager is used, whatever is sent |
| `final_vote` | `{choice}`, one of `final_votes` (`easy`, `medium`, `hard`) | `final_vote`, once |
| `final_wager` | `{amount}` | `final_wager`, once; one of `final_wagers` |
| `play_again` | `{}` | `final_scores`, once (again is `ok` and does nothing); the host's starts the next game |
| `leave` | `{}` | any time: the seat leaves the game and closes |

Host only (`you.host`); anybody else gets `not_host`:

| event | payload | when |
|---|---|---|
| `start` | `{}` | `lobby` |
| `options` | `{questions_per_game, question_seconds, audience}` | `lobby` |
| `reveal` | `{}` | `question`, `final_question`, once `you.can_reveal` |
| `judge` | `{peer_id, correct: bool}` | `reveal`, `final_reveal`: mark one player |
| `judge_submit` | `{}` | `reveal`, `final_reveal`: settle the marks and the scores |
| `next` | `{}` | `reveal`: next question (after the last one, into the final). `final_vote`: move on before everyone voted. `final_wager`: ask the final question. `final_reveal`: show the final scores |

Other error codes:
- `not_live`: the relay isn't connected to the game yet.
- `wrong_phase`.
- `already_answered`, `already_voted`, `already_wagered`.
- `not_everyone_answered`: a `reveal` before `you.can_reveal`.
- `invalid_wager`, `invalid_options`, `invalid_intent`.
- `rate_limited`: 60 intents per 10 s.

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
players:  [{peer_id, name, host, connected, ready, score, answered, guess, final_wagered}]
you:      {peer_id, host, can_reveal, answer: {text, wager} | null, wager_choices: [int],
           judgements: {"<peer_id>": bool}, judged, played_again}
reveal:   {answer, answers: [{peer_id, text, wager, correct, score}]} | null
final:    {votes: {easy, medium, hard}, picked, vote, wager, wagers: [{peer_id, wager}]} | null
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

### 5.2 `seat_closed`

`{reason}`, after which the channel closes and the seat no longer exists:

| reason | meaning |
|---|---|
| `left` | the player left |
| `expired` | no app came back within the hold |
| `removed` | the host removed the player |
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
  back to `lobby`, in the same game.

### 6.2 Visibility

While a question is open (`question`, `final_question`), `reveal` is null: nobody sees the
correct answer until the host reveals. Until a player has answered, they see who has answered
and nothing of what. Once they have, `players[].guess` carries everybody's guess as it comes
in, as the official app shows it on its waiting screen. Sporcle sends all of this on every
submission; the relay withholds what the official app would not show. (Since 1.1.)

### 6.3 Wagers and scoring

- Each of 1..`questions_per_game` can be wagered once a game; `you.wager_choices` is what is
  left.
- A right answer scores `+wager`; a wrong one scores 0.
- The final wager is one of `final_wagers`. A wrong final answer scores `−wager`.
- The host's marks are final: the relay reports scores, never computes them.
- When a question closes and the player hasn't answered, the relay answers for them with the
  last `draft` (or nothing) and its wager if still available, else the lowest wager left.
  This is what the official app does, and it means an absent player never loses a turn.

## 7. Fixtures

- [`fixtures/constants.json`](fixtures/constants.json): the shared numbers.
- [`fixtures/sporcle/hosted_game.json`](fixtures/sporcle/hosted_game.json): a real game, as
  its host's Sporcle connection received it, with ids and names replaced. The relay's state
  tests replay it.
