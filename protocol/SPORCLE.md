# sporcle_relay — spike

The first step towards a relay between a Fazoura-style app and Sporcle Party's servers.
The relay would hold each player's GameLift connection, so a phone can drop and come back
without Sporcle ever seeing it, and would hand the phone complete state snapshots rather than
Sporcle's stream of events.

This spike answers the questions that design depends on. It plays one Sporcle game as one player
from a terminal and logs every frame in both directions. The protocol itself is documented in
`~/dev/sporcle_scraper/PROTOCOL.md`.

## Running it

```bash
mix deps.get
```

Credentials come from the scraper. Each `creds/<name>.json` holds one account's Party player id
and token, never a password. `creds/` is git-ignored:

```bash
mkdir -p creds
(cd ~/dev/sporcle_scraper && uv run -q sporcle token HOST) > creds/host.json
(cd ~/dev/sporcle_scraper && uv run -q sporcle token JOIN) > creds/join.json
```

A token that has expired makes `createGame` or `joinGame` answer 401 or 403. To get a new one,
run `uv run sporcle login --slot HOST` in the scraper, then repeat the lines above.

```bash
mix spike host --cred host --pack 268682 --audience anyone --seconds 20 --questions 10
mix spike join 892562 --cred join
```

**`--audience anyone` lists the game publicly, and strangers join within seconds** (the first
run had one after 10 s, then several more). The value for a private game isn't known yet, so
the flag is required rather than defaulting to something public. Look for it in the
game-options screen of the decompiled bundle.

Type `help` at the prompt. The commands that matter are `ready`, `start`, `a <answer>`,
`reveal` and `next` for playing, and `drop`, `rejoin` and `reuse` for the experiments. The
console prints a summary of each event. `logs/<time>-<role>-<cred>.jsonl` holds everything: one
line per frame, with its direction, the connection (`c1`, `c2`, … since a rejoin opens a new
one), the time since that connection last received anything, the decoded event, every envelope
field and the raw hex. Logs are git-ignored because they contain other players' ids.

## Layout

| Module | |
|---|---|
| `Envelope` | GameLift Realtime framing: varint length + protobuf, JSON in field 15. Tested byte for byte against the scraper's codec. |
| `Identity` | Everything tied to a particular Sporcle app version: key, version, user agents, the login player JSON. |
| `Api` | `getPack`, `createGame`, `joinGame`. Credentials are passed with each call and never kept. |
| `Upstream` | One player's GameLift socket: connect, login, pong, log, report to its owner. This is the part the relay keeps. |
| `Session` | The console's player: creates or joins over REST, owns the `Upstream`, runs commands. |
| `FrameLog` | The JSONL log. |
| `mix spike` | The terminal front end. |

## Findings (first run, 2026-09-27)

A 3-question game hosted from here, with a second account joining from here.

**Transport**
- Plain Elixir TLS works for REST and for the game socket (Mint + permessage-deflate). The
  scraper's Chrome TLS imitation is not needed for these calls. The www.sporcle.com login is
  the one request still to try.
- Login returns a GameLift frame with no game JSON: `op 1`, and field 31 holding what looks
  like a peer id, a UDP port, `"NotImplementedYet"` and a certificate.
- **Keepalive is WebSocket ping/pong.** The server pings every 30 s, and answering with a pong
  is enough. No game-level keepalive was seen in about two and a half minutes.

**Game flow**
- `game_question` carries only `question`, `questionCategory`, `questionDifficulty` and
  `questionIndex`. **There is no deadline or countdown.** The official app must time the
  question itself from `gameOptions.QUESTION_SECONDS`, so a relay has to set the deadline
  itself, when the question arrives.
- `list_answers` is pushed after every submission (each player's `guessText`, `correct`,
  `score`, `wagerAmount`), not only at the reveal. When the host sends `advance_all`, it is
  echoed to everyone.
- **A player's own `player_update` (`readyForGame`) is not sent back to them**, only to the
  other players (confirmed live: host and joiner each got the other's, never their own).
  The official app must track its own ready on the device, so the relay records it when
  it sends it. `start_game` then pushes a `player_update` for everyone.
- Seen: `game_info`, `game_connect`, `game_question`, `list_answers`, `advance_all`,
  `player_connect`, `player_disconnect`, `player_update`. Not yet seen: judging, the final
  round, poppers, chat, and the end of a game.

**Disconnect and rejoin** (the question the relay exists for)
- A dropped player's answer to the current question **disappears** from `list_answers` for
  everyone.
- **A fresh `joinGame` with the same account and code gets the seat back mid-game.** The
  player gets a new peer id (2 → 4), but the server matches them by `playerId`: the earlier
  answer and wager reappeared under the new peer id. The rejoining connection got
  `game_info`, then `game_connect` with `currentView` (here `"GameShowAnswer"`), then the
  current question's `list_answers`.
- **A player session is single-use.** Reconnecting with the old `PlayerSessionId` upgrades
  the socket and accepts the login, then sends no game state, only pings. The server hadn't
  closed it after more than a minute. So a login's success has to be judged by whether
  `game_info` arrives, not by whether the socket stays up.

**A full game** (second run: hosted on the official app, joined from here, 5 questions plus the
final round, about 3½ minutes)
- **Round plan.** The `game_info` that starts the game carries `allRounds`: each question
  index with a `percent` (percent correct, the same number as `questionDifficulty`). Here it
  was 8 entries for 5 questions: 0–4 for the regular round, plus entries past 4 that seem to
  be the final-round candidates (the "easy" final was index 5, 67%).
- **Wagers.** Every answer carries its own `wagerAmount`. The phone used 5, 4, 3, 2, 1, once
  each. A correct answer scores `+wager` and a wrong one scores 0. The server accepted a
  wager of 0 and the same wager twice from us, so whether it enforces the one-use rule, and
  how, is still open.
- **The final round.** A `game_question` with only `questionIndex` opens the vote.
  `vote_final_round` is answered with running tallies (`finalVotes`, `votedPlayers`).
  `advance_all {currentView: "CAST_WAGER", pickedVote, questionIndex}` moves everyone to
  wagering, and `list_final_wagers` shows who has wagered. Then the real `game_question`
  arrives with the same index. **The final answer must carry the final wager in its own
  `wagerAmount`**: ours sent 0 and staked nothing, while the phone's carried 20 and lost 20
  (a wrong final answer scores `−wager`). The console now does this for you.
- **Judging.** The server's automatic check marks answers (a transliteration like
  "germany" for "المانيا" came back wrong). The host then toggles players: `judgement_update`
  carries the whole `playerJudgements` map on every tap, including un-marking. Once the host
  submits, a final `list_answers` arrives with correctness and scores settled, followed by
  `judged_answers` (null payload). A question with no toggles still gets both.
- **What a player sees after answering** (decompiled only, 1.5.15). Submitting moves the
  player's own screen from `GameAnswerQuestion` to `GameAnswerWait`, which lists every player
  with their `guessText` from each `list_answers` as it arrives (hidden only for spectators).
  The correct answer and the right/wrong colours wait for `GameShowAnswer`, the host's
  `advance_all`. Once every non-spectator has answered, the app stops the timer, and the
  host's "See Answer" is enabled only then, or 5 s after time ran out. Nothing reveals on
  its own: in every logged game, `advance_all` followed the host.
- **The final vote has three choices** (decompiled only, 1.5.15): `voteType` `easy`,
  `medium` or `hard`, all three always offered. It fits the round plan's three entries past
  the regular questions.
- **Browsing the catalog** (confirmed live, 2026-09-28): the official app's pack tabs are
  `searchPacks` with an empty `searchText` and `filters` JSON `{type, sort}`: `mostPopular`
  with `play_count`, `mostRecent` with `date_desc`, and `bookmarked`, `created`, `friends`,
  `purchased`, `free`, `all` with an empty sort. Pages of 20; the page after the last is
  empty. Search text combines with a type. `img_src` is an empty string for a pack without a
  picture. The image hosts (`static.sporcle.com`, a CloudFront bucket) send no CORS headers.
- **Changing the pack in the lobby** (decompiled only, 1.5.15): the host sends
  `change_pack {gamePack: <the pack>}`, the catalog's map for it, and every client listens
  for `change_pack` with the same payload. The app refuses the host's own draft packs
  (`active: false`). Other players can vote for a pack instead (`pack_votes`). The relay
  sends the pack as `getPack` returns it, as for `createGame`: not yet tried live, nor
  whether the sender gets `change_pack` back (the relay records it either way).
- **The end of the final** (decompiled only, 1.5.15): on `judged_answers` during the final's
  `showAnswer`, every client moves by itself to its final reveal, then its final
  scoreboard. Nothing comes from the server, which fits the full game above. The host's
  `advance_all {currentView: "score"}` is a shortcut, not the only way.
- **Play again** (decompiled only, 1.5.15): the final scoreboard offers "Play Again" to
  everyone, and each client sends `play_again` once, then waits. The host's brings everyone
  to `next_game` (confirmed live). What a non-host's does on the server isn't known yet;
  players carry a `readyForNextGame` flag, and clients also listen for `leave_behind`.
- `currentView` values seen: `GameShowAnswer`, `CAST_WAGER`, `showAnswer` (the final).
- **No game-over event.** After the final `judged_answers`, nothing more arrived until the
  host left. Then came `player_disconnect` (the host), **`promote_to_host {oldHostLeft: true}`**
  to us, and a `player_update` marking us as host. **Sporcle has host migration**, and a
  relay's client has to be able to become the host at any time.
- The connection held for the whole game on pings alone (every 30 s; the longest silence was
  27 s).

**Hosting** (third run: hosted from here with options in the login, both accounts from here;
confirmed live, and matching the decompiled app)
- **Game options are read from the host's GameLift login, not from `createGame`.** The
  official app sends them in both places: `createGame {gamePack, gameOptions}` and the login's
  `gameOptions` (plus `spectate`). With both, the server took 5 questions at 15 s. Offered
  values: questions 5/10/15/20, seconds 15/30/45/60, audience `private` ("Invite Only"),
  `friends` or `anyone`. The official app's defaults: 10, 45, `friends`. `private` works: no
  stranger appeared in five minutes, where the public game drew one within 10 s.
  `game_info.gameOptions` reports only the question count and seconds. Lobby edits are
  `edit_options {flat map}` (not yet tried live).
- **A regular question, from the host's side:** `advance_all {currentView: "GameShowAnswer"}`
  reveals. Each tap on a player sends `judgement_update {questionIndex, playerJudgements}`
  carrying the whole map, which is echoed to everyone. `judge_answers` (same payload)
  submits, and the server answers with the settled `list_answers` and `judged_answers`. Then
  `next_question {questionIndex, toFinalRound: questionIndex == QUESTIONS_PER_GAME - 1}`.
- **Wagers are the client's rule, not the server's.** The server accepted a wager of 1 five
  times in a row. In the official app, each of 1..QUESTIONS_PER_GAME can be used once, and a
  question that times out spends the lowest unused one. Final wagers are 0, 10 or 20.
- **The final round, from the host's side:**
  1. `next_question` with `toFinalRound: true` after the last question gives everyone a
     `game_question` carrying only `questionIndex`: the vote.
  2. Once everyone has voted, **the server itself** sends `advance_all {currentView:
     "CAST_WAGER", pickedVote, questionIndex}`. A 1–1 tie picked the host's vote.
     `advance_all {currentView: "voteCategory"}` is the host's force-advance when not everyone
     has voted.
  3. After the wagers (`list_final_wagers`), the host sends `next_question {questionIndex:
     <final index − 1>}` **with no `toFinalRound`**; the real question follows.
     `toFinalRound: true` at this point restarts the final at the vote.
  4. `advance_all {currentView: "showAnswer"}` reveals the final. Judging works as in a
     regular question. A wrong final answer is charged −wager at once, and marking it right
     turns that into +wager.
  5. `advance_all {currentView: "score"}` shows the final standings. That is the only end
     of a game.
- **Play again:** after the final scores, the host's `play_again` sends everyone `next_game`
  with the pack, which puts them back in the lobby of the same game.

**What this means for the relay**
- Sporcle's server already keeps a player's seat through a rejoin, so the relay doesn't have
  to fake one. Where the relay adds value:
  - **The disconnect never happens.** Holding the socket means a phone's blip never removes
    an answer, and the host never sees a `player_disconnect`.
  - **A rejoin can recover from anything.** When the relay's own upstream socket fails, it
    calls `joinGame` again, which needs a player token from the phone at that moment.
  - **Complete snapshots.** A rejoining phone gets the whole state, including a deadline
    the relay computed, which Sporcle never sends.

## Login: email + password → Party credentials (confirmed live 2026-09-28)

Captured from the official app (`RE/find_connect.py`) after its old login path stopped
working. Two requests, in one session (cookies carried between them):

1. `GET www.sporcle.com/login/?party_udid=<device udid>` — primes the session for the
   Party app. It sets a `_spmob` session cookie **only when the request carries the Party
   app user agent** (`party/1.5.15.297 …`); a desktop UA gets an ordinary web page and no
   party context.
2. `POST www.sporcle.com/auth/ajax/login.php` with `{email, passwd, remember}` and the
   cookies from step 1 → `{success, logged_in, user_id, handle, token}`. `user_id` is the
   sporcle_id (e.g. `xAc71a08as`, the `X-SPORCLE-PLAYER`), `token` is the 64-hex
   `X-SPORCLE-TOKEN`. Without step 1 (or with the wrong UA) the response is only
   `{success, logged_in}` — no token.

The token is bound to the `party_udid`, so the same value must be sent as `X-UDID` on
every Party API call afterwards.

**What used to be done and no longer works:** reading `user_id`/`user_key` off
`/apps/party/` and POSTing them to `spn.sporcle.com/api/spn/connect/sporcle`. Sporcle
removed those fields from the page and `connect/sporcle` now refuses them (`login_failed`
/ `invalid`). `connect/sporcle` isn't needed at all — the token comes straight from
`login.php` in party context. The gate that broke the scraper was the missing priming GET
and, in the relay/app, the wrong user agent. Implemented in
`sporcle_scraper/sporcle/auth.py` (`party_login`), `server/…/sporcle/login.ex`, and
`app/…/sporcle/sporcle_login.dart`.

## Still open
- `edit_options` in the lobby, `bounce` (kick) and `promote_new_host`, all untried live.
- A player dropping and rejoining during the final round and during judging (only mid-question
  was tested).
- The host: what happens when the host drops and rejoins, and what a host this client was
  promoted to has to send to carry on.
- Chat and poppers, and a game longer than 20 minutes.
