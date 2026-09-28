# shellcheck shell=bash
# The deploy lock, held for a whole kit operation. Sourced after core.sh,
# notify.sh and kamal.sh.
#
# Kamal's own lock (`kamal lock`, a folder on the servers) is taken and
# released by each Kamal command that changes something. A kit deploy is
# a sequence of them (stop a role, deploy it, hand over…), and between two
# of them another deploy could take the lock and interleave. So the kit
# takes Kamal's lock once, before anything changes, and runs every Kamal
# command under it with KAMAL_LOCK=true (Kamal's own way of saying "this
# process holds the lock": it neither takes nor releases it then).
#
# It's released on the way out, whatever the way (success, failure,
# Ctrl-C, TERM). A run that couldn't release it (killed outright, the
# machine gone) leaves it held: the lock's message names the machine and
# the process, so a later run from that machine that finds the process
# gone releases it, warned and notified. Held from elsewhere, or by a run
# still alive, it's refused, saying by whom and since when; `kit lock
# release` releases it on purpose. It never expires by itself: a deploy
# waiting on CI or a slow health check looks just like a dead one.

# _kit_lock_kamal SUBCOMMAND ARGS...: `kamal lock …`, as the lock's owner
# or not (KAMAL_LOCK unset for it), without hooks.
_kit_lock_kamal() { KAMAL_LOCK='' kit_kamal lock "$@" -H; }

# _kit_lock_marker: this run holds the lock for the Kamal config and
# destination in use (a nested kit process, a group deploy within `kit
# deploy`, finds it and takes nothing).
_kit_lock_marker() {
  printf '%s/lock-%s\n' "$KIT_RUN_DIR" \
    "$(printf '%s' "$(kit_conf KIT_KAMAL_CONFIG_FILE "")@${KIT_DESTINATION:-}" | tr -c 'A-Za-z0-9._@-' '_')"
}

# kit_lock_owner: who holds a lock this process takes: user@machine:pid.
# In the kit's image (KIT_RUNNER=docker), the machine and the process are
# those of the `kit` that started the container, which lives as long as
# the container does.
kit_lock_owner() {
  printf '%s@%s:%s\n' "$(id -un 2>/dev/null || echo "uid$(id -u)")" \
    "${KIT_HOST_NAME:-$(uname -n)}" "${KIT_HOST_PID:-$$}"
}

# _kit_pid_alive PID: a process PID runs on this machine. In the kit's
# image, this machine's processes are those listed when the container
# started (KIT_HOST_PIDS): the container can't see them.
_kit_pid_alive() {
  if [ -n "${KIT_HOST_PIDS+set}" ]; then
    kit_in_list "$1" "$KIT_HOST_PIDS"
  else
    ps -A -o pid= 2>/dev/null | tr -d ' ' | grep -qx "$1"
  fi
}

# kit_lock_acquire WHAT: takes the deploy lock for the whole run (the
# caller has made its run folder), unless it's held already by this run.
kit_lock_acquire() {
  local what=$1 marker message out status owner mine
  kit_is_true "$(kit_conf KIT_LOCK true)" || return 0
  kit_in_run || kit_die "kit_lock_acquire outside a run"
  marker=$(_kit_lock_marker)
  [ ! -f "$marker" ] || return 0
  if [ "${KAMAL_LOCK:-}" = true ]; then
    kit_info "KAMAL_LOCK=true: the deploy lock is taken as held by you"
    return 0
  fi

  mine=$(kit_lock_owner)
  message="$what [kit:$mine]"
  if ! out=$(_kit_lock_kamal acquire -m "$message" 2>&1); then
    status=$(_kit_lock_kamal status 2>&1 || true)
    case $status in
      *"There is no deploy lock"* | "")
        printf '%s\n' "$out" >&2
        kit_die "could not take the deploy lock (above)"
        ;;
    esac
    owner=$(printf '%s\n' "$status" | sed -n 's/.*\[kit:\([^]]*\)\].*/\1/p' | head -n 1)
    if [ -n "$owner" ] && [ "${owner%:*}" = "${mine%:*}" ] && ! _kit_pid_alive "${owner##*:}"; then
      kit_warn "the deploy lock was left by a run of the kit from this machine that's gone (pid ${owner##*:}): releasing it"
      kit_notify warning "released a deploy lock left by a dead run ($owner)"
      _kit_lock_kamal release >/dev/null 2>&1 || kit_die "could not release the stale deploy lock"
      out=$(_kit_lock_kamal acquire -m "$message" 2>&1) || {
        printf '%s\n' "$out" >&2
        kit_die "could not take the deploy lock (above)"
      }
    else
      printf '%s\n' "$status" >&2
      kit_die "the deploy lock is held (above): another deploy is running. If it's dead: kit lock release${KIT_DESTINATION:+ -d $KIT_DESTINATION}"
    fi
  fi
  : >"$marker"
  export KAMAL_LOCK=true
  kit_at_exit "_kit_lock_release '$marker'"
}

# _kit_lock_release MARKER: releases the lock this run took.
_kit_lock_release() {
  [ -f "$1" ] || return 0
  if _kit_lock_kamal release >/dev/null 2>&1; then
    rm -f "$1"
  else
    kit_warn "could not release the deploy lock: kit lock release${KIT_DESTINATION:+ -d $KIT_DESTINATION}"
  fi
}

# kit_lock_release_asking [--yes]: `kit lock release`: shows the lock,
# and releases it once confirmed.
kit_lock_release_asking() {
  local yes=${1:-} status answer tty=${KIT_TTY:-/dev/tty}
  status=$(_kit_lock_kamal status 2>&1) || true
  case $status in
    *"There is no deploy lock"*)
      kit_ok "there is no deploy lock"
      return 0
      ;;
  esac
  printf '%s\n' "$status" >&2
  if [ "$yes" != --yes ]; then
    { : <"$tty"; } 2>/dev/null || kit_die "no terminal to confirm on: kit lock release --yes"
    printf 'Release it? Only if that deploy is dead: releasing a live one lets another run alongside it. [y/N] ' >&2
    IFS= read -r answer <"$tty" || answer=
    case $answer in y | Y | yes) ;; *) kit_die "not released" ;; esac
  fi
  _kit_lock_kamal release || kit_die "could not release the deploy lock"
  kit_notify warning "deploy lock released by hand, by $(kit_lock_owner)"
  kit_ok "deploy lock released"
}
