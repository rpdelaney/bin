#!/usr/bin/env bash

#
# wrapper for terraform
# do `tf <command>` instead of `terraform <command>` and you might get some sugar added
#

# shellcheck disable=SC2086

# Dependencies {{{1
dependencies="terraform uncolor pee"
missing_dependencies=""

is_missing=0
for dependency in $dependencies; do
    if ! command -v "$dependency" > /dev/null 2>&1; then
        # If not found, add to missing_dependencies string
        missing_dependencies="$missing_dependencies $dependency"
        is_missing=1
    fi
done

if [ $is_missing -eq 1 ]; then
    printf "Required dependencies are missing:%s\n" "$missing_dependencies"
    exit 1
fi

unset dependencies missing_dependencies is_missing
# Dependencies 1}}}

cmd="$1"
shift

if git rev-parse &>/dev/null ; then
  # we're on git, so use the git branch as the filename
  plan_name="$(git symbolic-ref HEAD 2> /dev/null | sed -e 's/refs\/heads\///; s/\//_/g')_$(date +%s)"
else
  # I don't know what we're doing, so use the unix timestamp
  plan_name="$(date +%s)"
fi

case "$cmd" in
  init)
    (set -x ; terraform init -upgrade -input=false "$@" ) ; exit_code="$?"
    ;;
  import)
    (set -x ; terraform import -input=false "$@" ) ; exit_code="$?"
    ;;
  plan)
    # run a plan, non-interactively and saving the plan to a file for reuse later
    (set -x ; terraform plan -input=false -compact-warnings -out="${plan_name}.plan" "$@" ) ; exit_code="$?"
    ;;
  show)
    # show the *.plan files in the pwd, and save to text files
    for file in *.plan ; do
      # shellcheck disable=SC2089 disable=SC2016
      ( set -x ; terraform show "$file" | pee "cat -" "uncolor > ${file}.hcl" ) ; exit_code="$?"
      ( set -x ; /opt/homebrew/bin/tf-summarize -tree "$file" | tee "${file}.summary.txt" )
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
