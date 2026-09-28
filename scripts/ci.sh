#!/usr/bin/env bash
#
# Everything CI runs, runnable on a developer machine.
#
#   scripts/ci.sh              # server + app + image (what a pull request runs)
#   scripts/ci.sh server       # Elixir: compile, format, credo, test
#   scripts/ci.sh app          # Flutter: format, analyze, test, web build
#   scripts/ci.sh image        # build the production Docker image
#   scripts/ci.sh apk          # signed Android APK + the release manifest
#   scripts/ci.sh versions     # just the toolchain check (or: versions server|app)
#
# This file is the definition of those checks: .github/workflows/ci.yml calls it
# rather than repeating the steps, so what runs here is what runs there.
#
# Deploying is deliberately absent. A person deploys main with deploy-kit
# (`.kamal/kit/bin/kit deploy`, deploy/README.md), which checks that these passed in CI.

set -euo pipefail

# The toolchain CI pins. Kept in step with server/mix.exs, app/pubspec.yaml and
# deploy/Dockerfile; .github/workflows/ci.yml reads these, so this is the only place
# they are written for CI.
OTP_VERSION="29.0.6"
ELIXIR_VERSION="1.20.4"
FLUTTER_VERSION="3.47.4"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# Colour only when a terminal is watching; CI logs stay plain.
if [ -t 1 ]; then
  BOLD=$'\033[1m'; RED=$'\033[31m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'; OFF=$'\033[0m'
else
  BOLD=""; RED=""; GREEN=""; YELLOW=""; OFF=""
fi

warned=0

step()  { printf '\n%s==> %s%s\n' "$BOLD" "$1" "$OFF"; }
warn()  { printf '%sWARNING%s %s\n' "$YELLOW" "$OFF" "$1"; warned=1; }
fail()  { printf '%sFAILED%s %s\n' "$RED" "$OFF" "$1"; exit 1; }
ok()    { printf '%s%s%s\n' "$GREEN" "$1" "$OFF"; }

have() { command -v "$1" >/dev/null 2>&1; }

# Compares an installed version against the pinned one. A mismatch is a warning, not
# an error: the exact combination CI uses is not always installable locally, and a
# developer is better served by running the checks and knowing the caveat than by
# being refused. CI itself installs the pins, so it never warns.
check_version() {
  local name="$1" want="$2" got="$3"
  if [ -z "$got" ]; then
    warn "$name version could not be determined (wanted $want)"
  elif [ "$got" != "$want" ]; then
    warn "$name $got locally, CI uses $want — results here may not match CI"
  else
    printf '  %-8s %s\n' "$name" "$got"
  fi
}

# Only the toolchains the target needs: CI installs Elixir on the server job and
# Flutter on the app job, and nothing else.
versions() {
  local want="${1:-all}"
  local elixir_got="" otp_got="" flutter_got=""

  step "Toolchain"

  if [ "$want" = all ] || [ "$want" = server ]; then
    have elixir || fail "elixir not found. See README.md for the toolchain."
    elixir_got="$(elixir --version 2>/dev/null | sed -n 's/^Elixir \([0-9.]*\).*/\1/p')"
    otp_got="$(erl -noshell -eval \
      'io:format("~s", [erlang:system_info(otp_release)]), halt().' 2>/dev/null || true)"
    check_version "Elixir" "$ELIXIR_VERSION" "$elixir_got"
    # `erlang:system_info(otp_release)` gives the major only ("29"), which is the
    # part that decides whether a build is compatible.
    check_version "OTP" "${OTP_VERSION%%.*}" "$otp_got"
  fi

  if [ "$want" = all ] || [ "$want" = app ]; then
    have flutter || fail "flutter not found. See README.md for the toolchain."
    flutter_got="$(flutter --version 2>/dev/null | sed -n 's/^Flutter \([0-9.]*\).*/\1/p')"
    check_version "Flutter" "$FLUTTER_VERSION" "$flutter_got"
  fi
}

# AGENTS.md §4's list.
server() {
  step "Server (Elixir)"
  cd "$ROOT/server"

  mix deps.get
  mix compile --warnings-as-errors
  mix format --check-formatted
  mix deps.unlock --check-unused
  mix credo --strict
  mix test

  cd "$ROOT"
}

# AGENTS.md §5's list, and the web build the image ships.
app() {
  step "App (Flutter)"
  cd "$ROOT/app"

  flutter pub get
  dart format --set-exit-if-changed lib test
  flutter analyze
  flutter test
  flutter build web --release

  cd "$ROOT"
}

# The version pubspec.yaml declares, as the two halves Android wants: the name people
# read ("0.1.0") and the integer it orders installs by ("1").
pubspec_version() { sed -n 's/^version: *\([^+]*\)+.*$/\1/p' "$ROOT/app/pubspec.yaml" | head -1; }
pubspec_version_code() { sed -n 's/^version: *[^+]*+\(.*\)$/\1/p' "$ROOT/app/pubspec.yaml" | head -1; }

# The build number the last release published, or nothing if there wasn't one. Read
# out of that tag's own pubspec rather than a file here, because the question is what
# shipped, not what this checkout happens to say.
previous_release_code() {
  local tag
  for tag in $(git -C "$ROOT" tag --list 'v*' --sort=-v:refname 2>/dev/null); do
    # An `if`, not `[ ... ] && continue`: under `set -e` a bare test that comes out
    # false is a failing command and takes the whole run with it.
    if [ "$tag" != "$REL_TAG" ]; then
      git -C "$ROOT" show "${tag}:app/pubspec.yaml" 2>/dev/null |
        sed -n 's/^version: *[^+]*+\(.*\)$/\1/p' | head -1
      return
    fi
  done
}

# `<major>.<minor>.<patch>+<build>`. The build number is the integer Android orders
# installs by: it has to go up on every release and can never be reused, or Android
# refuses to install the update and every existing user is stuck.
check_release_version() {
  printf '%s' "$REL_VERSION" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$' ||
    fail "app/pubspec.yaml version '$REL_VERSION' is not <major>.<minor>.<patch>"

  printf '%s' "$REL_CODE" | grep -qE '^[1-9][0-9]*$' ||
    fail "app/pubspec.yaml build number '+$REL_CODE' is not a positive integer"

  local previous
  previous="$(previous_release_code)"
  # No previous release to compare against is the first one, not a pass.
  [ -n "$previous" ] || return 0

  if [ "$REL_CODE" -le "$previous" ]; then
    fail "build number +$REL_CODE is not above the last release's +$previous — Android will refuse to install over it"
  fi
}

# owner/repo of the GitHub repository releases are published to. CI knows it; locally
# it comes from the remote, so a fork releases to itself rather than pointing its
# users at somebody else's APK.
release_repo() {
  if [ -n "${GITHUB_REPOSITORY:-}" ]; then
    printf '%s' "$GITHUB_REPOSITORY"
    return
  fi
  local url
  url="$(git -C "$ROOT" remote get-url origin 2>/dev/null || true)"
  url="${url%.git}"
  case "$url" in
    *github.com[:/]*) printf '%s' "${url#*github.com}" | sed 's#^[:/]##' ;;
    *) return 1 ;;
  esac
}

sha256_of() {
  if have sha256sum; then
    sha256sum "$1" | cut -d" " -f1
  else
    shasum -a 256 "$1" | cut -d" " -f1
  fi
}

# The release APK people install by hand, and the manifest the installed app reads to
# find out it is out of date (app/lib/core/update/).
#
# Not part of `all`: it needs an Android SDK and the signing key, neither of which a
# check should demand. It is the one supported way to build an APK for somebody else,
# and unlike Gradle, which falls back to the debug key, it refuses to produce an APK
# nobody can update from.
apk() {
  step "Android APK"

  have python3 || fail "python3 not found (it writes the release manifest)"

  local version code tag server repo out apk_path file notes size digest
  version="$(pubspec_version)"
  code="$(pubspec_version_code)"
  [ -n "$version" ] && [ -n "$code" ] || fail "could not read 'version:' from app/pubspec.yaml"
  REL_VERSION="$version"
  REL_CODE="$code"

  # A release built against the wrong tag would publish a build whose own idea of its
  # version disagrees with where it is published. Checked only when a tag is named, so
  # a local build to try the thing out still works.
  tag="${RELEASE_TAG:-v$version}"
  REL_TAG="$tag"
  if [ -n "${RELEASE_TAG:-}" ] && [ "$RELEASE_TAG" != "v$version" ]; then
    fail "tag $RELEASE_TAG does not match app/pubspec.yaml ($version) — bump the pubspec, or tag v$version"
  fi

  check_release_version

  # A release is what every installed app is offered as an update, so it has to be
  # something that went through review: a tag on a commit that never reached main
  # would ship whatever the tagger pushed. Checked only when a tag is named.
  if [ -n "${RELEASE_TAG:-}" ]; then
    git -C "$ROOT" rev-parse --verify --quiet origin/main >/dev/null ||
      fail "origin/main is not fetched, so the tag cannot be checked against it"
    git -C "$ROOT" merge-base --is-ancestor HEAD origin/main ||
      fail "$RELEASE_TAG is on a commit that is not on main — tag what was merged, not a branch"
  fi

  # Android has no origin to be served from, so the relay it talks to is baked in
  # (app/lib/core/providers/config_providers.dart). Without this the build would
  # quietly point at localhost and never reach a game.
  server="${SERVER_URL:-}"
  if [ -z "$server" ] && [ -n "${PUBLIC_HOST:-}" ]; then
    server="https://$PUBLIC_HOST"
  fi
  [ -n "$server" ] || fail "set SERVER_URL (or PUBLIC_HOST) — a build with no relay in it is useless"

  if [ -z "${ANDROID_KEYSTORE_PATH:-}" ] && [ ! -f "$ROOT/app/android/key.properties" ]; then
    fail "no signing key: set ANDROID_KEYSTORE_PATH (and the passwords) or write app/android/key.properties. See README.md."
  fi

  repo="$(release_repo)" ||
    fail "could not work out the GitHub repository from 'origin' — set GITHUB_REPOSITORY"

  cd "$ROOT/app"
  flutter pub get
  # One universal APK rather than one per ABI: it is downloaded by hand from a link.
  # x86_64 is left out: only emulators run it, and they get theirs from `flutter run`.
  TRIVIA_RELAY_RELEASE_BUILD=1 flutter build apk --release \
    --target-platform android-arm,android-arm64 \
    --dart-define="SERVER_URL=$server" \
    --dart-define="APP_VERSION=$version" \
    --dart-define="APP_VERSION_CODE=$code" \
    --dart-define="UPDATE_MANIFEST_URL=https://github.com/$repo/releases/latest/download/android.json"

  apk_path="build/app/outputs/flutter-apk/app-release.apk"
  [ -f "$apk_path" ] || fail "$apk_path was not produced"

  out="$ROOT/app/build/release"
  file="trivia-relay-$version.apk"
  rm -rf "$out"
  mkdir -p "$out"
  cp "$apk_path" "$out/$file"

  size="$(wc -c < "$out/$file" | tr -d " ")"
  digest="$(sha256_of "$out/$file")"
  notes="${RELEASE_NOTES:-$(git -C "$ROOT" tag -l --format="%(contents:subject)" "$tag" 2>/dev/null || true)}"

  # python3 rather than a heredoc, so a tag message with a quote in it cannot produce
  # a manifest the app refuses to parse.
  VERSION="$version" CODE="$code" URL="https://github.com/$repo/releases/download/$tag/$file" \
  SIZE="$size" DIGEST="$digest" NOTES="$notes" python3 - "$out/android.json" <<'PYTHON'
import json, os, sys

manifest = {
    "version": os.environ["VERSION"],
    "version_code": int(os.environ["CODE"]),
    "url": os.environ["URL"],
    "size": int(os.environ["SIZE"]),
    "sha256": os.environ["DIGEST"],
}
notes = os.environ.get("NOTES", "").strip()
if notes:
    manifest["notes"] = notes

with open(sys.argv[1], "w", encoding="utf-8") as out:
    json.dump(manifest, out, ensure_ascii=False, indent=2)
    out.write("\n")
PYTHON

  cd "$ROOT"
  ok "app/build/release/$file  ($((size / 1048576)) MB, $tag)"
  cat "$out/android.json"
}

image() {
  step "Image (Docker)"

  have docker || fail "docker not found"

  # The image copies app/build/web in, so it has to exist first. CI guarantees this
  # by ordering the jobs; locally it is easy to forget.
  if [ ! -f "$ROOT/app/build/web/index.html" ]; then
    fail "app/build/web is missing — run 'scripts/ci.sh app' first"
  fi

  docker build --file deploy/Dockerfile --tag trivia-relay:local "$ROOT"
  ok "built trivia-relay:local"
}

main() {
  local target="${1:-all}"

  case "$target" in
    versions) versions "${2:-all}" ;;
    server)   versions server; server ;;
    app)      versions app; app ;;
    image)    image ;;
    # Not part of `all`: a release needs an Android SDK and the signing key.
    apk)      versions app; apk ;;
    all)      versions; server; app; image ;;
    *)        fail "unknown target '$target' (use: all, server, app, image, apk, versions)" ;;
  esac

  if [ "$warned" = 1 ]; then
    printf '\n%sPassed, with warnings above.%s\n' "$YELLOW" "$OFF"
  else
    printf '\n%sPassed.%s\n' "$GREEN" "$OFF"
  fi
}

main "$@"
