# shellcheck shell=bash
# Core helpers shared by every deploy-kit command and step: logging, lists,
# configuration loading, timeouts and waiting. Sourced, never run.
#
# Portable to bash 3.2 (macOS's /bin/bash): no associative arrays, no
# ${var,,}, no mapfile. Deploys are often run from a Mac.

KIT_HOME=${KIT_HOME:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}
export KIT_HOME

# shellcheck source=yaml.sh
. "$KIT_HOME/lib/yaml.sh"

# ---------------------------------------------------------------- logging

_kit_color() {
  if [ -t 2 ] && [ -z "${NO_COLOR:-}" ]; then printf '\033[%sm' "$1"; fi
}

kit_log() { printf '%skit%s %s\n' "$(_kit_color 2)" "$(_kit_color 0)" "$*" >&2; }
kit_info() { kit_log "$*"; }
kit_ok() { printf '%skit ✓%s %s\n' "$(_kit_color 32)" "$(_kit_color 0)" "$*" >&2; }
kit_warn() { printf '%skit !%s %s\n' "$(_kit_color 33)" "$(_kit_color 0)" "$*" >&2; }
kit_error() { printf '%skit ✗%s %s\n' "$(_kit_color 31)" "$(_kit_color 0)" "$*" >&2; }
kit_die() {
  kit_error "$*"
  exit 1
}

# kit_gate_die MESSAGE: a gate refusing, and how to go past it once, on
# purpose (the step's name comes from the hook running it: KIT_STEP).
kit_gate_die() {
  local hint=""
  [ -z "${KIT_STEP:-}" ] ||
    hint=" To go past it once, on purpose: KIT_SKIP=$(basename "$KIT_STEP") KIT_SKIP_REASON=\"why\" before the command (warned and notified)"
  kit_die "$1.$hint"
}

# ------------------------------------------------------------------ values

# These run in loops, in every hook: plain bash, no processes started.

# kit_is_true VALUE: 1, true, yes, on (any case).
kit_is_true() {
  case ${1:-} in
    1 | [Tt][Rr][Uu][Ee] | [Yy][Ee][Ss] | [Oo][Nn]) return 0 ;;
    *) return 1 ;;
  esac
}

# kit_upper TEXT: upper case, with - and . turned into _ (for variable names).
kit_upper() { printf '%s' "$1" | tr '[:lower:].-' '[:upper:]__'; }

# kit_words LIST: one item per line; items separated by spaces, commas or
# newlines. Empty items are dropped; nothing is globbed.
kit_words() {
  local word IFS=$' \t\n,' glob=true
  case $- in *f*) glob=false ;; esac
  set -f
  # shellcheck disable=SC2086 # split on IFS, globbing off
  for word in ${1:-}; do
    [ -z "$word" ] || printf '%s\n' "$word"
  done
  [ "$glob" = false ] || set +f
}

# kit_in_list ITEM LIST: whether ITEM is one of LIST's words.
kit_in_list() {
  local item=${1:-} sep=$',\t\n'
  [ -n "$item" ] || return 1
  case " ${2//[$sep]/ } " in
    *" $item "*) return 0 ;;
    *) return 1 ;;
  esac
}

# kit_is_name VALUE: a valid variable name (safe inside a regex).
kit_is_name() { [[ ${1:-} =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; }

# kit_is_int VALUE: a non-negative integer.
kit_is_int() { case "${1:-}" in '' | *[!0-9]*) return 1 ;; *) return 0 ;; esac; }

# ------------------------------------------------------------ configuration
#
# Configuration is shell variables named KIT_*, read from, in order (later
# wins):
#
#   $KIT_HOME/lib/defaults.sh           the kit's defaults
#   .kamal/kit.env                      the project's settings (committed)
#   .kamal/kit.<destination>.env        per destination (committed)
#   .kamal/kit.local.env                personal overrides (git-ignored)
#   the environment                     KIT_*=… kit deploy …, or any variable
#                                       the files set (KT_HOST=… …)
#
# A value can also be given per destination inside any of these with a
# suffix: KIT_DEPLOY_BRANCH_STAGING=dev beats KIT_DEPLOY_BRANCH for
# `-d staging` (see kit_conf). Everything read is exported, so steps and
# group scripts see the same configuration.

# kit_project_dir: the project's root (the git top level, else the current
# directory), unless KIT_PROJECT_DIR says otherwise.
kit_project_dir() {
  if [ -n "${KIT_PROJECT_DIR:-}" ]; then
    printf '%s\n' "$KIT_PROJECT_DIR"
  else
    git rev-parse --show-toplevel 2>/dev/null || pwd
  fi
}

# kit_load_config [DESTINATION]: loads the files above. DESTINATION defaults
# to KIT_DESTINATION, then KAMAL_DESTINATION (set by Kamal for hooks).
# The kit's own state, passed from a kit process to the ones it starts.
# Never taken from a file (kit.env, kit.local.env, group.env): set there,
# KIT_IN_HOOK or KIT_SANDBOX would turn every gate off, unseen.
KIT_INTERNAL_VARS="KIT_IN_HOOK KIT_RUN_DIR KIT_GROUP_DEPLOY KIT_SANDBOX KIT_IN_RUNNER KIT_HOOK KIT_STEP KIT_GROUP KIT_GROUP_DIR
  KIT_HOST_NAME KIT_HOST_PID KIT_HOST_PIDS"

# kit_scrub_internal SET-BEFORE: unsets the internal variables that weren't
# set before a file was sourced (SET-BEFORE: their names, space-separated).
kit_scrub_internal() {
  local var
  for var in $KIT_INTERNAL_VARS; do
    case " $1 " in *" $var "*) ;; *) unset "$var" ;; esac
  done
}

# kit_internal_set: the internal variables set now.
kit_internal_set() {
  local var out=""
  for var in $KIT_INTERNAL_VARS; do
    [ -z "${!var+set}" ] || out="$out $var"
  done
  printf '%s\n' "$out"
}

kit_load_config() {
  local dest=${1:-${KIT_DESTINATION:-${KAMAL_DESTINATION:-}}}
  local saved="" var file internal

  # What the environment says wins over the files, for every variable: a
  # script that sets KT_HOST (the sandbox, a rehearsal) must never lose to
  # the real server's address in kit.local.env. Remember the environment
  # (and any KIT_* set in this shell), then put it back after the files.
  for var in $( (compgen -e; compgen -v KIT_) 2>/dev/null | sort -u); do
    case $var in KIT_HOME | KIT_LOADED | PWD | OLDPWD | SHLVL | _ | BASH_* | FUNCNAME) continue ;; esac
    kit_is_name "$var" || continue
    saved="$saved$(printf '%s=%q' "$var" "${!var-}")"$'\n'
  done

  KIT_PROJECT_DIR=$(kit_project_dir)
  KIT_CONFIG_DIR=${KIT_CONFIG_DIR:-$KIT_PROJECT_DIR/.kamal}
  internal=$(kit_internal_set)

  set -a
  # shellcheck source=defaults.sh
  . "$KIT_HOME/lib/defaults.sh"
  for file in \
    "$KIT_CONFIG_DIR/kit.env" \
    ${dest:+"$KIT_CONFIG_DIR/kit.$dest.env"} \
    "$KIT_CONFIG_DIR/kit.local.env"; do
    if [ -f "$file" ]; then
      # shellcheck disable=SC1090
      . "$file"
    fi
  done
  # The project's own Kamal config, before -c (which comes through the
  # environment) replaces it: groups that don't name a config belong to it.
  if [ -z "${KIT_PROJECT_KAMAL_CONFIG_FILE+set}" ]; then
    KIT_PROJECT_KAMAL_CONFIG_FILE=${KIT_KAMAL_CONFIG_FILE:-}
  fi
  kit_scrub_internal "$internal"
  eval "$saved"
  set +a

  KIT_DESTINATION=$dest
  KIT_LOADED=1
  export KIT_PROJECT_DIR KIT_CONFIG_DIR KIT_DESTINATION KIT_LOADED
}

# kit_conf NAME [DEFAULT]: NAME's value for the current destination:
# NAME_<DESTINATION> if set, else NAME if set, else DEFAULT. Set to empty
# counts as set (KIT_SMOKE_URLS_STAGING= turns smoke tests off for staging).
kit_conf() {
  local name=$1 default=${2:-} scoped
  if [ -n "${KIT_DESTINATION:-}" ]; then
    # The destination's suffix, worked out once per destination.
    if [ "${_KIT_DEST_FOR:-}" != "$KIT_DESTINATION" ]; then
      _KIT_DEST_SUFFIX=$(kit_upper "$KIT_DESTINATION")
      _KIT_DEST_FOR=$KIT_DESTINATION
    fi
    scoped="${name}_$_KIT_DEST_SUFFIX"
    if [ -n "${!scoped+set}" ]; then
      printf '%s\n' "${!scoped}"
      return
    fi
  fi
  if [ -n "${!name+set}" ]; then
    printf '%s\n' "${!name}"
  else
    printf '%s\n' "$default"
  fi
}

# kit_env_get KEY FILE: KEY's value in a dotenv file, parsed, never sourced
# (a value with spaces or $ would otherwise run). Read as the shell would
# read the simple cases: a quoted value up to its closing quote, an
# unquoted one up to a comment (` # …`) or the end; what follows is
# dropped. The last assignment wins.
kit_env_get() {
  local key=$1 file=$2
  [ -r "$file" ] || return 1
  kit_env_parse "$key" <"$file"
}

# kit_env_parse KEY: kit_env_get, from stdin.
kit_env_parse() {
  local key=$1 value
  kit_is_name "$key" || kit_die "not a variable name: $key"
  value=$(sed -n "s/^[[:space:]]*\(export[[:space:]]\{1,\}\)\{0,1\}${key}[[:space:]]*=//p" | tail -n 1)
  case $value in
    \"*) value=${value#\"} && value=${value%%\"*} ;;
    \'*) value=${value#\'} && value=${value%%\'*} ;;
    *)
      value=${value%%[[:space:]]#*}
      value=${value%"${value##*[![:space:]]}"}
      ;;
  esac
  printf '%s\n' "$value"
}

# -------------------------------------------------------------- processes

# kit_descendants PID: PID's children, their children…, one per line.
kit_descendants() {
  ps -A -o pid= -o ppid= 2>/dev/null | awk -v root="$1" '
    { pid[NR] = $1; parent[NR] = $2 }
    END {
      tree[root] = 1
      do {
        grew = 0
        for (i = 1; i <= NR; i++)
          if (!(pid[i] in tree) && (parent[i] in tree)) { tree[pid[i]] = 1; print pid[i]; grew = 1 }
      } while (grew)
    }'
}

# kit_kill_tree SIGNAL PID: PID and everything it started. Killing PID
# alone would leave its children running, holding the caller's pipes.
kit_kill_tree() {
  local sig=$1 pid=$2 pids
  pids=$(kit_descendants "$pid")
  # shellcheck disable=SC2086 # one pid per word
  kill "-$sig" "$pid" $pids 2>/dev/null || true
}

# kit_timeout SECONDS COMMAND...: runs COMMAND, killing it and what it
# started after SECONDS (0 or empty: no limit). Exit status 124 on
# timeout, like timeout(1), which macOS doesn't ship. COMMAND runs in the
# background, so its stdin is /dev/null: anything interactive must read
# /dev/tty. And it ignores Ctrl-C, like any background job of a script:
# an interrupt (or TERM) of the kit stops it here, then the kit.
kit_timeout() {
  local secs=$1 rc
  shift
  if ! kit_is_int "$secs" || [ "$secs" -eq 0 ]; then
    "$@"
    return
  fi
  "$@" &
  _KIT_TIMEOUT_PID=$!
  (
    sleep "$secs"
    kit_kill_tree TERM "$_KIT_TIMEOUT_PID"
    sleep 5
    kit_kill_tree KILL "$_KIT_TIMEOUT_PID"
  ) </dev/null >/dev/null 2>&1 3>&- &
  _KIT_TIMEOUT_WATCHER=$!
  trap '_kit_timeout_stop; kit_signal_traps; exit 130' INT
  trap '_kit_timeout_stop; kit_signal_traps; exit 143' TERM
  rc=0
  wait "$_KIT_TIMEOUT_PID" || rc=$?
  kit_signal_traps
  kit_kill_tree TERM "$_KIT_TIMEOUT_WATCHER"
  wait "$_KIT_TIMEOUT_WATCHER" 2>/dev/null || true
  case $rc in 137 | 143) rc=124 ;; esac
  return "$rc"
}

_kit_timeout_stop() {
  kit_kill_tree TERM "$_KIT_TIMEOUT_WATCHER"
  kit_kill_tree TERM "$_KIT_TIMEOUT_PID"
}

# kit_committed_conf NAME: NAME as the committed configuration sets it
# (.kamal/kit.env and kit.<destination>.env at HEAD, read not sourced;
# NAME_<DESTINATION> first), ignoring the environment, kit.local.env and
# uncommitted edits: for policy that a deployer can't turn off for
# themselves (KIT_UNSKIPPABLE, KIT_SKIP_REASON_REQUIRED).
kit_committed_conf() {
  local name=$1 rel file content value="" scoped="" v sname=""
  rel=${KIT_CONFIG_DIR#"$KIT_PROJECT_DIR"/}
  for file in "$rel/kit.env" ${KIT_DESTINATION:+"$rel/kit.$KIT_DESTINATION.env"}; do
    content=$(git -C "$KIT_PROJECT_DIR" show "HEAD:$file" 2>/dev/null) || continue
    v=$(printf '%s\n' "$content" | kit_env_parse "$name")
    if printf '%s\n' "$content" | grep -Eq "^[[:space:]]*(export[[:space:]]+)?${name}="; then value=$v; fi
    if [ -n "${KIT_DESTINATION:-}" ]; then
      sname="${name}_$(kit_upper "$KIT_DESTINATION")"
      v=$(printf '%s\n' "$content" | kit_env_parse "$sname")
      if printf '%s\n' "$content" | grep -Eq "^[[:space:]]*(export[[:space:]]+)?${sname}="; then scoped="set:$v"; fi
    fi
  done
  if [ -n "$scoped" ]; then printf '%s\n' "${scoped#set:}"; else printf '%s\n' "$value"; fi
}

# ---------------------------------------------------------------- the run
#
# A `kit deploy` (or a `kit group deploy` of its own) keeps a folder for
# the run, KIT_RUN_DIR, which its Kamal commands' hooks share: gates that
# passed, skips already notified, `kamal config`. Its .kit-run file marks
# it as the kit's: a KIT_RUN_DIR without it (left in a shell, or set by
# hand) is not trusted with gates "already passed".

# kit_at_exit COMMAND: runs COMMAND (a string) when the kit exits, however
# it does: done, failed, interrupted (Ctrl-C) or terminated. The last one
# registered runs first.
_KIT_AT_EXIT=""
kit_at_exit() {
  _KIT_AT_EXIT="$1${_KIT_AT_EXIT:+
$_KIT_AT_EXIT}"
  trap _kit_run_at_exit EXIT
  kit_signal_traps
}

# kit_signal_traps: INT, TERM and HUP exit (running the exit commands).
kit_signal_traps() {
  trap 'exit 130' INT
  trap 'exit 143' TERM
  trap 'exit 129' HUP
}

_kit_run_at_exit() {
  local cmd
  set +e
  while IFS= read -r cmd; do
    [ -z "$cmd" ] || eval "$cmd"
  done <<<"$_KIT_AT_EXIT"
  _KIT_AT_EXIT=""
}

# kit_run_dir_new: creates and exports KIT_RUN_DIR (removed on exit).
kit_run_dir_new() {
  KIT_RUN_DIR=$(mktemp -d "${TMPDIR:-/tmp}/kit-run.XXXXXX")
  : >"$KIT_RUN_DIR/.kit-run"
  export KIT_RUN_DIR
  kit_at_exit "rm -rf '$KIT_RUN_DIR'"
}

# kit_in_run: within a run the kit started.
kit_in_run() { [ -n "${KIT_RUN_DIR:-}" ] && [ -f "$KIT_RUN_DIR/.kit-run" ]; }

# kit_sandbox_skip: in a gate, stops it (exit 0) when running for `kit
# sandbox`: local, nothing to check against GitHub, the branch or a
# freeze. Only for the sandbox destination: KIT_SANDBOX anywhere else is
# refused, never a quiet way past the gates.
kit_sandbox_skip() {
  kit_in_sandbox || return 0
  kit_info "sandbox: $(basename "$0") skipped"
  exit 0
}

# kit_in_sandbox: running for `kit sandbox` (KIT_SANDBOX, destination
# sandbox). KIT_SANDBOX with another destination stops the kit.
kit_in_sandbox() {
  [ -n "${KIT_SANDBOX:-}" ] || return 1
  [ "${KIT_DESTINATION:-}" = sandbox ] ||
    kit_die "KIT_SANDBOX is set, but the destination is '${KIT_DESTINATION:-none}': it's for \`kit sandbox\` only (unset it)"
}

# kit_wait_until TIMEOUT INTERVAL COMMAND...: runs COMMAND every INTERVAL
# seconds until it succeeds (0) or TIMEOUT seconds have passed (1).
kit_wait_until() {
  local timeout=$1 interval=$2 deadline
  shift 2
  deadline=$((SECONDS + timeout))
  while :; do
    if "$@"; then return 0; fi
    [ "$SECONDS" -ge "$deadline" ] && return 1
    sleep "$interval"
  done
}

# kit_require COMMAND [HINT]: fails with a clear message when a tool is missing.
kit_require() {
  command -v "$1" >/dev/null 2>&1 || kit_die "needs '$1'${2:+ ($2)}"
}

# kit_version_being_deployed: Kamal's version in a hook (a commit id by
# default, <sha>_uncommitted_<hash> for a dirty tree, or whatever VERSION /
# --version said), else HEAD's commit.
kit_version_being_deployed() {
  if [ -n "${KAMAL_VERSION:-}" ]; then
    printf '%s\n' "$KAMAL_VERSION"
  else
    git -C "$(kit_project_dir)" rev-parse HEAD
  fi
}

# kit_is_sha VALUE: a full or abbreviated (7+) hex commit id.
kit_is_sha() {
  case "${1:-}" in
    *[!0-9a-f]* | '') return 1 ;;
    *) [ "${#1}" -ge 7 ] ;;
  esac
}

# kit_is_rollback: this hook runs for `kamal rollback`.
kit_is_rollback() { [ "${KAMAL_COMMAND:-}" = rollback ]; }
