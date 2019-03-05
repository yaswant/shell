#!/usr/bin/env shi
# install ysh
# yaswant.pradhan
set -e
#TODO: update ysh library install script

PREFIX="${1:-${HOME}/ysh}"
mkdir -p "$PREFIX"
cp * "$PREFIX"

# get login shell
login_shell=${SHELL##*/}
append_path='export PATH=$PATH:'$PREFIX

case $login_shell in
  bash)  echo $append_path >> ~/.bash_profile
         ;;
  csh)   echo $append_path >> ~/.cshrc
         ;;
  ksh)   echo $append_path >> ~/.kshrc
         ;;
  sh)    echo $append_path >> ~/.profile
         ;;
  tcsh)  echo $append_path >> ~/.tchrc
         ;;
  zsh)   echo $append_path >> ~/.zshrc
         ;;
  *)     echo "Can't guess the login shell"
esac

