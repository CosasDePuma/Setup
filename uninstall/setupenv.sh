#!/bin/sh

# ==== PROGRAMS ====

programs="bspwm compton polybar scrub sxhkd"

# ==== COLORS ====

COLOR_RED="\e[31m"
COLOR_GRE="\e[32m"
COLOR_YEL="\e[33m"
COLOR_OFF="\e[0m"

# ==== LOGGING ====

log() {
    echo "${COLOR_GRE}[+] Good ${COLOR_OFF}${1}!"
}

warning() {
    echo "${COLOR_YEL}[-] Warn ${COLOR_OFF}${1}!"
}

error () {
    echo "${COLOR_RED}[!] Error ${COLOR_OFF}${1}"
}

panic() {
    error "${1}"
    exit 1
}

# ==== UTILS ====

# Iterate over programs
iter() {
  # s_hellcheck disable=SC2086
  for program in $programs
  do
    command=$(echo "${*}" | sed "s/%%/${program}/")
    /bin/sh -c "${command} 1>/dev/null 2>/dev/null"
  done
}

# ==== CHECK: ROOT ===

test "$(id -u)" = "0" || panic "This script needs root permissions"

# Get real user and home directory
if test -n "${SUDO_USER}"
then
    USER="${SUDO_USER}"
    HOME=$(eval echo ~"${SUDO_USER}")
fi

# ==== CONFIG DIR ====

# Config directory
CONFIG="${HOME}/.config"

# ==== REMOVE CUSTOM FONTS ====

warning "Removing custom fonts"
rm -rf /usr/share/fonts/hacknerd

# ==== REMOVE CONFIG FILES ====

warning "Removing config files"
rm -f "${HOME}"/.zsh* "${HOME}"/.p10k.zsh /root/.zsh* /root/.p10k.zsh
rm -rf "${CONFIG}"/feh "${CONFIG}"/powerlevel10k
iter rm -rf "${CONFIG}"/%%

# ==== REMOVE PROGRAMS ====

warning "Uninstalling programs"
iter apt -y purge %%
apt -y purge bat feh lsd rofi zsh 1>/dev/null 2>/dev/null

# ==== REMOVE SYSTEM DIRECTORIES ====

warning "Removing system directories with junk"
iter "find /etc -name \"*%%*\" -exec rm -r {} +"
iter "find /usr -name \"*%%*\" -exec rm -r {} +"
iter "find /var -name \"*%%*\" -exec rm -r {} +"

# ==== REMOVE LINKS ====

warning "Removing links"

sed -i '/# Execute a customized Window Manager/d' "${HOME}"/.xinitrc
sed -i '/exec bspwm/d' "${HOME}"/.xinitrc

usermod -s /bin/bash "${USER}" 1>/dev/null 2>/dev/null
usermod -s /bin/bash root 1>/dev/null 2>/dev/null

# ==== ALL DONE ====

log "Successfully uninstalled"
