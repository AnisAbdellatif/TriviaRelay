#!/usr/bin/env bash
#
# Everything CI runs, runnable on a developer machine.
#
#   scripts/ci.sh              # server + app + image (what a pull request runs)
#   scripts/ci.sh server       # Elixir: compile, format, credo, test
#   scripts/ci.sh app          # Flutter: format, analyze, test, web build
#   scripts/ci.sh image        # build the production Docker image
#   scripts/ci.sh apk          # unsigned release APK (Gradle; never sees the key)
#   scripts/ci.sh sign         # sign that APK + the release manifest (no Gradle, no pub)
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
fail()  { printf '%sFAILED%s %s\n' "$RED" "$OFF" "$1" >&2; exit 1; }
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
  web_build

  cd "$ROOT"
}

# The web app, as the image ships it. CanvasKit comes out of the build, not from
# gstatic.com: the relay's Content-Security-Policy allows scripts from itself only,
# and a copy on a CDN is code the page runs that nobody here can pin.
web_build() {
  flutter build web --release --no-web-resources-cdn
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
# find out it is out of date (app/lib/core/update/). Two steps, so the signing key is
# never in the same place as the code a build downloads and runs:
#
#   apk   builds the APK unsigned. Gradle and pub run plugins nobody here wrote, so
#         Gradle is given nothing of the key: no signing config, no password in the
#         environment (the variables are cleared for the build even if set). In CI
#         there is no keystore on the machine at all; locally, keep yours outside
#         app/ if that matters to you (ANDROID_KEYSTORE_PATH).
#   sign  signs that APK with the Android build-tools' zipalign and apksigner, checks
#         the signature, and writes the manifest from the signed file. No Gradle, no
#         pub. In CI it is a separate job on a fresh machine, the only one that is given
#         the key (.github/workflows/ci.yml).
#
# Not part of `all`: they need an Android SDK and the signing key, neither of which a
# check should demand. They are the one supported way to build an APK for somebody
# else, and `sign` refuses to produce an APK nobody can update from.

# Reads the release's version and tag and checks them, for both steps.
release_version() {
  local version code
  version="$(pubspec_version)"
  code="$(pubspec_version_code)"
  [ -n "$version" ] && [ -n "$code" ] || fail "could not read 'version:' from app/pubspec.yaml"
  REL_VERSION="$version"
  REL_CODE="$code"

  # A release built against the wrong tag would publish a build whose own idea of its
  # version disagrees with where it is published. Checked only when a tag is named, so
  # a local build to try the thing out still works.
  REL_TAG="${RELEASE_TAG:-v$version}"
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
}

RELEASE_DIR="$ROOT/app/build/release"
unsigned_apk() { printf '%s/trivia-relay-%s-unsigned.apk' "$RELEASE_DIR" "$REL_VERSION"; }

apk() {
  step "Android APK (unsigned)"

  local server repo apk_path
  release_version

  # Android has no origin to be served from, so the relay it talks to is baked in
  # (app/lib/core/providers/config_providers.dart). Without this the build would
  # have no relay at all. It carries the player's Sporcle token and the seat's, so
  # it is https: a release is never built to talk to a relay in the clear.
  server="${SERVER_URL:-}"
  if [ -z "$server" ] && [ -n "${PUBLIC_HOST:-}" ]; then
    server="https://$PUBLIC_HOST"
  fi
  [ -n "$server" ] || fail "set SERVER_URL (or PUBLIC_HOST) — a build with no relay in it is useless"
  printf '%s' "$server" | grep -qE '^https://[A-Za-z0-9.-]+(:[0-9]+)?/?$' ||
    fail "SERVER_URL '$server' is not https://<host>[:port] — a release only talks to its relay over TLS"

  repo="$(release_repo)" ||
    fail "could not work out the GitHub repository from 'origin' — set GITHUB_REPOSITORY"

  cd "$ROOT/app"
  # `env -u`: whatever signing variables this shell has, the build does not get them.
  local -a no_key=(env -u ANDROID_KEYSTORE_BASE64 -u ANDROID_KEYSTORE_PATH
    -u ANDROID_KEYSTORE_PASSWORD -u ANDROID_KEY_ALIAS -u ANDROID_KEY_PASSWORD)
  "${no_key[@]}" flutter pub get
  # One universal APK rather than one per ABI: it is downloaded by hand from a link.
  # x86_64 is left out: only emulators run it, and they get theirs from `flutter run`.
  "${no_key[@]}" TRIVIA_RELAY_RELEASE_BUILD=1 flutter build apk --release \
    --target-platform android-arm,android-arm64 \
    --dart-define="SERVER_URL=$server" \
    --dart-define="APP_VERSION=$REL_VERSION" \
    --dart-define="APP_VERSION_CODE=$REL_CODE" \
    --dart-define="UPDATE_MANIFEST_URL=https://github.com/$repo/releases/latest/download/android.json"

  # Gradle's own output: the Flutter tool copies it to flutter-apk/ under the name of a
  # signed one, which it is not.
  apk_path="build/app/outputs/apk/release/app-release-unsigned.apk"
  [ -f "$apk_path" ] || fail "$apk_path was not produced (is the release build still unsigned? app/android/app/build.gradle.kts)"

  rm -rf "$RELEASE_DIR"
  mkdir -p "$RELEASE_DIR"
  cp "$apk_path" "$(unsigned_apk)"

  cd "$ROOT"
  ok "$(unsigned_apk)  (unsigned; next: scripts/ci.sh sign)"
}

# The newest Android build-tools with apksigner in them.
build_tools() {
  local sdk="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}"
  if [ -z "$sdk" ] && [ -f "$ROOT/app/android/local.properties" ]; then
    sdk="$(sed -n 's/^sdk\.dir=//p' "$ROOT/app/android/local.properties" | head -1)"
  fi
  [ -n "$sdk" ] && [ -d "$sdk/build-tools" ] ||
    fail "no Android SDK: set ANDROID_HOME (it needs build-tools, for zipalign and apksigner)"
  local dir
  dir="$(find "$sdk/build-tools" -mindepth 2 -maxdepth 2 -name apksigner -printf '%h\n' 2>/dev/null |
    sort -V | tail -1)"
  [ -n "$dir" ] && [ -x "$dir/zipalign" ] ||
    fail "no build-tools with zipalign and apksigner under $sdk/build-tools"
  printf '%s' "$dir"
}

# One value from app/android/key.properties, or nothing.
key_property() {
  [ -f "$ROOT/app/android/key.properties" ] || return 0
  sed -n "s/^[[:space:]]*$1[[:space:]]*=[[:space:]]*//p" "$ROOT/app/android/key.properties" |
    head -1 | tr -d '\r'
}

sign() {
  step "Android APK (sign)"

  have python3 || fail "python3 not found (it writes the release manifest)"

  local tools repo unsigned aligned file signed keystore alias size digest notes
  release_version
  tools="$(build_tools)"
  repo="$(release_repo)" ||
    fail "could not work out the GitHub repository from 'origin' — set GITHUB_REPOSITORY"

  unsigned="$(unsigned_apk)"
  [ -f "$unsigned" ] || fail "$unsigned is missing — run 'scripts/ci.sh apk' first"

  # The key: in CI the keystore arrives base64-encoded in the environment and is
  # written out only for as long as this function runs; locally it is a file named by
  # ANDROID_KEYSTORE_PATH or app/android/key.properties (storeFile, relative to
  # app/android/app as Gradle had it).
  #
  # Every release has to be signed with the same key or Android refuses to install one
  # over another, and every existing user is stuck.
  local keydir
  keydir="$(mktemp -d)"
  # shellcheck disable=SC2064 # the path is fixed now, on purpose
  trap "rm -rf '$keydir'" EXIT
  if [ -n "${ANDROID_KEYSTORE_BASE64:-}" ]; then
    keystore="$keydir/release.jks"
    (umask 077 && printf '%s' "$ANDROID_KEYSTORE_BASE64" | base64 --decode > "$keystore") ||
      fail "ANDROID_KEYSTORE_BASE64 is not valid base64"
  else
    keystore="${ANDROID_KEYSTORE_PATH:-$(key_property storeFile)}"
    case "$keystore" in
      "" ) ;;
      /*) ;;
      *) [ -n "${ANDROID_KEYSTORE_PATH:-}" ] || keystore="$ROOT/app/android/app/$keystore" ;;
    esac
  fi
  [ -n "$keystore" ] && [ -f "$keystore" ] ||
    fail "no signing key: set ANDROID_KEYSTORE_PATH (and the passwords) or write app/android/key.properties. See README.md."

  # Passwords reach apksigner through its environment (`env:`), never its command
  # line, which any process on the machine can read.
  TR_KS_PASS="${ANDROID_KEYSTORE_PASSWORD:-$(key_property storePassword)}"
  TR_KEY_PASS="${ANDROID_KEY_PASSWORD:-$(key_property keyPassword)}"
  alias="${ANDROID_KEY_ALIAS:-$(key_property keyAlias)}"
  [ -n "$TR_KS_PASS" ] || fail "no keystore password: set ANDROID_KEYSTORE_PASSWORD or storePassword in key.properties"
  [ -n "$alias" ] || fail "no key alias: set ANDROID_KEY_ALIAS or keyAlias in key.properties"
  # keytool has written PKCS12 since Java 9, which has one password for the store and
  # the key, so the key's falls back to the store's rather than being required.
  [ -n "$TR_KEY_PASS" ] || TR_KEY_PASS="$TR_KS_PASS"
  export TR_KS_PASS TR_KEY_PASS

  file="trivia-relay-$REL_VERSION.apk"
  signed="$RELEASE_DIR/$file"
  aligned="$keydir/aligned.apk"
  # A failed run must not leave an earlier run's APK and manifest looking current.
  rm -f "$signed" "$signed.idsig" "$RELEASE_DIR/android.json"

  # Aligned before signing (signing after is what keeps the alignment valid), with
  # native libraries on 16 KB pages, which Android 15+ devices with 16 KB pages need.
  "$tools/zipalign" -f -P 16 4 "$unsigned" "$aligned"
  "$tools/apksigner" sign \
    --ks "$keystore" --ks-pass env:TR_KS_PASS \
    --ks-key-alias "$alias" --key-pass env:TR_KEY_PASS \
    --out "$signed" "$aligned"
  unset TR_KS_PASS TR_KEY_PASS
  rm -rf "$keydir"
  trap - EXIT

  "$tools/zipalign" -c -P 16 4 "$signed" || fail "$signed is not aligned"
  "$tools/apksigner" verify --verbose --print-certs "$signed" ||
    fail "$signed does not verify"
  rm -f "$unsigned" "$signed.idsig"

  size="$(wc -c < "$signed" | tr -d " ")"
  digest="$(sha256_of "$signed")"
  notes="${RELEASE_NOTES:-$(git -C "$ROOT" tag -l --format="%(contents:subject)" "$REL_TAG" 2>/dev/null || true)}"

  # python3 rather than a heredoc, so a tag message with a quote in it cannot produce
  # a manifest the app refuses to parse.
  VERSION="$REL_VERSION" CODE="$REL_CODE" URL="https://github.com/$repo/releases/download/$REL_TAG/$file" \
  SIZE="$size" DIGEST="$digest" NOTES="$notes" python3 - "$RELEASE_DIR/android.json" <<'PYTHON'
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

  ok "app/build/release/$file  ($((size / 1048576)) MB, $REL_TAG)"
  cat "$RELEASE_DIR/android.json"
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
    # Not part of `all`: a release needs an Android SDK and the signing key. `sign`
    # needs no Flutter: it is the build-tools and the key, and nothing else.
    apk)      versions app; apk ;;
    sign)     sign ;;
    all)      versions; server; app; image ;;
    *)        fail "unknown target '$target' (use: all, server, app, image, apk, sign, versions)" ;;
  esac

  if [ "$warned" = 1 ]; then
    printf '\n%sPassed, with warnings above.%s\n' "$YELLOW" "$OFF"
  else
    printf '\n%sPassed.%s\n' "$GREEN" "$OFF"
  fi
}

main "$@"
