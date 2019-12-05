#!/bin/bash

_benchmark() {
  local cur prev opts
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"
  opts="--ntimes= --output= --help --verbose --version"

  if [[ ${cur} == -* ]] ; then
      COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
      return 0
  fi
} &&
complete -F _benchmark -o filenames benchmark.sh


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


_files() {
  local cur prev opts
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"
  opts="--help -L -H --keep --size-between --size-bigger --size-smaller \
        --older-than --newer-than --delete"

  if [[ ${cur} == -* ]] ; then
      COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
      return 0
  fi
} &&
complete -F _files -o plusdirs files


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


_repeat() {
  local cur prev opts
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"
  opts="--character= --width= --help --version"

  if [[ ${cur} == -* ]] ; then
      COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
      return 0
  fi
} &&
complete -F _repeat -o nospace repeat


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
} &&
complete -F _rmempty -o dirnames rmempty
