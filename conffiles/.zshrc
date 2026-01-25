# ~/.zshrc: oh-my-zsh configuration
# Migrated from bash configuration with eternal history preserved

# Path to oh-my-zsh installation
export ZSH="$HOME/.oh-my-zsh"

# Theme - minimal and fast, shows git branch like your bash prompt
# Options: robbyrussell (default, fast), agnoster (more info), pure (minimal)
ZSH_THEME="robbyrussell" # set by `omz`

# Plugins - minimal and efficient
# Ordered for optimal loading
plugins=(
  git                   # Git aliases and completion
  ssh-agent             # Manages ssh-agent automatically
  colored-man-pages     # Colorized man pages
  command-not-found     # Suggests packages for missing commands
  extract               # Universal extractor: 'x file.tar.gz'
  z                     # Jump to frequent directories
  history               # History aliases (h, hsi, etc.)
  docker                # Docker completions
  docker-compose        # Docker-compose completions
  python                # Python-specific completions
  pip                   # pip completions
  timer                 # adding a timer to longer executions
  virtualenv            # Virtualenv prompt info
  zsh-autosuggestions   #
)

# SSH agent plugin configuration
# Replaces manual .ssh-agent sourcing
zstyle :omz:plugins:ssh-agent agent-forwarding no
zstyle :omz:plugins:ssh-agent quiet yes
zstyle :omz:plugins:ssh-agent lifetime 12h  # 43200 seconds from your keyon alias

# Show timer only if command takes more than 1 second
export TIMER_THRESHOLD=5

# Optional: Adjust precision (number of decimal places, default is 1)
export TIMER_PRECISION=1


# Load oh-my-zsh
source $ZSH/oh-my-zsh.sh

# ============================================================================
# Environment Variables (from .bashenv)
# ============================================================================

export HOSTNAME=$(hostname -s)
export TERM=xterm-256color  # Upgraded from xterm-color for better color support

export LESS="-R -deiP--- File\: ?f{%f}:{PIPE}. -- [?eeof:?pB%pB\%:input..] -- [%i/%m] -- ?ltLine\: %lt:no line count. ---"
export PGPPATH=~/.pgp
export PAGER="less"
export VISUAL="emacs -nw"
export EDITOR="emacs -nw"

export PERL5LIB="$HOME/workspace/dbmanagement"
export R_HISTSIZE=100000

# One-line fix: properly wraps variables and colors to prevent wrapping
ret_status='%(?:%{$fg_bold[green]%}➜ :%{$fg_bold[red]%}➜ )'
PROMPT='%{$fg[white]%}[%D{%Y%m%d %H:%M:%S}]%{$reset_color%} %{${ret_status}%} %{$fg[cyan]%}%c%{$reset_color%} $(git_prompt_info) '
# ============================================================================
# History Configuration
# ============================================================================

# Standard zsh history
HISTFILE=~/.zsh_history
HISTSIZE=100000
SAVEHIST=100000

# History options
setopt EXTENDED_HISTORY          # Write timestamp to history (format: : <beginning time>:<elapsed seconds>;<command>)
setopt INC_APPEND_HISTORY        # Append immediately, not on exit
setopt SHARE_HISTORY             # Share history across all sessions
setopt HIST_IGNORE_DUPS          # Don't record duplicates consecutively
setopt HIST_FIND_NO_DUPS         # Don't show duplicates in search
setopt HIST_IGNORE_SPACE         # Don't record commands starting with space
setopt HIST_REDUCE_BLANKS        # Remove superfluous blanks
setopt HIST_VERIFY               # Show command with history expansion before running

# Eternal history configuration (preserves your bash eternal history pattern)
# This creates a separate comprehensive log file similar to .bash_eternal_history
ETERNAL_HISTORY_FILE="$HOME/.zsh_eternal_history"

# Function to log to eternal history
# Format: [YYYY-MM-DD HH:MM:SS] PID HOSTNAME USER COMMAND
log_eternal_history() {
  local cmd_line
  # Get the last command from history
  cmd_line=$(fc -ln -1)
  # Write to eternal history with timestamp, PID, hostname, user, and command
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $$ $HOSTNAME $USER $cmd_line" >> "$ETERNAL_HISTORY_FILE"
}

# Hook to log every command to eternal history
precmd_functions+=(log_eternal_history)

# ============================================================================
# Aliases (from .bash_aliases)
# ============================================================================

# File operations
alias edclean="rm -f *~"
alias copy="cp"
alias rm="rm -i"
alias mv="mv -i"
alias cp="cp -i"

# Compression
alias gz="gzip -best"
alias guz="gunzip"

# Editor
alias vi="vim"

# System
alias f="finger"
alias sb="source ~/.zshrc"  # Changed from .bashrc

# Directory listings (zsh has better defaults, but keeping for compatibility)
alias dir="ls -alg"
alias ll='ls -l'
alias la='ls -A'
alias l='ls -CF'
alias lsn="/bin/ls"  # Unaliased ls
alias dirn="/bin/ls -alg"

# SSH key management
alias keyon='ssh-add -t 43200'
alias keyoff='ssh-add -D'
alias keylist='ssh-add -l'

# Screen with proper TERM
alias screen="TERM=screen screen"

# ============================================================================
# Completion Configuration
# ============================================================================

# Enable completion features (oh-my-zsh already does this, but being explicit)
autoload -Uz compinit
compinit

# Case-insensitive completion
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# Colored completion (use LS_COLORS)
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# ============================================================================
# Color Support
# ============================================================================

# Enable color support for ls (oh-my-zsh handles this, but ensuring it's set)
if [[ -x /usr/bin/dircolors ]]; then
  test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
fi

# ls colors
alias ls='ls --color=auto -F'

# ============================================================================
# Window Title (from .bashrc PROMPT_COMMAND)
# ============================================================================

# Set terminal title to user@host:dir
case "$TERM" in
  xterm*|rxvt*|screen*)
    set_window_title() {
      print -Pn "\e]0;%n@%m: %~\a"
    }
    precmd_functions+=(set_window_title)
    ;;
esac

# ============================================================================
# Optional Enhancements
# ============================================================================

# fzf integration (if installed)
# Provides fuzzy search for history (Ctrl+R), files (Ctrl+T), directories (Alt+C)
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Key bindings for more bash-like behavior
# Use emacs-style key bindings (since you use emacs as editor)
bindkey -e

# ============================================================================
# Custom Functions
# ============================================================================

# Make completion work with sudo
# Allows: sudo <tab> to complete commands as if you weren't using sudo
zstyle ':completion::complete:*' gain-privileges 1

# just completion (justfile task runner)
# Generates completion file automatically if just is installed
if command -v just &> /dev/null; then
  # Ensure completions directory exists
  [[ -d "$ZSH/completions" ]] || mkdir -p "$ZSH/completions"

  # Generate completion if not already present
  if [[ ! -f "$ZSH/completions/_just" ]]; then
    just --completions zsh > "$ZSH/completions/_just"
  fi
fi

# ============================================================================
# Performance Optimizations
# ============================================================================

# Disable auto-update check (reduces startup time)
# You can manually update with: omz update
DISABLE_AUTO_UPDATE="true"

# Uncomment to disable bi-weekly update checks
# DISABLE_UPDATE_PROMPT="true"

# ============================================================================
# Additional Notes
# ============================================================================

# Migration checklist:
# 1. Install oh-my-zsh: sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
# 2. Copy this file to ~/.zshrc
# 3. Optional: Install fzf for fuzzy search: sudo apt install fzf (or appropriate package manager)
# 4. Optional: Install zsh-autosuggestions:
#    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
#    Then add 'zsh-autosuggestions' to plugins array above
# 5. Remove or comment out .ssh-agent sourcing from crontab (handled by ssh-agent plugin)
# 6. Change default shell: chsh -s $(which zsh)

# Your eternal history is preserved at ~/.zsh_eternal_history
# Format: [YYYY-MM-DD HH:MM:SS] PID HOSTNAME USER COMMAND
# Same format as your bash eternal history for easy compatibility

# To search eternal history:
# grep "search_term" ~/.zsh_eternal_history
# Or create an alias:
# alias hsearch='grep -i ~/.zsh_eternal_history'
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.opencode/bin:$PATH"
eval "$("$HOME/.local/bin/mise" activate zsh)"

# opencode
