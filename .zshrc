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

# Colored man
man() {
    env \
    LESS_TERMCAP_mb=$'\e[01;31m' \
    LESS_TERMCAP_md=$'\e[01;31m' \
    LESS_TERMCAP_me=$'\e[0m' \
    LESS_TERMCAP_se=$'\e[0m' \
    LESS_TERMCAP_so=$'\e[01;44;33m' \
    LESS_TERMCAP_ue=$'\e[0m' \
    LESS_TERMCAP_us=$'\e[01;32m' \
    man "$@"
}

# fzf previews
fzf-lovely(){

	if [ "$1" = "h" ]; then
		fzf -m --reverse --preview-window down:20 --preview '[[ $(file --mime {}) =~ binary ]] &&
 	                echo {} is a binary file ||
	                 (bat --style=numbers --color=always {} ||
	                  highlight -O ansi -l {} ||
	                  coderay {} ||
	                  rougify {} ||
	                  cat {}) 2> /dev/null | head -500'

	else
	        fzf -m --preview '[[ $(file --mime {}) =~ binary ]] &&
	                         echo {} is a binary file ||
	                         (bat --style=numbers --color=always {} ||
	                          highlight -O ansi -l {} ||
	                          coderay {} ||
	                          rougify {} ||
	                          cat {}) 2> /dev/null | head -500'
	fi
}
