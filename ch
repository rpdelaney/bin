#!/usr/bin/bash
#
#augmented 'cd'
#provides enhanced directory changing behavior
#
if [ -d "$@" ]; then            #if the argument is an existing directory, then
    new_dir="$@"                #set new_dir to that path
elif [ -d ."$@" ]; then         #if the a hidden directory matches the argument, then
    new_dir=".""$@"             #set new_dir to the hidden path
elif [ "$@" == '-' ]; then      #if we passed '-' as the argument, then
    new_dir="-"                 #act like cd
else                            #otherwise
    error_msg="cd: directory "$red$bold$1$reset" not found."    #say we can't find it
fi

if [ "$error_msg" ]; then       #if there was an error message, then
    echo "$error_msg"
    unset error_msg
else
    builtin cd "$new_dir"
    timeout 3 git_branch="$(parse_git_branch 2>> /dev/null)" 2>> /dev/null
    ls
fi
