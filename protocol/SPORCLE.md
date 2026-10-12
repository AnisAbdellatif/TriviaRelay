# Trivia Relay — spike

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
  with their `guessText` from each `list_answers` as it arrives (a spectating host sees only
  who has answered).
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
- **Joinable games** (confirmed live, 2026-09-28): `GET getJoinableGames`, no parameters,
  answers `{invitedGames, friendGames, publicGames}`, each a list of `{gameCode, gamePack:
  {id (a string), name, description, img_src}, gameScreen, host: {playerId,
  sporcleHandle}, currentHost, playerCount, hasImages, creationTime, location, distance}`.
  `gameScreen` was `Lobby`, `Question <n>` (from 1) or `Final Question`. One call listed 78
  public games, 55 of them in their lobby, the rest mid-game. `distance` (km) ranks them from
  the caller; its origin is unknown (the relay sends no location), so the relay ignores it.
  Joining one is the usual `joinGame` with its code. The official app also listens for
  live changes over an API-Gateway socket (`registerForJoinScreenUpdates`), which isn't used.
- **Removing a player** (decompiled only, 1.5.15): the host's player menu offers "Eject"
  (they may rejoin) and "Kick" (they may not), each sending `bounce {peerId, playerId,
  noReturn}` with `noReturn` true for a kick. The removed player's client handles `bounce`
  without checking whom it names, so Sporcle sends it to that player alone: it reads
  `noReturn` and `reject`, disconnects, and shows "The host just ejected you" (with "Join
  Again"), "You have been kicked from this game and may not rejoin", or, for `reject` (a
  kicked player joining again), "You cannot join this game". What reaches the other
  players isn't known yet; Sporcle does close the removed player's socket itself, with
  close code `4000 "Eject"` (confirmed live, 2026-10-12; see "The host's player menu").
- **Changing the pack in the lobby** (decompiled only, 1.5.15): the host sends
  `change_pack {gamePack: <the pack>}`, the catalog's map for it, and every client listens
  for `change_pack` with the same payload. The app refuses the host's own draft packs
  (`active: false`). Other players vote for packs instead (see "Pack votes" below). The relay
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

## Host and game flow (2026-09-29)

From the decompiled bundle of the official app 1.5.15 (`sporcle_re/bundle_decompiled.js`;
`@N` is a line in it), except where a point says it was confirmed live (the spike's frame
logs of 2026-09-27). Nothing here was tried live from the relay yet.

**Joining a game under way** (confirmed live for a rejoin during a reveal, 2026-09-27; the
rest decompiled only, `_onGameConnect` @547907–548030)
- The rejoining connection got `game_info` (players, `gameOptions`, **no `allRounds`**),
  then `game_connect {inLobby: false, midRoundJoin: true, currentView: "GameShowAnswer",
  questionIndex, question, questionText, questionCategory, timeElapsed: 35,
  usedWagers: {"0": false, "3": false}, questions: [{questionIndex, guessText,
  wagerAmount, answer, correct, score}], packVotes, gamePack}`, then the current
  question's `list_answers` (live). `questions` lists the player's own answers so far,
  the current question's included; the official app doesn't read it.
- The official app reads `questionIndex`, `questionText`, `questionCategory`,
  `questionImgSrc`, `currentView`, `usedWagers`, `timeElapsed` (seconds: its clock is
  `QUESTION_SECONDS - timeElapsed`, @1689992, @1692194), and for the final `pickedVote`
  and `judgeSubmitted`. A `questionIndex` below `QUESTIONS_PER_GAME` is the regular round
  (`GameLoop`), otherwise the final (`FinalRound`) (@547946).
- `currentView` values the app knows: regular `GameAnswerQuestion` (the default),
  `GameAnswerWait` (answered, waiting), `GameShowAnswer`, `MidRoundScores` (@1689564);
  final `VOTE_CATEGORY` (the default), `CAST_WAGER`, `wait` (wagers in), `question`,
  `answered`, `showAnswer`, `FINAL_REVEAL`, `score` (@1710698). In the final,
  `timeElapsed` is used only for `question` (@547980); `judgeSubmitted` goes straight to
  the final scores (@1711275).
- `usedWagers` is `{"<wager>": mark}`, the mark true or false once judged, null before
  (@1688290). `list_answers.playerWagers` is the same map for the player receiving it (the
  host's own used wagers, in the recorded game: confirmed live), and `update_wagers
  {wagers}` replaces it (received only, @1688923). The official app disables a used wager
  rather than hiding it; on a timeout it spends the first unused one (@1689209).
- `allRounds` appears nowhere in the bundle: the official app ignores it (`onGameInfo`
  @292722 copies `gameOptions` and resets nothing).

**The start** (decompiled only)
- The host's "Start the Game" (@1644718) asks "Not all players are ready." / "Start
  anyways?" when any player (the host included) isn't `readyForGame` (@1641455), then
  sends `start_game` with no payload (@1641410). The button waits for everyone ready, or
  30 s after the lobby opened, and needs a second player (@1644262); the relay doesn't
  enforce those two.
- Every client, the host's included, answers the first `game_question` in the lobby with a
  local 5 s "We're starting in" count down (`CountdownModal`, @1642810, @1754449), and only
  then shows the question and starts its clock. There is no count down event. The final
  question gets a 3 s "Final question in" the same way (@1711923).

**Hosting as a spectator** (decompiled only)
- The `SPECTATE` option (default false, @549711) is the switch "Host this game as a
  spectator" in the pack screen's "More options" (@547182), and "Host the game as a
  spectator" in the lobby's and the game's settings (@607982). It goes in `createGame`'s
  `gameOptions`, in the host's login (`spectate` and `gameOptions`, @548818), and later
  in `edit_options` with every other option (@607319). Only a host can spectate.
- A spectating host never answers: their question view starts at `GameAnswerWait`
  (@1688198), `forceSubmit` does nothing (@1689212), and other players' guesses show as
  "Answered" until the reveal (`hideAnswers`, @1689517, @1693150). They still reveal
  ("See Answer", waiting only for the non-spectators, @1689730), judge, and move on. In the
  final they neither vote (@1710911) nor wager (@1713790). Everyone's "all answered/
  wagered" counts skip spectators (@1711575); scores list them last with "Hosting"
  instead of a score (@1696163), and they can't win (@1707711).

**The host's player menu** (decompiled only; `UtilityModal.getActions` @1649199)
- Host only, never on oneself (@1648668), not on a disconnected player (@1649221), in any
  phase: the lobby, the question, the scoreboards and the final (@1644732, @1693182,
  @1707689, @1711048).
- "Make Host" asks "Promote <name> to Host?" and sends `promote_new_host {peerId}`
  (@1647571). The old host waits for the `player_update` about itself; the new host gets
  `promote_to_host {oldHostLeft}` and a banner "You're the new host!" / "The host has
  promoted you." (or "The host has left the game.") (@293357).
- "Eject" ("They will be able to rejoin") and "Kick" ("They will not be able to rejoin")
  ask "Eject/Kick <name> from the Game?" and send `bounce {peerId, playerId, noReturn}`
  (@1647491). Other players get no bounce-specific event; the official app drops a
  disconnected player from its list (@292866), which suggests a `player_disconnect`.

**The server does not check that these come from the host** (confirmed live, 2026-10-12,
a `private` game with two of our accounts). The menu is host-only in the official app, but
the server enforces nothing:
- A non-host sent `promote_new_host {peerId: <its own peer>}` and the server made it host:
  it got `promote_to_host {oldHostLeft: false}`, and a `player_update` with `isHost: true`
  for that peer went to everyone, the old host included. So any client can seize host.
- A non-host's `bounce {peerId: <a player>}` was honoured. The removed player received
  `bounce {gameCode, noReturn}` (not the `peerId`/`playerId` the sender named), and Sporcle
  then **closed that player's socket itself** with WebSocket close code `4000 "Eject"` (the
  earlier open question — whether Sporcle closes the socket — is answered: it does).
- Both reach a player through `sendTo` as well, so the sender need not even be in the game's
  player list as a host. The relay drops any game event that arrives from a peer rather than
  the server (see PROTOCOL/`Seat`), since that is the only sign it has of a forgery.

**Back to the lobby** (decompiled only)
- The host's "Go to Lobby" in the game's settings (@607019) asks "Are you sure you want to
  return to the lobby?" and sends `go_to_lobby` with no payload (@607052). Every client
  that receives `go_to_lobby` resets to the lobby with its payload (the pack at least); the
  others first show "Returned to Lobby" / "The Host returned everyone to the Game Lobby"
  (@293449).

**Banners** (decompiled only)
- `server_message {type, title, message, interval}` on the game socket (@293319) shows as
  the in-app banner: `type` `info`, `warn`, `error` or `success` colours its border,
  `interval` is how long it shows in ms (0: until dismissed), default 4750 (@1753594). A
  message without `interval` hides at once, in the official app.

**Pack votes** (decompiled only)
- In the lobby, a non-host's "Vote for Packs" opens the pack browser, where a tap votes
  for a pack (@1645445, @1627848): `vote_on_pack {gamePack}` with the whole pack, or
  `{gamePack, unvote: true}` to take it back (@1642012, @1642032). At most
  `MAX_PACK_VOTES` (5) packs per player per game (@549723, "You can vote for up to 5
  packs, per game."), never one's own draft (@1641943).
- Everyone gets `pack_votes {packVotes: {<packId>: {gamePack, voters: [playerId]}}}`
  (@1642890); `game_connect` and `next_game` carry `packVotes` too. The lobby's "N Pack
  Votes" button opens "Voted Packs", most voted first (@1752610); the host's tap on one
  sends `change_pack` (@1641740).

**Rating and reporting a question** (decompiled only)
- Once answered and while revealed (`GameAnswerWait`, `GameShowAnswer`, and the final's
  `answered` and `showAnswer`, @1690124, @1713319), a thumb up or down sends
  `rate_question {questionIndex, rating}`, 1 or -1, and tapping it again 0 (@1691027). As
  written, the official app sends the rating from before the tap, and no `questionIndex`
  in the final; the relay sends the new rating and the index. Nothing comes back.
- "Report Question" / "Find something wrong with this question?" offers "Inaccurate",
  "Typo / Spelling" and "Offensive Content", sent as `report_question {questionIndex,
  reason}` with `inaccurate`, `typo` or `offensive` (@1705257, @1705367). No reply.

**Answers** (decompiled only)
- `ANSWER_MAX_LENGTH` is 80 (@549716), the answer field's `maxLength` for the regular and
  the final question; the answer is trimmed when sent (@1689161).

**Play again and `leave_behind`** (decompiled only)
- The final scoreboard listens for `next_game`, `leave_behind`, `change_pack` and
  `list_answers` (@1707811). `leave_behind {gameCode}` stores the code and disconnects
  (@1708000); "Play Again" then joins that game: `joinGame {gameCode, location:
  "play_again"}` (@1707510). Without one it sends `play_again` (no payload), host or not,
  and waits for `next_game` (@1707480). A non-host playing again on a pack with pictures
  needs a popper (@1707404). Who gets `leave_behind` isn't known; presumably the players
  who hadn't pressed Play Again when the next game started.
- `joinGame`'s `location` is `code_field`, `link`, `room_list`, `play_again` or
  `reconnect` (@1608761, @1609811, @1610516, @1707510, @291865). It looks like analytics
  (the app logs it); the relay's joins send none, and they work (confirmed live).
- Players carry `readyForNextGame` (confirmed live, true for both players mid-game); the
  official app never reads it.

## Chat and reactions (decompiled only, 1.5.15)

None of this has been tried live, except where it says so. `@N` is a line of
`~/dev/sporcle_re/bundle_decompiled.js`.

**The envelope, and messages for one player**
- The game socket's client is GameLift Realtime's (`RTSClient` @1763898). Its `Packet`
  (@1772330–1772640) has f1 opcode, f2 sequence number, f3 target player, f4 target group,
  f5 sender, f6 reliable, f7 client version, f15 payload; `PLAYER_ID_SERVER` is 4294967295
  (@1771373), -1 as an int32, the f3 every game message carries. `send(event, payload)`
  targets the server; `sendTo(peer, event, payload)` (@1764100) is the same packet with
  the peer's id in f3 and the app's own peer id in f5, for that player alone. As
  decompiled, both set opcode 100 where the captured app sent 200 (and f5 8, its peer then);
  the relay keeps the captured 200 for both, and sends its own peer as f5.
- Messages from the server carry the receiving peer in f3 and -1 in f5 (confirmed live).

**Chat** (the `MessageBoard` screen @1721639, GiftedChat)
- Opening the chat screen sends `chat_open` (no payload), closing it `chat_close`
  (@1722139, @1722178). While open it listens for `chat_load`, `chat_message`,
  `chat_typing` and `chat_load_more`. The game screen listens for `chat_has_message` all
  the time (@294424), which only sets a red dot on the chat button
  (`chatHasUnreadMessages`, @293434); `chat_load` clears it (@1722222). The chat button
  (`MessageBoardButton` @1646065) also listens for `last_chat_message {message}`, shown as
  "name: text" on the button, and `chat_typing`, which animates it.
- `chat_load {messages, hasMore}` replaces the history (@1722200); `chat_load_more
  {messages, hasMore}` is older messages, prepended, in answer to `chat_load_more {page}`
  (@1721716), `page` counting 1, 2, … from the first. GiftedChat keeps messages newest
  first, so these lists presumably are too.
- A message is GiftedChat's: `{_id, text, createdAt, user, image?, system?}`. Sending
  (`onSend` @1721760) is `chat_message {message}` with the message as GiftedChat made it:
  a random `_id`, `createdAt` a date, and `user: {_id: getUserId() ("sporcle_id//<id>",
  @508460), peerId, name: teamName, mascotType, mascotCustomImageUrl, hatType, showHat:
  true, isHost}` (@1722950). The app adds it to its own list: Sporcle is not expected to
  send it back. The keyboard's GIFs go as `image` (a link) with the text. Received:
  `chat_message {message}`; the sender stops showing as typing.
- The field takes 256 characters (`maxLength`, `maxInputLength` @1723030) on one line, and
  the text is trimmed as it is sent. No moderation or filtering field is read anywhere;
  `system` messages (GiftedChat's) are drawn apart (@1722470).
- Typing: `chat_start_typing` (debounced 500 ms, leading) and `chat_stop_typing`
  (debounced 600 ms, trailing) as the field changes (@1721844, @1721869), no payloads.
  `chat_typing {whoseTyping: {<user id>: <name>}}` is the whole list; the app leaves itself
  out and shows up to three names, then "N more", "is/are typing..." (@1722080).
- Where: the chat button is on the lobby (@1644439), the list of players after answering
  and at the reveal (`PlayerList` @1693938, in `GameAnswerWait`), and the scoreboards
  (`PlayerScores` @1697394: between questions, the final's wager, answered and reveal
  views, the final scoreboard). Not while answering a question, nor on the final's vote.

**Reactions** (the player menu's "Your Sounds", @1647370–1647440)
- A sound is sent in two parts: `honk {peerId: <own peer>, honk_type: <type>}` with
  `sendTo` the player's peer (throttled to one every 2 s, leading, and played on the
  sender's phone too), then `send_u2u {playerId, peerId, type}` to the server, naming the
  player (throttled to one every 125 ms).
- Received: the game screen plays `honk_type` unless `peerId` is its own peer, at most one
  every 250 ms (`onHonk` @292110); the sender's mascot shakes wherever it shows (@392117).
- Sounds: `goose` (the Honk) is free and always offered; the rest come in paid packs
  (`SOUND_PACKS` @549890): `party.sound_pack.1` cow, donkey, goat, rooster, sheep;
  `.2` aww, clap, laugh, ooh, soccer_cheer; `.3` accordion, rim_shot, trombone, trumpet,
  tuba. The menu offers the goose and the player's own packs (`getSoundPacks` →
  `{mySoundPacks, lockedSoundPacks}`, @1647315); the relay sends only the goose.
- `list_u2u {u2u, u2uPerf}` is taken whole into the screen's state (`onListU2U` @1642729,
  @1688549, @1711459): `u2u` is by the player id who received, each `{total, stream,
  byType}`, `stream` being the latest as `"<type>-<id>"` and `byType[type].players` who
  sent them. Every list of players shows each player's `stream` and `total` (`PlayerU2U`
  @1651091), and a tap opens who sent what (`PlayerU2UModal` @1654591). `u2uPerf
  {animate, disable}` turns the animation off.
- Players carry `honksMap` (`{}` in every live game logged, confirmed live); nothing in
  the bundle reads it. The profile's "Honks Sent" and "Honks Received" (@1666403) are
  REST statistics.

**Party Poppers spent**
- `popper_spent` (no payload read, `onPopperSpent` @1688562): the game screen shows
  "Popper Spent" / "You used 1 Popper to join this image party. Let the fun begin!" and
  takes one off its count.

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

## Around the game: packs, Party Poppers, friends, names (decompiled only, 1.5.15)

None of this has been tried live. `@N` is a line of `~/dev/sporcle_re/bundle_decompiled.js`.
Every call below is on the Party API (`party.sporcle.com/api/party`, the same axios
instance and headers as `searchPacks`), and answers its payload as the body.

**Packs**
- `POST /bookmarkPack {pack_id, bookmarked}` (@505723) and `POST /subscribePack {pack_id,
  subscribed}` (@507915). Both call sites of each (@544339, @1641654 for bookmarks; @544079
  for subscriptions) send the pack's flag *as it was before the tap* and then flip it
  locally, so Sporcle must turn it over: `bookmarked: false` bookmarks. The relay sends the
  opposite of what it is asked for. Any failure of a bookmark is shown as "You have reached
  the limit of pack bookmarks". A subscription asks for push permission first: it is
  "notify me when someone starts a party in this pack", delivered as a push to the
  official app.
- A pack carries the player's own `bookmarked` and `subscribed` (confirmed live in the
  `gamePack` a `createGame` sent, which is `getPack`'s map with the host's flags).
- `POST /reportPack {pack_id, player_id, reason, extraInfoText}` (@507330). The pack
  screen's form (@552389) offers `harassment`, `offensive`, `spam`, `inaccurate`, `other`,
  requires a reason and some text (at most 200 characters), and sends no `player_id`. The
  in-game menu (@1610420) reports the game's pack with `player_id` = the host and
  `reason: "admin_delete"`, which reads as a moderator's tool.
- `GET /getRandomPack` (@506219), no parameters, answers `{pack}`. The pack screen shows
  it; the lobby's "Load a Random Pack" (@1645548, @1642117) checks it with `canHostPack`
  and switches to it.

**Party Poppers**
- `joinGame` answers `popper_count` and `popper_last_claim` beside the session (confirmed
  live for the count), or, instead of a session, `denied: {code, message}`. The codes the
  join screen handles (@291950–292000): `NeedLogin`, `Blocked` (with `audienceType`),
  `BuyPopper` ("Insufficient Poppers to join this image party", @291993), `GameNotFound`
  ("Looks like that Party is no longer going"), `GameFull`. `BuyPopper` opens the popper
  store (@548346).
- A non-host pays one Popper per game with images (the store's text, @1686731). The game
  screen listens for `popper_spent` (@1688421, handler @1688562): it takes one off the
  count and says "You used 1 Popper to join this image party". It is registered on the
  question screen, so the Popper is spent when play starts, not at the join.
- `POST /claimPoppers` (@505859), no body, answers `{popper_count, popper_last_claim}`
  (@1757664). `popper_last_claim` is Unix seconds; the store counts one claimable Popper
  per 14400 s since it, up to 5 minus the count (@1757930). Refills also come from a
  rewarded video (`deliverReward {type: "popper_rewarded_video"}`) and purchases, neither
  of which the relay offers.
- The official app also reads the count from `saveUser`'s answer at start-up (@294770);
  `saveUser` writes the profile, so the relay doesn't call it for that.

**Friends**
- `GET /getFriends?page=<n>` (@506471) answers `{friends}`, a map by the id an invitation
  takes, each a player (`playerId`, `sporcleHandle`, `teamName`, `friendStatus:
  {is_friend, sent, received}`, @1748605).
- `POST /inviteToGame {friend_uid, game}` (@507155) and `POST /inviteAllFriendsToGame
  {game}` (@507121), `game` being `{gameCode, gamePack: {id, name, img_src}}` (@1747700,
  @1642544). Plain REST with the player's credentials: nothing goes over the SigV4 social
  socket. "Invite all" in the friends list invites each friend one by one; the lobby sends
  `inviteAllFriendsToGame` once when the host asked to notify friends.

**Names**
- Edit Profile (@1574133) trims the team name, asks `GET /getHandleHasBadWords?handle=`
  (@506555, answers `{handle_has_bad_words}`), and refuses with "Invalid handle" when it is
  true. Otherwise it sends `player_update {teamName, …}` to the game it is in and saves it
  with `saveUser {fields: {team_name, …}}` (@507534).
- Players are shown by `teamName`, falling back to `sporcleHandle`, with "@" +
  `sporcleHandle` under it (@1665256, @1667399, @1648755). So `teamName` is the name to
  choose, and `sporcleHandle` stays the account's handle. The relay's login sends the
  player's chosen name as `teamName` only.

**Also seen**: the lobby's share is "Join My … Game!" and `<homepage>/join/<code>`
(@1641825); the official app keeps the screen awake from the game socket's `connect` to its
close (`activateKeepAwake`, @294417).

## Still open
- `edit_options` in the lobby, `bounce` (kick) and `promote_new_host`, all untried live.
  For `bounce`, what the removed player receives (the decompiled client reads only
  `noReturn` and `reject`) and what the others see; for `promote_new_host`, whether the old
  host gets a `player_update` about itself.
- `go_to_lobby`: its payload as received (the pack, `packVotes`?), and whether the host gets
  it back.
- `game_connect` for a late join mid-question (the `currentView` then, and whether
  `timeElapsed` counts from the question's arrival or from the end of the start's count
  down), and during the final.
- `server_message`, `update_wagers`, `pack_votes`, `vote_on_pack`, `rate_question`,
  `report_question`, `leave_behind`: none seen live. Whether Sporcle takes a
  `rate_question` of 0 as "no rating".
- `SPECTATE` in the login and in `edit_options`, and what everybody's `player_update`
  says after it changes.
- A player dropping and rejoining during the final round and during judging (only mid-question
  was tested).
- The host: what happens when the host drops and rejoins, and what a host this client was
  promoted to has to send to carry on.
- Chat, reactions and poppers, none seen live: whether Sporcle sends `chat_message` only to
  players with the chat open, whether it sends a player's own message back, the order and
  page size of `chat_load` and `chat_load_more`, whether `last_chat_message` comes for
  every message, what `createdAt` looks like as received, whether a `honk` sent with
  `sendTo` reaches only its target (and whether the server needs opcode 100 for it), what
  `list_u2u` carries and when, whether the server checks that a sender owns a paid sound,
  and what `honksMap` holds.
- A game longer than 20 minutes.
