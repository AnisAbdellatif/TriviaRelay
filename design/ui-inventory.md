# Trivia Relay — UI inventory for redesign

## The app

Trivia Relay is a third-party mobile client (Android APK + web build, Flutter) for playing
**Sporcle Party** trivia games with friends in the same room or remotely. Its point: a relay
server holds each player's seat, so a phone that drops, locks or closes the app comes back to
the game exactly where it was, never shown as disconnected.

Constraints for the design:
- **No Sporcle name, logo or branding** as the app's own. Text may say "works with Sporcle Party".
- Phone-first, portrait, one-handed. Must also work landscape, with large text, and with the
  keyboard open. Web build renders the same phone-width column centred on desktop.
- Dark UI. Main action of every screen is a big button pinned at the bottom.
- Toasts appear at the **top** (bottom is reserved for the main button).
- Content people wrote (questions, answers, names, chat, pack titles) can be **Arabic/Hebrew
  (RTL)**; the chrome is English LTR. Layout must survive mixed direction.
- Every animation needs a **reduced-motion** settled state.
- Minimum 48px touch targets; screen-reader labels on all icons.

## Current visual language (to keep, evolve or replace)

- Palette: deep navy ground `#111729` (deeper `#0A0E1A`, glow `#1B2442`); ink `#F1F0EA`
  (dim 66%, faint 50%); **Signal** yellow `#FFD23F` (primary accent); **Flare** pink
  `#FF4F7B` (second accent: final round, warnings, destructive); OK green `#3EE0A1`;
  alarm red `#FF3B30`; translucent panels and hairline borders.
- Fonts: **Bricolage Grotesque** (big titles), **Figtree** (headings/body), **DM Mono**
  (uppercase tracked eyebrows, tags, hints). Noto Naskh Arabic fallback.
- Motifs: concentric hairline **rings** spreading from a top corner of every screen (yellow;
  pink during the final round; around the winner on the final screen); the **mark** — a
  question mark drawn in two legs, yellow handing on to pink, with a seam; two short
  **accent bars** (yellow, pink) under big titles.
- Motion: pop/overshoot when something becomes true, colour easing, glow flash on last
  seconds, scores counting up, standings rows sliding to their new rank (FLIP).

---

## 1. Shared components (design system)

| Component | What it is |
|---|---|
| Background | Flat navy with corner rings; ring colour varies (yellow / pink / none). |
| Mark (logo) | Two-leg question mark. Sizes 30 (home header), ~120 (sign-in), 150 faded/broken (seat ended). |
| Accent bars | Two short bars under a hero title. |
| Page layout | Optional header row (back button + eyebrow title + actions), scrolling content, footer with 1–2 big buttons. Footer unpins and scrolls when space is short. |
| Big button | Full-width rounded. Kinds: **primary** (yellow), **pink**, **outline**. States: normal, disabled, busy (spinner in place of hint), **chosen** (filled + check, not pressable). Optional small mono hint on the right ("tap to undo", "host"), which wraps under the label when cramped. |
| Circle icon button | 44px round outlined icon (back, settings, copy, share, refresh, random, chat, more). |
| Tile | Tappable card/row with ink, hover, keyboard-focus ring. |
| Panel | Translucent rounded card. |
| Eyebrow | Small mono uppercase tracked label (section titles, top-bar label). |
| Tag | Tiny uppercase mono chip/text (YOU, HOST, READY, "wager 10", "42% get it"). |
| Avatar | Circle with initial on server-assigned hue; faded with light initial when player is away. |
| Waiting line | Pulsing dot + text ("Waiting for the host…", "Taking your seat"). |
| Text field | Dark filled field with hint; follows typed text's direction. |
| Choice chips | Single-select rows of chips (question count, seconds, audience, report reason, pack list). |
| Switch row | Title + dim subtitle + switch. |
| Toast | Top-of-screen short message, auto-dismiss, taps pass through. |
| Dialog | Title, body, two text actions (cancel / confirm; confirm may be destructive). |
| Bottom sheet | Draggable modal sheet (pack details, invite friends, menus). |
| Menu sheet | List of icon + title + subtitle rows (game menu, player menu, bypass menu). |
| Countdown | Seconds + progress bar. Normal → warning (last 10s or last third, red, easing tint) → final seconds (glow flash, pop per second) → "Time's up". Paused state: dim, "PAUSED · 12s". |
| Count-up number | Score that runs to its new value; "+10" style deltas. |
| Banners | Update banner, connection banner, notice banner, status banner (see §4). |

---

## 2. Screens outside a game

### 2.1 Sign in
- Large mark, title "Trivia Relay", accent bars, tagline ("Sporcle Party games that keep your place…").
- Eyebrow "Your Sporcle account"; Email field; Password field.
- Privacy note under fields (differs Android vs web: password goes to Sporcle only / passes through the relay, kept by neither).
- Disclaimer: "Trivia Relay is not made by Sporcle…".
- Footer: "Sign in with Sporcle" (busy: "Signing in…"). Errors as toast.

### 2.2 Home
- Header: small mark, eyebrow "Signed in as {handle}", Settings circle button.
- Update banner (Android only, when a newer APK exists): eyebrow "New version · 12 MB", "Trivia Relay 0.2.0 is out.", "Get it" button, close ×.
- Hero: "Trivia Relay", accent bars, tagline ("Drop out, come back: your seat, your answers…").
- Section "Join a game": game-code field (short alphanumeric code), "Join" button (busy "Joining…"), "Find a game" button.
- Footer: "Back to game {CODE}" (only when this phone holds a seat), "Host a game".
- Dialog when an invite link opened the app: "Join game {code}?" / "Back to game {code}?" — Not now / Join.

### 2.3 Find a game (game browser)
- Header: back, title "Find a game", Refresh button.
- Search field "Search by pack, host or code" with clear ×.
- **Party Poppers panel**: eyebrow "Party Poppers", "You have 3. A game with pictures costs 1 to join, except for its host.", "Claim free ones" button (toasts: "Claimed." / "None to claim yet: one comes back every 4 hours, up to 5.").
- Grouped lists with eyebrows: "Invited", "Friends' games", "Public games".
- **Game tile**: pack image, pack/game name, "Hosted by {name}", stage tag (Lobby / Question 8 / Final question / Playing), facts tag ("4 players · photos · 1 popper"), chevron.
- List footer states: loading; "Couldn't load games." + Try again; "No games match "x"."; empty ("No games to join right now…"); count.
- Auto-refresh every 15s (list must not jump under a finger).
- Confirm dialog: "Spend a Party Popper?" / "Join a game in progress?" — Not now / Join.

### 2.4 Host a game (setup)
- Header: back, eyebrow "Host a game".
- Title "Set up tonight's game".
- "Pack": empty state tile ("Choose a pack" / "Browse popular and fresh packs, or search" + chevron) or chosen pack tile with "Change".
- "Questions": chips (number options).
- "Seconds per question": chips ("15s", "30s"…).
- "Who can join": chips Invite only / Friends / Anyone; warning text for Anyone ("Listed publicly: strangers join within seconds.").
- "Host only": spectator switch ("Host as a spectator" — "Run the game without playing: you reveal and mark, the others answer.").
- Footer: "Choose a pack" (disabled-ish until chosen) → "Create the game" (busy "Creating…").

### 2.5 Pick a pack (pack browser)
- Header: back, title "Pick a pack", "A random pack" (dice) button.
- Search field "Search popular packs" with clear.
- List chips: Popular, Fresh, Bookmarked, Created, Friends, Purchased, Free.
- **Pack tile**: square rounded image (or quiet placeholder icon), name, subtitle/author line, facts tag ("169 questions · photos · 143K plays"), chosen check, "more" button (bookmark icon if bookmarked).
- Infinite scroll; footer states: loading more, end, "Couldn't load packs." + Try again, empty per list ("Packs you bookmark in Sporcle Party show up here.", etc.), no search match.

### 2.6 Pack details (bottom sheet)
- Pack image, name, facts tag, description.
- Main button "Choose this pack" (or "Vote for this pack"; absent when just viewing).
- "Bookmark" / "Bookmarked" button (toast "Bookmarked." / "Bookmark removed.").
- Switch "Tell me when someone hosts it" — "Sporcle Party's own app sends the notice, if you have it."
- Text button with flag "Report this pack".

### 2.7 Report a pack
- Header: back, eyebrow "Report a pack". Pack name.
- "What's wrong with it": chips Harassment or bullying / Offensive or inappropriate / Spam / Wildly inaccurate / Other.
- "Tell Sporcle more": multiline field with char limit.
- Footer "Send report" (busy "Sending…"); confirm dialog "Send this report?"; toast "Report sent. Thank you."

### 2.8 Settings
- Header: back, eyebrow "Settings".
- "Sporcle account": handle.
- "Name other players see": field (hint = handle), help text, "Save the name" (busy "Saving…"); toasts for saved / refused.
- Game feedback switches: "Sounds" (question opening, answer in, right/wrong, last seconds) and "Vibration" (Android).
- "In a game": current seat info (game code) when holding one.
- "This app": version ("Version 0.1.1" / "Development build").
- "Relay (debug builds only)": URL field.
- "Host tools": bypass code field "One-time bypass code" + Activate; when active: check + "Bypass active" + Deactivate; inline error text.
- Disclaimer.
- Footer "Sign out" (busy "Signing out…"); dialog when in a game: "Sign out?" — Stay / Leave and sign out.

---

## 3. The game screen

One screen, switches view by phase. Shell around every phase:

### 3.1 Game shell
- **Top bar**: Home/back button ("Home. Your seat is held"), one-line eyebrow label ("Lobby", "Question 3 of 10", "Final round", "Final scores"; short forms "Q3 of 10", "Final", "Scores" when narrow; pink during final), game code tag (dropped first when narrow), **Chat button with unread badge**, **Leave** text button, **more (⋮)** menu (host items, or Leave when no room).
- Banners stacked under the top bar (see §4).
- Background rings: yellow normally, pink through the final round, none on final scores.
- Floating **bypass button** (admin icon) when bypass is active.
- Full-screen waiting states: "Taking your seat", "Joining again", "Leaving the game…".
- Game menu sheet: "Back to the lobby — End this game for everyone" (host, mid-game), "Leave the game" (pink).
- Dialogs: "Leave the game?" (Stay / Leave), "Return everyone to the lobby?" (Cancel / Go to lobby).

### 3.2 Lobby
- "Game code" eyebrow + big code + Copy button + Share-invite-link button; "Invite friends" button.
- **Pack panel**: image, name, description, facts tag; host: "Change the pack".
- **Host options** (host only): question count chips, seconds chips, spectator switch.
- **Pack votes panel**: eyebrow "Pack votes · 2"; help ("Vote for up to 3 packs you'd rather play" / host: "Tap a pack to play it instead."); vote tiles (image, name, vote count, tags "your vote", "playing now", vote icon); "Vote for a pack" button.
- "Players · 5": player rows with ready check / not-ready circle.
- Footer: "I'm ready" (primary) ⇄ "You're ready" (outline, hint "tap to undo"); host also "Start the game". Dialog "Not everyone is ready — Start the game anyway?".

### 3.3 Start countdown
- Full-view "We're starting in" / "Final question in" eyebrow + huge number popping each second (synchronised on all phones).

### 3.4 Question
- Pinned top: **countdown** with progress bar.
- Eyebrow "Question 3" / "Final · hard"; difficulty tag "42% get it".
- Question text (can be RTL); optional **big glyph** (flag, emoji, word drawn large); optional **question image** on a light mat (fixed-height box; loading spinner; "The picture didn't load." with broken-image icon).
- **Answer field** "Your answer" (closes at "Time's up").
- **Wager picker**: eyebrow "Wager · each once a game", chips for remaining wagers (used ones gone).
- After locking: panel with lock icon + your answer + "wager 10" tag (green).
- **Answered list**: "3 of 5 answered", player rows with check (answered) / hourglass (thinking); once you've answered, others' guesses appear in the rows.
- Spectating host: panel with eye icon "You're hosting as a spectator: the players answer…".
- Footer: "Lock it in" / "Locking…" / "Time's up"; host: "Reveal the answer" + note "Reveal opens once everyone has answered, or 5 seconds…".
- "Next question" waiting state between questions.

### 3.5 Reveal
- Question text.
- "The answer" panel (big).
- Guesses section, eyebrow: host "Switch on the right guesses" / "Marked" / others "The host is marking the guesses".
- **Guess rows**: avatar, name, the guess on its own line (dash if empty), host has a right/wrong **switch** per row; others see ✓/✗; faint wash behind a guess the host re-marked (differs from Sporcle's exact match).
- **Question feedback**: thumbs up / down, "Report" (flag) → dialog "Report the question — What's wrong with it?" radio reasons, Cancel / Report.
- "Standings" with score deltas counting up and rows sliding to new rank.
- Footer (host): "Confirm the marks", then "Next question" / "On to the final round" / "Show the final scores". Dialog "Skip scoring this question?" — Go back / Skip scoring.

### 3.6 Final round — vote
- Title "Final round", explainer ("One last question, and you wager 0, 10 or 20 on it…").
- Three big buttons Easy / Medium / Hard (chosen one pink with check).
- "Standings".
- Host footer: "Move on without the rest" (outline).

### 3.7 Final round — wager
- Title "Your wager" / "The wagers" (spectator); "The final question is hard. Right adds your wager, wrong takes it away."
- **Three big wager tiles** 0 / 10 / 20 (hairline, turns pink when chosen).
- "Standings" (or others' wager status).
- Host footer: "Ask the final question" (pink).

### 3.8 Final scores
- Eyebrow "Final scores", "Game over" / winner headline, accent bars.
- **Winner(s)**: large avatar(s) ringed in yellow with rings spreading behind; ties show several.
- Full standings.
- Footer: "Play again" (host) / "Play again" → "Waiting for the host" (players).
- "Left behind" state: next game started without you → offer to join it by its code.

### 3.9 Seat ended / displaced
- Faded broken mark (150), big title, dim explanation, buttons.
- Reasons: "You left", "Your seat was let go" (away too long), "You were removed" (can rejoin), "You were kicked", "Your seat moved to another device", "The relay restarted", "That game is over for you".
- Buttons: "Join again" (busy "Joining…") where allowed, "Home".
- Displaced: "Open on other devices" — "Use it here" / "Home".

---

## 4. Overlays, banners, sheets inside the game

- **Connection banner**: rounded pink strip, blinking dot, "Reconnecting…" / "Disconnected" + "Reconnect".
- **Status banner** (relay's own link to the game): "Joining the game…" waiting line; or "Lost the game — The relay can't get back in by itself." + "Rejoin" / "Rejoining…".
- **Notice banner** (dismissible ×, auto-expires): "Back to the lobby — The host returned everyone to the lobby.", "You're the host now — The host handed you the game." / "…The host left the game, so it's yours to run.", "Popper spent — Joining this game with pictures used 1 of your Party Poppers.".
- **Reaction toast**: megaphone icon + "Hosta honked at you", under the top bar, separate from normal toasts.
- **Toasts**: "Code copied.", "You honked at {name}", "Invited.", relay refusals.
- **Chat screen** (full screen over the game): back "Back to the game", eyebrow "Chat"; messages newest at bottom; "Earlier messages" button / "Loading earlier messages"; empty "No messages yet. Say hello!"; **bubbles** (own vs others: avatar, name, text; picture messages); **system messages** (from the game, centred); **typing line** ("Ana, Bo and 2 more are typing"); field "Say something" + Send. Closes itself when a question opens.
- **Player menu** (sheet, tap any other player row): header avatar + name + detail; "Honk — A honk plays on their phone" (or "Wait a moment" cooldown); host: "Make host — Hand them the game", "Remove — They can join again", "Kick — They can't come back" (pink). Each host action confirms ("Make {name} the host?", "Remove {name}?", "Kick {name}?").
- **Invite friends sheet** (draggable): title "Invite friends", "Sporcle tells them, in Sporcle Party, that you are in this game."; "Invite all" / "All invited"; friend rows (avatar, name, status) with "Invite" / "Invited"; "More friends"; error + Try again; empty state.
- **Bypass sheet** (admin): "Bypass actions" — "Become host — Take over the game", "Kick a player — Pick a player to remove" → "Kick who?" list (Connected / Away) → "Kick {name}?".

---

## 5. Player row (used everywhere)

Avatar (hue, faded when away) · name (RTL-aware) · notes tag (YOU · HOST · READY · AWAY · SPECTATING) · optional guess line · trailing slot (score with count-up, ✓/✗, switch, ready icon, hourglass, rank) · optional tap → player menu · optional re-marked wash.

---

## 6. Feedback & game moments (for motion/sound design)

Game start · question opens · your answer locked in · right / wrong at reveal · tick each of the last seconds unanswered · reaction received/sent (honk) · overtaking in standings · winner reveal. Sounds and vibration are user-toggleable; all motion has a reduced-motion version.

---

## Deliverables wanted from the redesign

1. Updated tokens: palette, type scale, radii, spacing, elevation/borders, motion curves.
2. Component specs for §1 and §5 with all states.
3. Mockups of every screen/phase in §2–§3 (portrait phone), including empty, loading, error,
   host vs player vs spectating-host variants, and the final-round (pink) treatment.
4. Overlays in §4.
5. One landscape/large-text example and one RTL-content example (Arabic question + answers).
