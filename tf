#!/usr/bin/env bash

#
# wrapper for terraform
# do `tf <command>` instead of `terraform <command>` and you might get some sugar added
#

# shellcheck disable=SC2086

if ! command -v terraform >/dev/null 2>&1 ; then echo "Missing dependency: terraform" 1>&2 ; exit 1 ; fi

cmd="$1"
shift

if git rev-parse &>/dev/null ; then
  # we're on git, so use the git branch as the filename
  plan_name="$(git symbolic-ref HEAD 2> /dev/null | sed -e 's/refs\/heads\///; s/\//_/g')"
else
  # I don't know what we're doing, so use the unix timestamp
  plan_name="$(date +%s)"
fi

case "$cmd" in
  init)
    (set -x ; terraform init -input=false "$@" ) ; exit_code="$?"
    ;;
  import)
    (set -x ; terraform import -input=false "$@" ) ; exit_code="$?"
    ;;
  plan)
    # run a plan, non-interactively and saving the plan to a file for reuse later
    (set -x ; terraform plan -input=false -compact-warnings -out="$plan_name.plan" "$@" ) ; exit_code="$?"
    ;;
  show)
    # show the *.plan files in the pwd, and save to text files
    if ! command -v uncolor >/dev/null 2>&1 ; then echo "Missing dependency: uncolor" 1>&2 ; exit 1 ; fi
    if ! command -v pee >/dev/null 2>&1 ; then echo "Missing dependency: pee" 1>&2 ; exit 1 ; fi

    for file in *.plan ; do
      # shellcheck disable=SC2089 disable=SC2016
      ( set -x ; terraform show "$file" | pee "cat -" "uncolor > $file.plan.hcl" ) ; exit_code="$?"
      if ! command -v tf-summarize >/dev/null 2>&1 ; then
        ( set -x ; tf-summarize -tree -draw "$file" | tee "$file.plan.summary" )
      fi
      #
      # TODO: exit_code will get overwritten on the next loop pass
      #
    done
    ;;
  apply)
    # check if the user gave us a terraform plan to apply
    for arg in "$@" ; do
      if [[ -f "$arg" ]]; then
        # terraform plan files are zip compressed archives with contents that
        # have mimetype "application/octet-stream"
        {
          [[ "$(file --mime-type --brief "$arg")" == "application/zip" ]];
          [[ "$(file --mime-type --brief --uncompress-noreport "$arg")" == "application/octet-stream" ]];
        } && ((plan_found++))
      fi
    done

    if [[ "$plan_found" == 1 ]] ; then
      (set -x ; terraform apply -compact-warnings -input=false "$@" ) ; exit_code="$?"
    else
      echo "I couldn't find a plan file in the arguments you gave me." 1>&2 ; exit_code=1
    fi
    ;;
  *)
    ( set -x ; terraform "$cmd" "$@" )
    ;;
esac

# I use `notice` to send notifications that always reach me
message="terraform $cmd done"
if command -v notice >/dev/null 2>&1 ; then
  notice "$message"
elif command -v notify-send >/dev/null 2>&1; then
  notify-send "$message"
elif command -v terminal-notifier >/dev/null 2>&1; then
    terminal-notifier -message "$message"
fi

exit "$exit_code"

# EOF
