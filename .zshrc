# History
# ----------
HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=1000

# Options
# ----------
setopt autocd extendedglob nomatch notify
unsetopt beep

# Prompt
# ----------
autoload -U promptinit; promptinit
prompt spaceship
