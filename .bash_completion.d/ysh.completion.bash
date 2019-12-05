#!/bin/bash

_files() {
  local cur prev opts
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"
  opts="--help -H -L --keep --bigger= --smaller= --older= --newer= --delete"

  if [[ ${cur} == -* ]] ; then
      COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
      return 0
  fi
} &&
complete -F _files -o default files


_caldat() {
  local cur prev opts
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"
  opts="--format= --help --verbose --version"

  if [[ ${cur} == -* ]] ; then
      COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
      return 0
  fi
} &&
complete -F _caldat -o nospace caldat


_julday() {
  local cur prev opts
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"
  opts="--format= --time= --help --verbose --version"

  if [[ ${cur} == -* ]] ; then
      COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
      return 0
  fi
} &&
complete -F _julday -o nospace julday


_rmempty() {
  local cur prev opts
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"
  opts="-atime -ctime -daystart --dir --file --ignore --level \
        --dry-run -mtime --verb --version --broken-link --help"

  if [[ ${cur} == -* ]] ; then
      COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
      return 0
  fi
}
complete -F _rmempty -o dirnames rmempty
