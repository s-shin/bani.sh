
BANISH_VERSION="0.0.1"
BANISH_AUTHOR="Shintaro Seki <s2pch.luck@gmail.com>"
BANISH_LICENSE="MIT"

#-------------------------------------------------------------------------------
# INTERNAL
#-------------------------------------------------------------------------------

_banish_error() {
    >&2 echo "[bani.sh] $@" 
    >&2 banish_trace 1
}

#-------------------------------------------------------------------------------
# UTILITIY
#-------------------------------------------------------------------------------

banish_trace() {
    local skip_idx="${1:-0}"
    local prefix="${2:-  <= }"
    local i
    for ((i = $skip_idx+1; i < ${#FUNCNAME[@]}; i++)); do
        echo "${prefix}${FUNCNAME[$i]} (${BASH_SOURCE[$i]}:${BASH_LINENO[$i]})"
    done
}

banish_util_indexof() {
    local v="$1"; shift
    local i=0
    for t in "$@"; do
        if [[ "$t" = "$v" ]]; then
            echo $i
            return
        fi
        i=$((i+1))
    done
    echo -1
}

banish_util_split() {
    IFS="$1" read -ra banish_util_split_result <<< "$2"
    if [[ "$2" = *"$1" ]]; then
        banish_util_split_result=("${banish_util_split_result[@]}" "")
    fi
}
banish_util_split_result=()

#-------------------------------------------------------------------------------
# COLOR
#-------------------------------------------------------------------------------

BANISH_COLOR=${BANISH_COLOR:-true}

banish_color_ansi() {
    local codes=$1; shift
    if $BANISH_COLOR; then
        echo -e "\033[${codes}m$@\033[0m"
    else
        echo "$@"
    fi
}

banish_color_mod_to_code() {
    local mod="$1"; shift
    local code
    case $mod in
        "b" | "bold" ) code=1;;
        * ) _banish_error "unknown modifier: $mod"; return 1;;
    esac
    echo $code
}

banish_color_name_to_code() {
    local color="$1"; shift
    local bg="${1:-false}"; shift
    local code
    case "$color" in
        "k" | "black"   ) code=30;;
        "r" | "red"     ) code=31;;
        "g" | "green"   ) code=32;;
        "y" | "yellow"  ) code=33;;
        "b" | "blue"    ) code=34;;
        "m" | "magenta" ) code=35;;
        "c" | "cyan"    ) code=36;;
        "w" | "white"   ) code=37;;
        * ) _banish_error "unknown color: $color"; return 1;;
    esac
    if $bg; then
        code=$((code + 10))
    fi
    echo $code
}

banish_color() {
    local format="${1:-}"; shift
    if [[ -z "$format" ]]; then
        echo "$@"
        return
    fi
    local code
    if code="$(banish_color_name_to_code "$format" 2>/dev/null)"; then
        banish_color_ansi "$code" "$@"
        return
    fi
    code=""
    local back
    if [[ "$format" = *,* ]]; then
        back=$(echo "$format" | cut -d, -f1)
        code="$(banish_color_name_to_code "$back" true)"
        format=$(echo "$format" | cut -d, -f2)
        if [[ -z "$format" ]]; then
            banish_color_ansi "$code" "$@"
            return
        fi
    fi
    if [[ "$format" = *+ ]]; then
        local fore=$(echo "$format" | cut -d+ -f1)
        code="$(banish_color_name_to_code "$fore");$code"
        code="$(banish_color_mod_to_code "bold");$code"
        banish_color_ansi "$code" "$@"
        return
    fi
    code="$(banish_color_name_to_code "$format");$code"
    banish_color_ansi "$code" "$@"
}

#-------------------------------------------------------------------------------
# LOG
#-------------------------------------------------------------------------------

BANISH_LOG_LEVEL=${BANISH_LOG_LEVEL:-debug}
BANISH_LOG_COLOR_NOW=${BANISH_LOG_COLOR_NOW:-black+}
BANISH_LOG_COLOR_PREFIX=${BANISH_LOG_COLOR_PREFIX:-black+}
BANISH_LOG_COLOR_SUFFIX=${BANISH_LOG_COLOR_SUFFIX:-}
BANISH_LOG_COLOR_DEBUG=${BANISH_LOG_COLOR_DEBUG:-blue}
BANISH_LOG_COLOR_INFO=${BANISH_LOG_COLOR_INFO:-green}
BANISH_LOG_COLOR_WARN=${BANISH_LOG_COLOR_WARN:-yellow}
BANISH_LOG_COLOR_ERROR=${BANISH_LOG_COLOR_ERROR:-red}

banish_log_level_to_int() {
    case "$1" in
        "debug" ) echo 1;;
        "info"  ) echo 2;;
        "warn"  ) echo 3;;
        "error" ) echo 4;;
        * ) _banish_error "unknown log level: $1"; return 1;;
    esac
}
banish_log_level_to_char() {
    case "$1" in
        "debug" ) echo "D";;
        "info"  ) echo "I";;
        "warn"  ) echo "W";;
        "error" ) echo "E";;
        * ) _banish_error "unknown log level: $1"; return 1;;
    esac
}

banish_log_now() {
    local level=$1; shift
    echo "$(banish_color "$BANISH_LOG_COLOR_NOW" "$(date +"%Y-%m-%d %H:%M:%S")")"
}
banish_log_prefix() {
    local level=$1; shift
    local c=$(banish_log_level_to_char $level)
    echo "$(banish_color "$BANISH_LOG_COLOR_PREFIX" "")$(banish_log_now $level)$(banish_color "$BANISH_LOG_COLOR_PREFIX" " ($c)") "
}
banish_log_suffix() {
    echo ""
}
banish_log() {
    local level=$1; shift
    if [[ $(banish_log_level_to_int "$BANISH_LOG_LEVEL") -le $(banish_log_level_to_int "$level") ]]; then
        echo "$(banish_log_prefix $level)$@$(banish_log_suffix $level)"
    fi
}

banish_log_debug() { banish_log debug "$(banish_color "$BANISH_LOG_COLOR_DEBUG" "$@")"; }
banish_log_info()  { banish_log info "$(banish_color "$BANISH_LOG_COLOR_INFO" "$@")"; }
banish_log_warn()  { banish_log warn "$(banish_color "$BANISH_LOG_COLOR_WARN" "$@")"; }
banish_log_error() { banish_log error "$(banish_color "$BANISH_LOG_COLOR_ERROR" "$@")"; }
banish_log_d() { banish_log_debug "$@"; }
banish_log_i() { banish_log_info "$@"; }
banish_log_w() { banish_log_warn "$@"; }
banish_log_e() { banish_log_error "$@"; }

#-------------------------------------------------------------------------------
# TESTING
#-------------------------------------------------------------------------------

BANISH_TAP_VERSION=13

_banish_tap_n=0
_banish_tap_total=0
_banish_tap_failed=0

_banish_tap_init() {
    _banish_tap_n=0
    _banish_tap_total=0
}

banish_tap_begin() {
    _banish_tap_init
    _banish_tap_total=${1:--1}
    echo "TAP version $BANISH_TAP_VERSION"
    if [[ "${_banish_tap_total}" -ge 0 ]]; then
        echo "1..${_banish_tap_total}"
    fi
}

banish_tap_eq_0() {
    ((_banish_tap_n++))
    local code=$1; shift
    if [[ "$code" -eq 0 ]]; then
        echo "ok $_banish_tap_n - $@"
    else
        ((_banish_tap_failed++))
        local i
        for ((i = 0; i < "${#BASH_SOURCE[@]}"; i++)); do
            if [[ "${BASH_SOURCE[$i]}" != "${BASH_SOURCE[0]}" ]]; then
                break
            fi
        done
        echo "not ok $_banish_tap_n - $@"
        echo "  ---"
        echo "  at: ${FUNCNAME[$i]:-} (${BASH_SOURCE[$i]}:${BASH_LINENO[$(($i-1))]})"
        echo "  ..."
    fi
}

banish_tap_ok() {
    local code="$?"
    banish_tap_eq_0 "$code" "$@"
}

banish_tap_eval() {
    local errexit=false
    if [[ "$SHELLOPTS" = *"errexit"* ]]; then errexit=true; set +e; fi
    eval "$1";
    local code="$?"
    if $errexit; then set -e; fi
    banish_tap_eq_0 "$code" "${2:-$1}";
}
banish_tap_equal() { banish_tap_eval "[[ \"$1\" = \"$2\" ]]" "${@:3}"; }
banish_tap_not_equal() { banish_tap_eval "[[ \"$1\" != \"$2\" ]]" "${@:3}"; }
banish_tap_eq() { banish_tap_eval "[[ $1 -eq $2 ]]" "${@:3}"; }
banish_tap_ne() { banish_tap_eval "[[ $1 -ne $2 ]]" "${@:3}"; }
banish_tap_lt() { banish_tap_eval "[[ $1 -lt $2 ]]" "${@:3}"; }
banish_tap_le() { banish_tap_eval "[[ $1 -le $2 ]]" "${@:3}"; }
banish_tap_gt() { banish_tap_eval "[[ $1 -gt $2 ]]" "${@:3}"; }
banish_tap_ge() { banish_tap_eval "[[ $1 -ge $2 ]]" "${@:3}"; }

banish_tap_diag() {
    if [[ -p /dev/stdin ]]; then
        sed -e "s/^/# /"
    else
        echo "# $@"
    fi
}

banish_tap_bailout() { echo "Bail out! $@"; }

banish_tap_end() {
    if [[ "$_banish_tap_total" -lt 0 ]]; then
        echo "1..${_banish_tap_n}"
    fi
    echo "# tests $_banish_tap_n"
    echo "# pass  $(($_banish_tap_n - $_banish_tap_failed))"
    if [[ "$_banish_tap_failed" = 0 ]]; then
        echo "# ok"
    else
        echo "# fail  $_banish_tap_failed"
    fi
    _banish_tap_init
}
