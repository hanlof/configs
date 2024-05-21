# Prompt stuff: format the number of jobs and hide if 0
function __prompt_format_jobs()
{
  a="$*"
  b=${a%0}
  printf "${b:+[$a] }"
  #printf ${b:+\\e[1;34m<\\e[0m}${b:=$*}
}

# reference: https://github.com/git/git/blame/master/contrib/completion/git-prompt.sh
function __git_color_path()
{
  printf -v red  '\[\e[1;31m\]'
  printf -v yellow  '\[\e[1;33m\]'
  printf -v purple '\[\e[1;35m\]'
  printf -v rst '\[\e[0m\]'
  printf -v brown '\[\e[33m\]'
  printf -v pink '\[\e[35m\]'
  printf -v white '\[\e[1;34m\]'
  out="$PWD"
  gittop=$(git rev-parse --show-toplevel 2> /dev/null)
  while [ "$?" == "0" ]; do
    if [ -d "${gittop}/.git/rebase-merge" -o \
         -d "${gittop}/.git/rebase-apply" -o \
         -f "${gittop}/.git/MERGE_HEAD" -o \
         -f "${gittop}/.git/CHERRY_PICK_HEAD" -o \
         -f "${gittop}/.git/REVERT_HEAD" -o \
         -d "${gittop}/.git/sequencer" ]; then
      col=${yellow}
    else
      col=${purple}
    fi
    tail=${out#${gittop}}
    repo_name=${gittop##*/}
    repo_prefix=${gittop%$repo_name}
    out="${repo_prefix}${col}${repo_name}${rst}${tail}"

    gittop=$(git -C $gittop/.. rev-parse --show-toplevel 2> /dev/null)
  done
  reporoot=$(repo --show-toplevel 2> /dev/null)
  tail=${out#${reporoot}}
  if [ "$?" == 0 ]; then
    repo_name=${reporoot##*/}
    repo_prefix=${reporoot%$repo_name}
    out="${repo_prefix}${white}${repo_name}${rst}${tail}"
  fi

  echo $out
}

function __prompt_exit_status()
{
  __exit_status="$1"

  if [ "$__exit_status" != "0" ]; then                   # exit status from previous command
    if [ "$__exit_status" -gt 128 ]; then                # find signal name if exit status > 128
      signame=$(2>/dev/null kill -l $((__exit_status - 128)))
      if [ "$?" == "0" ]; then                           # verify that signal name could be found
        M=SIG${signame}
      else
        M=$__exit_status
      fi
    else
      M=$__exit_status
    fi
    echo ' [\[\e[1;31m\]'"$M"'\[\e[0m\]]'
  fi
}

