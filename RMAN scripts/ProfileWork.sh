alias ll='ls -ltr'
alias la='ls -la'
alias lc='ls -l|wc -l'
alias d1='df -h'
alias d2='du -sh *|sort -nr'
alias sud='sudo su - oracle'
PATH=$PATH\:/dir/path:/usr/local/bin; export PATH
PS1="\H \w >"
set -o vi
stty erase ^H
umask 027