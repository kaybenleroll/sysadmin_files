alias edclean="rm -f *~"
alias f="finger"
alias dir="ls -alg"
alias dirn="lsn -alg"
alias ls="ls --color=auto -F"
alias lsn="/bin/ls"
alias copy="cp"
alias gz="gzip -best"
alias guz="gunzip"
alias sb="source ~/.bashrc"
alias vi="vim"
alias rm="rm -i"
alias mv="mv -i"
alias cp="cp -i"

alias screen="TERM=screen screen"


# enable color support of ls and also add handy aliases                                                                                                                             
if [ "$TERM" != "dumb" ]; then
    eval "`dircolors -b`"
    alias ls='ls --color=auto'
    alias dir='ls --color=auto --format=vertical'
    alias vdir='ls --color=auto --format=long'
fi

# some more ls aliases                                                                                                                                                              
alias ll='ls -l'
alias la='ls -A'
alias l='ls -CF'

# enable programmable completion features (you don't need to enable                                                                                                                 
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile                                                                                                                
alias keyon='ssh-add -t 43200'
alias keyoff='ssh-add -D'
alias keylist='ssh-add -l'



