#!/bin/sh

# ==== ENV ====

CWD="$(pwd)"
TMP="$(mktemp -d)"
REPO="https://raw.githubusercontent.com/CosasDePuma/dotfiles/master/"

# ==== COLORS ====

COLOR_RED="\e[31m"
COLOR_GRE="\e[32m"
COLOR_YEL="\e[33m"
COLOR_BLU="\e[34m"
COLOR_OFF="\e[0m"

# ==== LOGGING ====

log() {
    echo "${COLOR_GRE}[+] Good ${COLOR_OFF}${1}!"
}

info() {
    echo "${COLOR_BLU}[*] Info ${COLOR_OFF}${1}"
}

warning() {
    echo "${COLOR_YEL}[-] Warn ${COLOR_OFF}${1}!"
}

panic() {
    echo "${COLOR_RED}[!] Error ${COLOR_OFF}${1}"
    exit 1
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

# ==== UTILITIES ====

# Change dir if exists
chdir() {
    cd "${1}" || return
}

# Own a directory
own() {
    chown -R "${USER}" "${1}"
}

# Create a directory
makedir() {
    info "Making ${1} directory"
    mkdir -p "${1}"
    own "${1}"
}

# Copu and own files or directories
copy() {
    for last in "${@}"; do :; done
    info "Copying files to ${last}"
    cp "${@}"
    own "${last}"
}

# Nullify outputs and check errors
nullify() {
    "${@}" 1>/dev/null 2>/dev/null || panic "Command \"${*}\" failed"
}

# ==== INSTALLER ====

# Install a program
get() {
    info "Checking ${1}"
    # Check if exists
    if test -n "$(which "${1}")"
    then log "${1} already installed"
    # Install the program
    else
        info "Installing ${1}"
        nullify apt -y install "${1}"
        log "${1} installed"
    fi
    # Check if installed correctly
    checkexe "${1}"
}

# Install a array of programs without checking erros
getdep() {
    for dep in "${@}"
    do
       info "Checking ${dep}"
       nullify apt -y install "${dep}"
       log "${dep} installed"
    done
}

# ==== CHECKERS ====

# Check if a program is installed
checkexe() {
    test -n "$(which "${1}")" || panic "Couldn't find ${1}"
}

# Create and own a file
checkfile() {
    test -f "${1}" || touch "${1}"
    chown "${USER}" "${1}"
}

# ==== CHECK: OS ====

# Only tested on parrot-5.7
test "$(uname -n)" = "parrot" || panic "This script only works in Parrot OS"
test "$(uname -r | cut -d. -f1-2)" = "5.7" || warning "This script was only tested on Parrot OS 7.2"

# ==== UPDATE | UPGRADE ====

# Update and upgrade
info "Updating"
nullify apt -y update

info "Upgrading"
nullify apt -y upgrade

# ==== INSTALL: git ====

# Git is an essential
get git
git config --global credential.helper store

# ==== INSTALL: wget =====

# wget is an essential
get wget

# ==== INSTALL: feh ====

# Background program
get feh

info "Customizing feh"

# Download wallpaper
makedir "${CONFIG}"/feh
nullify wget -q -O "${CONFIG}/feh/wallpaper" "${REPO}/.config/feh/wallpaper"
log "feh successfully customized"

# ==== INSTALL: rofi ====

# Program launcher
get rofi

# ==== INSTALL: polybar ====

# Topbar
info "Installing polybar dependencies"

# Install dependencies
polybardep="build-essential git cmake cmake-data pkg-config python3-sphinx libcairo2-dev libxcb1-dev libxcb-util0-dev libxcb-randr0-dev libxcb-composite0-dev python3-xcbgen xcb-proto libxcb-image0-dev libxcb-ewmh-dev libxcb-icccm4-dev"
# shellcheck disable=SC2086
getdep ${polybardep}
polybaroptdep="libxcb-xkb-dev libxcb-xrm-dev libxcb-cursor-dev libasound2-dev libpulse-dev libjsoncpp-dev libmpdclient-dev libcurl4-openssl-dev libnl-genl-3-dev"
# shellcheck disable=SC2086
getdep ${polybaroptdep}
log "polybar dependencies installed"

# Download polybar
if test -z "$(which polybar)"
then
    info "Downloading polybar"
    chdir "${TMP}"
    nullify wget -q -O "polybar.tar" "https://github.com/polybar/polybar/releases/download/3.4.3/polybar-3.4.3.tar"
    info "Checking polybar sha256"
    test "d4ed121c1d3960493f8268f966d65a94d94c4646a4abb131687e37b63616822f" = "$(sha256sum polybar.tar | cut -d' ' -f1)" || warning "Polybar sha256 does not match"
    nullify tar -xf "polybar.tar"
    chdir "polybar"
    makedir build
    chdir build
    info "Compiling polybar"
    nullify cmake ..
    nullify make -j"$(nproc)"
    nullify make install
    chdir "${CWD}"
fi

# Customizing polybar
info "Customizing polybar"
makedir "${CONFIG}"/polybar
nullify wget -q -O "${CONFIG}/polybar/config" "${REPO}/.config/polybar/config"
nullify wget -q -O "${CONFIG}/polybar/launch.sh" "${REPO}/.config/polybar/launch.sh"
chmod u+x "${CONFIG}"/polybar/launch.sh
makedir "${CONFIG}"/polybar/scripts
nullify wget -q -O "${CONFIG}/polybar/scripts/ip.sh" "${REPO}/.config/polybar/scripts/ip.sh"
chmod u+x "${CONFIG}"/polybar/scripts/ip.sh
log "polybar successfully customized"

# ==== INSTALL: hack nerd fonts ====

# Custom fonts
info "Customizing fonts"
if ! test -d /usr/share/fonts/hacknerd
then
    chdir "${TMP}"
    nullify wget -O "hack.zip" "https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/Hack.zip"
    unzip -o -q -d /usr/share/fonts/hacknerd "hack.zip"
    chdir "${CWD}"
fi
log "hack nerd fonts successfully installed"

# ==== INSTALL: compton ====

# Transparency and blur effects
get compton

# Customize compton
info "Customizing compton"
makedir "${CONFIG}"/compton
nullify wget -q -O "${CONFIG}/compton/comptonrc" "${REPO}/.config/compton/comptonrc"
log "compton successfully customized"

# ==== INSTALL: bspwm ====

# Window Manager and Shortcuts
get bspwm
get sxhkd

# Customize bspwm
info "Customizing bspwm"
makedir "${CONFIG}"/bspwm
nullify wget -q -O "${CONFIG}/bspwm/bspwmrc" "${REPO}/.config/bspwm/bspwmrc"
chmod u+x "${CONFIG}"/bspwm/bspwmrc
makedir "${CONFIG}"/bspwm/scripts
nullify wget -q -O "${CONFIG}/bspwm/scripts/bspwm_resize" "${REPO}/.config/bspwm/scripts/bspwm_resize"
chmod u+x "${CONFIG}"/bspwm/scripts/bspwm_resize
log "bspwm successfully customized"

# Shortcuts
info "Customizing sxhkd"
makedir "${CONFIG}"/sxhkd
nullify wget -q -O "${CONFIG}/sxhkd/sxhkdrc" "${REPO}/.config/sxhkd/sxhkdrc"
log "sxhkd successfully customized"

# xInit
if ! grep -q "exec bspwm" "${HOME}"/.xinitrc
then
    echo "# Execute a customized Window Manager" >> "${HOME}"/.xinitrc
    echo "exec bspwm" >> "${HOME}"/.xinitrc
fi
own "${HOME}"/.xinitrc

# ==== INSTALL: zsh ====

# Terminal
get zsh

# Customize
info "Customizing terminal"
usermod -s /bin/zsh "${USER}" 1>/dev/null 2>/dev/null
usermod -s /bin/zsh root 1>/dev/null 2>/dev/null
nullify wget -q -O "${HOME}/.zshrc" "${REPO}/.zshrc"
nullify ln -s -f "${HOME}/.zshrc" /root/.zshrc
log "Terminal successfully customized"

# ==== INSTALL: powerlevel10k ====

# Terminal Theme
info "Installing powerlevel10k"
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${CONFIG}"/powerlevel10k 1>/dev/null 2>/dev/null
log "Powerlevel10k successfully installed"

# Customize the theme
info "Customizing powerlevel10k"
nullify wget -q -O "${HOME}/.p10k.zsh" "${REPO}/.p10k.zsh"
nullify ln -s -f "${HOME}/.p10k.zsh" /root/.p10k.zsh
log "powerlevel10k successfully customized"

# ==== INSTALL: bat ====

# Cat with wings!
info "Installing bat"
if test -z "$(which bat)"
then
    chdir "${TMP}"
    nullify wget -q -O "bat.deb" "https://github.com/sharkdp/bat/releases/download/v0.15.4/bat_0.15.4_amd64.deb"
    test "66b5fa31e4946da9331824fba4b6a7076565fe83866f14562450a010a5112857" = "$(sha256sum bat.deb | cut -d' ' -f1)" || warning "bat.deb sha256 does not match"
    nullify dpkg -i bat.deb
    chdir "${CWD}"
fi
log "lsd successfully installed"

# ==== INSTALL: lsd ====

# LS Deluxe
info "Installing lsd"
if test -z "$(which lsd)"
then
    chdir "${TMP}"
    nullify wget -q -O "lsd.deb" "https://github.com/Peltoche/lsd/releases/download/0.17.0/lsd_0.17.0_amd64.deb"
    test "ac85771d6195ef817c9d14f8a8a0d027461bfc290d46cb57e434af342a327bb2" = "$(sha256sum lsd.deb | cut -d' ' -f1)" || warning "lsd.deb sha256 does not match"
    nullify dpkg -i lsd.deb
    chdir "${CWD}"
fi
log "lsd successfully installed"

# ==== INSTALL: scrub ====

get scrub

# ==== OWN CONFIG DIRECTORY ====

own "${HOME}/.xinitrc"
own "${HOME}/.zshrc"
own "${HOME}/.p10k.zsh"
own "${CONFIG}"

# ==== ALL DONE! ====

log "All done!"
