# shellcheck shell=bash
# The hook dispatcher: `kit hook <name>`, which every .kamal/hooks/<name>
# shim runs. Sourced after core.sh and notify.sh.
#
# A hook runs, in order:
#   1. the steps listed in KIT_HOOK_<NAME> (e.g. KIT_HOOK_PRE_DEPLOY), each
#      a project step (.kamal/steps/<step>), a kit step (steps/<step>), or a
#      path relative to the project;
#   2. every executable in .kamal/hooks.d/<name>/, in name order.
# The first failing step fails the hook (and so Kamal's command), after a
# notification saying which step failed and why.
#
# Kamal hands hooks its secrets in the environment: steps must never print
# or send the environment.

# kit_hook_run [--gates] NAME: runs hook NAME. Unknown hook names work too
# (a hook Kamal adds later just needs a shim and a KIT_HOOK_ list).
# --gates: only its listed steps that are cached per run (KIT_CACHED_STEPS),
# not the project's hooks.d scripts, so that a command can pass the gates
# before it changes anything Kamal won't (a group stopping a role first):
# `kit hook --gates pre-deploy`. Kamal's own run of the hook then finds
# them passed.
kit_hook_run() {
  local gates=false hook var step path skip reason rc started cached unskippable
  local steps=()
  if [ "${1:-}" = --gates ]; then
    gates=true
    shift
  fi
  hook=$1

  # A kamal command run from inside a step (a migration through `kamal app
  # exec`, say) would run pre-connect again: the outer command's hooks
  # already ran, so nested ones do nothing. KIT_IN_HOOK is <hook>:<pid>,
  # and counts only while that hook's process is one of ours: a value left
  # in a shell, or set by hand, turns no gate off.
  if [ -n "${KIT_IN_HOOK:-}" ]; then
    if _kit_hook_outer_running "$KIT_IN_HOOK"; then
      return 0
    fi
    kit_warn "$hook: KIT_IN_HOOK=$KIT_IN_HOOK isn't a hook of this command: ignored, the steps run"
  fi
  export KIT_IN_HOOK="$hook:$$"

  var="KIT_HOOK_$(kit_upper "$hook")"
  for step in $(kit_words "$(kit_conf "$var" "")"); do steps+=("$step"); done
  # The project's scripts by glob, not by word: its path may hold spaces.
  if [ "$gates" != true ] && [ -d "$KIT_CONFIG_DIR/hooks.d/$hook" ]; then
    for step in "$KIT_CONFIG_DIR/hooks.d/$hook"/*; do
      [ -f "$step" ] && [ -x "$step" ] && steps+=("$step")
    done
  fi
  skip=$(kit_conf KIT_SKIP "")
  reason=$(kit_conf KIT_SKIP_REASON "")
  cached=$(kit_conf KIT_CACHED_STEPS "")
  unskippable=$(kit_committed_conf KIT_UNSKIPPABLE)

  for step in ${steps[@]+"${steps[@]}"}; do
    if [ "$gates" = true ] && ! kit_in_list "$(basename "$step")" "$cached"; then
      continue
    fi
    if kit_in_list "$(basename "$step")" "$skip"; then
      if kit_in_list "$(basename "$step")" "$unskippable"; then
        kit_error "$hook: $(basename "$step") can't be skipped${KIT_DESTINATION:+ on $KIT_DESTINATION} (KIT_UNSKIPPABLE, in the committed kit.env)"
        kit_notify error "$hook: refused to skip $(basename "$step") (KIT_UNSKIPPABLE), by ${KAMAL_PERFORMER:-${USER:-unknown}}"
        return 1
      fi
      kit_skip_reason_check || return 1
      kit_warn "$hook: skipping $step (KIT_SKIP${reason:+: $reason})"
      # Once per kit run: each group's deploy runs the hooks again.
      if _kit_skip_first "$(basename "$step")"; then
        kit_notify warning "$hook: step $(basename "$step") skipped by KIT_SKIP${reason:+ (\"$reason\")}, by ${KAMAL_PERFORMER:-${USER:-unknown}}"
      fi
      continue
    fi

    path=$(_kit_hook_resolve "$step") || {
      kit_error "$hook: no step named '$step' (looked in .kamal/steps/, the kit's steps/, and as a path)"
      kit_notify error "$hook: no step named '$step'"
      return 1
    }

    if _kit_hook_cached "$hook" "$step"; then
      kit_info "$hook: $step already passed in this run"
      continue
    fi

    started=$SECONDS
    rc=0
    KIT_HOOK=$hook KIT_STEP=$step kit_timeout "$(_kit_step_timeout "$step")" "$path" || rc=$?
    if [ "$rc" -ne 0 ]; then
      if [ "$rc" -eq 124 ]; then
        kit_error "$hook: $step timed out after $((SECONDS - started))s"
      else
        kit_error "$hook: $step failed (exit $rc)"
      fi
      kit_notify error "${KAMAL_COMMAND:-deploy} stopped: $hook step '$step' failed (version ${KAMAL_SERVICE_VERSION:-${KAMAL_VERSION:-?}}, by ${KAMAL_PERFORMER:-unknown})"
      return "$rc"
    fi
    _kit_hook_cache "$hook" "$step"
  done
  return 0
}

# _kit_hook_outer_running HOOK:PID: PID is a running ancestor of this
# process, and is `kit hook` (the outer hook). From the whole process
# table: busybox's ps (the kit's image) has no -p.
_kit_hook_outer_running() {
  local pid=${1##*:}
  kit_is_int "$pid" && [ "$pid" -gt 1 ] || return 1
  ps -A -o pid= -o ppid= -o args= 2>/dev/null | awk -v self=$$ -v outer="$pid" '
    { parent[$1] = $2; args[$1] = " " $0 " " }
    END {
      if (!(outer in args) || args[outer] !~ / hook /) exit 1
      p = self
      for (i = 0; i < 64 && (p in parent) && p > 1; i++) {
        p = parent[p]
        if (p == outer) exit 0
      }
      exit 1
    }'
}

# _kit_step_timeout STEP: KIT_STEP_TIMEOUT_<STEP>, else KIT_STEP_TIMEOUT;
# for ci-green, at least KIT_CI_WAIT and a minute, so that waiting for CI
# ends with CI's verdict, not with the step killed.
_kit_step_timeout() {
  local name timeout wait
  name=$(basename "$1")
  timeout=$(kit_conf "KIT_STEP_TIMEOUT_$(kit_upper "$name")" "$(kit_conf KIT_STEP_TIMEOUT 600)")
  if [ "$name" = ci-green ] && kit_is_int "$timeout" && [ "$timeout" -gt 0 ]; then
    wait=$(kit_conf KIT_CI_WAIT 0)
    kit_is_int "$wait" && [ "$timeout" -lt $((wait + 60)) ] && timeout=$((wait + 60))
  fi
  printf '%s\n' "$timeout"
}

# kit_skip_reason_check: when KIT_SKIP skips anything, KIT_SKIP_REASON must
# say why if KIT_SKIP_REASON_REQUIRED (e.g. _PRODUCTION) is on, in the
# configuration or in the committed kit.env (which the environment and
# kit.local.env can't turn off).
kit_skip_reason_check() {
  [ -n "$(kit_conf KIT_SKIP "")" ] || return 0
  [ -z "$(kit_conf KIT_SKIP_REASON "")" ] || return 0
  kit_is_true "$(kit_conf KIT_SKIP_REASON_REQUIRED false)" ||
    kit_is_true "$(kit_committed_conf KIT_SKIP_REASON_REQUIRED)" || return 0
  kit_error "skipping steps${KIT_DESTINATION:+ on $KIT_DESTINATION} needs a reason: KIT_SKIP_REASON=\"why\" (KIT_SKIP_REASON_REQUIRED)"
  return 1
}

# _kit_skip_first STEP: true the first time STEP is skipped in this kit run
# (always, outside one).
_kit_skip_first() {
  kit_in_run || return 0
  [ ! -f "$KIT_RUN_DIR/skipped-$1" ] || return 1
  : >"$KIT_RUN_DIR/skipped-$1"
}

# _kit_hook_resolve STEP: the executable to run for STEP.
_kit_hook_resolve() {
  local step=$1
  case $step in
    /*) [ -x "$step" ] && printf '%s\n' "$step" && return 0 ;;
    */*) [ -x "$KIT_PROJECT_DIR/$step" ] && printf '%s\n' "$KIT_PROJECT_DIR/$step" && return 0 ;;
    *)
      if [ -x "$KIT_CONFIG_DIR/steps/$step" ]; then
        printf '%s\n' "$KIT_CONFIG_DIR/steps/$step"
        return 0
      fi
      if [ -x "$KIT_HOME/steps/$step" ]; then
        printf '%s\n' "$KIT_HOME/steps/$step"
        return 0
      fi
      ;;
  esac
  return 1
}

# Within one `kit deploy` (KIT_RUN_DIR set), a gate that passed for this
# version isn't run again by the next `kamal deploy -r …` of the same run:
# CI is asked once, and the confirmation is asked once.
_kit_hook_cache_file() {
  printf '%s/passed-%s-%s' "$KIT_RUN_DIR" "$(basename "$2")" "${KAMAL_VERSION:-none}"
}

_kit_hook_cached() {
  kit_in_run || return 1
  kit_in_list "$(basename "$2")" "$(kit_conf KIT_CACHED_STEPS "")" || return 1
  [ -f "$(_kit_hook_cache_file "$1" "$2")" ]
}

_kit_hook_cache() {
  kit_in_run || return 0
  kit_in_list "$(basename "$2")" "$(kit_conf KIT_CACHED_STEPS "")" || return 0
  : >"$(_kit_hook_cache_file "$1" "$2")"
}
