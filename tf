#!/usr/bin/env bash
#
# wrapper for terraform

# shellcheck disable=SC2086

if ! command -v terraform >/dev/null 2>&1 ; then echo "Missing dependency: terraform" 1>&2 ; exit 1 ; fi

cmd="$1"
shift

if git rev-parse &>/dev/null ; then
  # we're on git, so use the git branch as the filename
  plan_name="$(git symbolic-ref HEAD 2> /dev/null | sed -e 's/refs\/heads\///')"
else
  # I don't know what we're doing, so use the unix timestamp
  plan_name="$(date +%s)"
fi

case "$cmd" in
  plan)

    (set -x ; terraform plan -compact-warnings -input=false -out="$plan_name.plan" "$@" ) ; exit_code="$?"
    ;;
  show)
    if ! command -v uncolor >/dev/null 2>&1 ; then echo "Missing dependency: uncolor" 1>&2 ; exit 1 ; fi
    if ! command -v pee >/dev/null 2>&1 ; then echo "Missing dependency: pee" 1>&2 ; exit 1 ; fi

    for file in *.plan ; do
      # shellcheck disable=SC2089 disable=SC2016
      ( set -x ; terraform show "$file" | pee "cat -" "uncolor > $file.txt" ) ; exit_code="$?"
    done
    ;;
  *)
    ;;
esac

if command -v notice >/dev/null 2>&1 ; then
  notice "terraform '$1' done"
fi

exit "$exit_code"

# EOF
