# __________  _________ ___ ___
# \____    / /   _____//   |   \
#   /     /  \_____  \/    ~    \
#  /     /_  /        \    Y    /
# /_______ \/_______  /\___|_  /
#         \/        \/       \/

# Fix Java Problem
export _JAVA_AWT_WM_NONREPARENTING=1

# Load the theme
source ~/.config/powerlevel10k/powerlevel10k.zsh-theme
test ! -f ~/.p10k.zsh || source ~/.p10k.zsh

# History
SAVEHIST=1000
HISTFILE=~/.zsh_history

# ==== ALIASES ====

# lsd
alias ls="lsd --group-dirs=first"
alias ll="lsd -l --group-dirs=first"
alias lsa="lsd -A --group-dirs=first"
alias lla="lsd -lA --group-dirs=first"
alias lst="lsd -A --tree"

# bat
alias cat="bat --paging=never"
alias catl="bat"
alias catn="bat -pp"

# python3 as default
alias python="python3"
alias pip="python3 -m pip"

# ==== FUNCTIONS ====

# Prepare folder to pentesting
mkt() { mkdir -p content; mkdir -p exploits; mkdir -p nmap; mkdir -p scripts }

# Remove a file and make it unrecoverable
rmk() { scrub -p dod "${@}"; shred -v -zun 10 "${@}" }
