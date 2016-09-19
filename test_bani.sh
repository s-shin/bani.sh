#!/bin/bash
set -eu

. "$(cd $(dirname ${BASH_SOURCE:-$0}); pwd)/bani.sh"

banish_tap_begin

#---

banish_tap_diag "banish_tap"

banish_tap_eq 10 10
banish_tap_ne 0 100 "0 != 100"

#---

banish_tap_diag "banish_util_indexof"

r=$(banish_util_indexof bar foo bar fizz)
banish_tap_eq "$r" 1 "contains"

r=$(banish_util_indexof bar foo fizz)
banish_tap_eq "$r" -1 "not contains"

#---

banish_tap_diag "banish_util_split"

banish_util_split ":" "foo:bar"
r=("${banish_util_split_result[@]}")
banish_tap_eq "${#r[@]}" 2
banish_tap_equal "${r[0]}" "foo"
banish_tap_equal "${r[1]}" "bar"

banish_util_split ":" ":bar"
r=("${banish_util_split_result[@]}")
banish_tap_eq "${#r[@]}" 2
banish_tap_equal "${r[0]}" ""
banish_tap_equal "${r[1]}" "bar"

banish_util_split ":" "foo:"
r=("${banish_util_split_result[@]}")
banish_tap_eq "${#r[@]}" 2
banish_tap_equal "${r[0]}" "foo"
banish_tap_equal "${r[1]}" ""

banish_util_split ":" "::foo::"
r=("${banish_util_split_result[@]}")
banish_tap_eq "${#r[@]}" 5
banish_tap_equal "${r[0]}" ""
banish_tap_equal "${r[1]}" ""
banish_tap_equal "${r[2]}" "foo"
banish_tap_equal "${r[3]}" ""
banish_tap_equal "${r[4]}" ""

#---

banish_tap_diag "banish_color"

r="$(banish_color red red)"
banish_tap_equal "$r" "$(echo -e "\033[31mred\033[0m")"

#---

banish_tap_end
