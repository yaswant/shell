#!/usr/bin/env shi
# remove ysh
# yaswant.pradhan
set -e
#TODO: update ysh library install script

PREFIX="${1:-${HOME}/ysh}"
cd && rm -r "$PREFIX"

# get login shell
remove_path='export PATH=$PATH:'$PREFIX
login_shell=${SHELL##*/}

case $login_shell in
  bash)  printf "%s\n%s\n" "Please manually remove the following line from ~/.bash_profile" "$remove_path"
         ;;
  csh)   printf "%s\n%s\n" "Please manually remove the following line from  ~/.cshrc" "$remove_path"
         ;;
  ksh)   printf "%s\n%s\n" "Please manually remove the following line from ~/.kshrc" "$remove_path"
         ;;
  sh)    printf "%s\n%s\n" "Please manually remove the following line from ~/.profile" "$remove_path"
         ;;
  tcsh)  printf "%s\n%s\n" "Please manually remove the following line from ~/.tchrc" "$remove_path"
         ;;
  zsh)   printf "%s\n%s\n" "Please manually remove the following line from ~/.zshrc" "$remove_path"
         ;;
  *)     echo "ysh may not have been in user PATH"
esac

