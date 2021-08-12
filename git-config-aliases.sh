#!/bin/bash -e

# Include useful git aliases (global) to user profile
# yaswant.pradhan

git config --global alias.ac "!git add . && git commit -am"
git config --global alias.acp "!f() { git add -A && git commit -m \"\$@\" && git push; }; f"
git config --global alias.alias "config --get-regexp ^alias."
git config --global alias.br 'branch'
git config --global alias.branchdate "!git for-each-ref --sort='-committerdate:iso8601' --format='%(committerdate:short)|%(committerdate:relative)|%(refname:short)|%(committername)' refs/heads/ | column -s '|' -t"
git config --global alias.branchdate-remote "!git for-each-ref --sort='authordate' --format='%(committerdate:short)|%(committerdate:relative)|%(refname:short)|%(committername)' refs/remotes/ | column -s '|' -t"
git config --global alias.ci 'commit'
git config --global alias.co 'checkout'
git config --global alias.cob 'checkout -b'
git config --global alias.filter "config --get-regexp ^filter."
git config --global alias.last 'log -1 HEAD'
git config --global alias.logg 'log --all --decorate --oneline --graph'
git config --global alias.lsr "!gls() { ls -aR \$(readlink -ev \${1:-\`pwd\`}) 2>/dev/null | grep --color=none -oP '.*?(?=/.git:)' || printf 'No repos found in current directory\n' ; }; gls"
git config --global alias.list-repos "!gls() { ls -aR \$(readlink -ev \${1:-\`pwd\`}) 2>/dev/null | grep --color=none -oP '.*?(?=/.git:)' || printf 'No repos found in current directory\n' ; }; gls"
git config --global alias.rpull "!grp() { find -maxdepth \${1:-2} -type d -name .git -printf '%-20h ' -execdir git pull \\;; }; grp"
git config --global alias.st 'status'
git config --global alias.unstage 'reset HEAD --'
git config --global alias.remote-repos "!grr() { curl -s https://api.github.com/users/\${1:-$(git config --get user.name)}/repos?per_page=100 | grep -oP '(?<=clone_url\": \").*(?=\",)' ; }; grr"

# personal trial
# git config --global alias.traffic "!gtr() { curl -H \"Authorization: token \$(grep -m 1 \${1:-`git config --get user.name`} ~/.git-credentials | awk -F':|@' '{print \$3}')\" https://api.github.com/repos/\${1:-`git config --get user.name`}/\${2:-ypylib}/traffic/clones; }; gtr"
