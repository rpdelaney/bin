#!/usr/bin/env bash
#

if [[ -z "$1" ]] ; then
  echo "argument not optional" 1>&2
  exit 1
fi

_halp_try() {
  eval "$1 --help" && return
  eval "$1 -h" && return
  eval "$1 -?" && return
}

pager < <(set -x ; _halp_try "$1" 2>&1)
