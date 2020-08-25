#!/bin/sh

# ==== ENV ====

CWD="$(pwd)"
TMP="$(mktemp -d)"
FILPATH="$(readlink -f "${0}")"
DIRPATH="$(dirname "${FILPATH}")"

COMMIT="a1b59a29a0aa8b8cfd766bf674660c3624117603"
REPO=""

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

nullify() {
    "${@}" 1>/dev/null 2>/dev/null || panic "Command \"${*}\" failed"
}

# ==== INSTALLER ====

get() {
    info "Checking ${1}"
    if test -n "$(which "${1}")"
    then log "${1} already installed"
    else
        info "Installing ${1}"
        nullify apt -y install "${1}"
        log "${1} installed"
    fi
    checkexe "${1}"
}

getdep() {
    for dep in "${@}"
    do
       info "Checking ${dep}"
       nullify apt -y install "${dep}"
       log "${dep} installed"
    done
}

# ==== CHECKERS ====

checkexe() {
    test -n "$(which "${1}")" || panic "Couldn't find ${1}"
}

checkfile() {
    test -f "${1}" || touch "${1}"
    chown "${USER}" "${1}"
}

# ==== UTILITIES ====

chdir() {
    cd "${1}" || return
}

own() {
    chown -R "${USER}" "${1}"
}

makedir() {
    info "Making ${1} directory"
    mkdir -p "${1}"
    own "${1}"
}

copy() {
    for last in "${@}"; do :; done
    info "Copying files to ${last}"
    cp "${@}"
    own "${last}"
}

# ==== CHECK: OS ====

test "$(uname -n)" = "parrot" || panic "This script only works in Parrot OS"
test "$(uname -r | cut -d. -f1-2)" = "5.7" || warning "This script was only tested on Parrot OS 7.2"

# ==== CHECK: ROOT ===

test "$(id -u)" = "0" || panic "This script needs root permissions"

if test -n "${SUDO_USER}"
then
    USER="${SUDO_USER}"
    HOME=$(eval echo ~"${SUDO_USER}")
fi

CONFIG="${HOME}/.config"

# ==== UPDATE | UPGRADE ====

info "Updating"
nullify apt -y update

info "Upgrading"
nullify apt -y upgrade

# ==== INSTALL: git ====

get git
git config --global credential.helper store

# ==== INSTALL: wget =====

get wget

# ==== INSTALL: feh ====

get feh

info "Customizing feh"
wallpaper=$(find "${DIRPATH}" -name "wallpaper*" -type f | head -n 1)
if test -z "${wallpaper}"
then
	wallpaper="${TMP}/wallpaper.jpg"
	nullify wget -q -O "${wallpaper}" "https://gist.githubusercontent.com/CosasDePuma/1e85ffa318dc335f7dfb7bed318d32d7/raw/${COMMIT}/wallpaper.jpg"
fi
makedir "${HOME}"/.config/feh
copy "${wallpaper}" "${HOME}"/.config/feh/wallpaper
rm -f "${wallpaper}" 1>/dev/null 2>/dev/null
log "feh successfully customized"

# ==== INSTALL: rofi ====

get rofi

# ==== INSTALL: polybar ====

info "Installing polybar dependencies"
polybardep="build-essential git cmake cmake-data pkg-config python3-sphinx libcairo2-dev libxcb1-dev libxcb-util0-dev libxcb-randr0-dev libxcb-composite0-dev python3-xcbgen xcb-proto libxcb-image0-dev libxcb-ewmh-dev libxcb-icccm4-dev"
# shellcheck disable=SC2086
getdep ${polybardep}
polybaroptdep="libxcb-xkb-dev libxcb-xrm-dev libxcb-cursor-dev libasound2-dev libpulse-dev libjsoncpp-dev libmpdclient-dev libcurl4-openssl-dev libnl-genl-3-dev"
# shellcheck disable=SC2086
getdep ${polybaroptdep}
log "Polybar dependencies installed"

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
    #nullify make userconfig
    chdir "${CWD}"
fi

info "Customizing polybar"
makedir "${HOME}"/.config/polybar
cat > "${HOME}"/.config/polybar/launch.sh << POLYBAR
#!/bin/sh
#  ____   ___   _      __ __  ____    ____  ____
# |    \\ /   \\ | |    |  |  ||    \\  /    ||    \\
# |  o  )     || |    |  |  ||  o  )|  o  ||  D  \\
# |   _/|  O  || |___ |  ~  ||     ||     ||    /
# |  |  |     ||     ||___, ||  O  ||  _  ||    \\
# |  |  |     ||     ||     ||     ||  |  ||  .  \\
# |__|   \\___/ |_____||____/ |_____||__|__||__|\\_|

# Terminate already running instances
killall -q polybar
# Wait until the process have been shut down
while pgrep -u \$UID -x polybar >/dev/null; do sleep 1; done
# Launch a new instance
polybar puma &
POLYBAR
chmod u+x "${HOME}"/.config/polybar/launch.sh

cat > "${HOME}"/.config/polybar/config << CONFIG
;==========================================================
; ██████╗  ██████╗ ██╗  ██╗   ██╗██████╗  █████╗ ██████╗
; ██╔══██╗██╔═══██╗██║  ╚██╗ ██╔╝██╔══██╗██╔══██╗██╔══██╗
; ██████╔╝██║   ██║██║   ╚████╔╝ ██████╔╝███████║██████╔╝
; ██╔═══╝ ██║   ██║██║    ╚██╔╝  ██╔══██╗██╔══██║██╔══██╗
; ██║     ╚██████╔╝███████╗██║   ██████╔╝██║  ██║██║  ██║
; ╚═╝      ╚═════╝ ╚══════╝╚═╝   ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝
;==========================================================

[colors]
background = #222
background-alt = #444
foreground = #dfdfdf
foreground-alt = #555
primary = #ffb52a
alert = #bd2c40

[bar/puma]
width = 100%
height = 37

font-0 = Hack Nerd Font Mono:pixelsize=12;2
background = \${colors.background}
foreground = \${colors.foreground}

radius = 6.0
fixed-center = false
line-size = 3
line-color = #f00
border-size = 4
border-color = #00000000
padding-left = 0
padding-right = 2
module-margin-left = 1
module-margin-right = 2
tray-padding = 2
tray-position = right

modules-left = bspwm
modules-center = xwindow
modules-right = wlan vpn pulseaudio cpu battery date

wm-restack = bspwm
scroll-up = bspwm-desknext
scroll-down = bspwm-deskprev
cursor-click = pointer
cursor-scroll = ns-resize

[module/bspwm]
type = internal/bspwm

label-focused = 
label-focused-padding = 2
label-focused-background = \${colors.background-alt}

label-occupied = 
label-occupied-padding = 2

label-urgent = 
label-urgent-padding = 2
label-urgent-background = \${colors.alert}

label-empty = 
label-empty-padding = 2
label-empty-foreground = \${colors.foreground-alt}

[module/xwindow]
type = internal/xwindow
label = %title:0:30:...%

[module/cpu]
type = internal/cpu
interval = 2
label = %percentage:2%%

[module/wlan]
type = custom/script
exec = nm-applet

[module/date]
type = internal/date
interval = 5
date =
date-alt = " %d-%m-%Y"
time = %H:%M
time-alt = %H:%M:%S
label = %date% %time%

[module/pulseaudio]
type = internal/pulseaudio
format-volume = <label-volume> <bar-volume>
label-volume = 蓼
label-volume-foreground = \${root.foreground}
label-muted = 遼
label-muted-foreground = #666
bar-volume-width = 10
bar-volume-foreground-0 = #55aa55
bar-volume-foreground-1 = #55aa55
bar-volume-foreground-2 = #55aa55
bar-volume-foreground-3 = #55aa55
bar-volume-foreground-4 = #55aa55
bar-volume-foreground-5 = #f5a70a
bar-volume-foreground-6 = #ff5555
bar-volume-gradient = false
bar-volume-indicator = |
bar-volume-indicator-font = 2
bar-volume-fill = ─
bar-volume-fill-font = 2
bar-volume-empty = ─
bar-volume-empty-font = 2
bar-volume-empty-foreground = \${colors.foreground-alt}

[module/battery]
type = internal/battery
battery = BAT0
adapter = ADP1
full-at = 99
format-charging = <label-charging>
format-discharging = <label-discharging>
label-charging =  %percentage%%
label-discharging =  %percentage%%

[module/vpn]
type = custom/script
exec = ~/.config/polybar/scripts/ip.sh
interval = 10

[settings]
screenchange-reload = true

[global/wm]
margin-top = 5
margin-bottom = 5

; vim:ft=dosini
CONFIG
makedir "${HOME}"/.config/polybar/scripts
cat > "${HOME}"/.config/polybar/scripts/ip.sh << POLYBARSH
#!/bin/sh

if test -n "\$(/usr/sbin/ifconfig | grep tun0 | awk '{ print \$1 }' | tr -d ':' )"
then iface="tun0"
else iface="wlan0"
fi

address="\$(/usr/sbin/ifconfig \${iface} | grep inet | awk '{ print \$2 }')"
if test -z "\${address}"
then address="-"
fi

echo " \${address}"
POLYBARSH
chmod u+x "${HOME}"/.config/polybar/scripts/ip.sh
own "${HOME}"/.config/polybar

log "polybar successfully customized"

# ==== INSTALL: hack nerd fonts ====

info "Customizing fonts"
chdir "${TMP}"
nullify wget -O "hack.zip" "https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/Hack.zip"
unzip -o -q -d /usr/share/fonts/hacknerd "hack.zip"
chdir "${CWD}"
log "hack nerd fonts successfully installed"

# ==== INSTALL: compton ====

get compton

info "Customizing compton"
test -d "${HOME}"/.config/compton || makedir "${HOME}"/.config/compton
cat > "${HOME}"/.config/compton/comptonrc << COMPTON
#  _____               _
# |     |___ _____ ___| |_ ___ ___
# |   --| . |     | . |  _| . |   |
# |_____|___|_|_|_|  _|_| |___|_|_|
#                |_|
#

active-opacity = 0.95;
inactive-opacity = 0.80;
frame-opacity = 0.80;

backend = "glx";

opacity-rule = [
  "99:class_g = 'Atom'",
	"99:class_g = 'burp-StartBurp'",
	"80:class_g = 'Caja'",
	"99:class_g = 'Code'",
	"99:class_g = 'Firefox'",
	"99:class_g = 'Google-chrome'",
	"80:class_g = 'Rofi'"
];

blur-background = true;
COMPTON
own "${HOME}"/.config/compton
log "compton successfully customized"

# ==== INSTALL: bspwm ====

get bspwm
checkexe sxhkd

# Window Manager
info "Customizing bspwm"
test -d "${HOME}"/.config/bspwm || makedir "${HOME}"/.config/bspwm
cat > "${HOME}"/.config/bspwm/bspwmrc << BSPWM
#! /bin/sh
#  ____ ____ ____ ____ ____
# ||B |||S |||P |||W |||M ||
# ||__|||__|||__|||__|||__||
# |/__\|/__\|/__\|/__\|/__\|
#

# --- Custom ---

# Init shortcuts
sxhkd &
# Fix Java errors with bspwm
wname LG3D &
# Polybar
${HOME}/.config/polybar/launch.sh &
# Background
feh --bg-fill ${HOME}/.config/feh/wallpaper
# Transparency
compton --config ${HOME}/.config/compton/comptonrc &

# Windows Key as modifier
bscp config pointer_modifier mod1

# Programs as Floating Windows
bspc rule -a Caja desktop='^8' state=floating follow=on
bspc rule -a Gimp desktop='^8' state=floating follow=on

# --- Default ---

bspc monitor -d I II III IV V VI VII VIII IX X

bspc config border_width         2
bspc config window_gap          12

bspc config split_ratio          0.52
bspc config borderless_monocle   true
bspc config gapless_monocle      true
BSPWM
chmod u+x "${HOME}"/.config/bspwm/bspwmrc

# Shortcuts
info "Customizing sxhkd"
test -d "${HOME}"/.config/sxhkd || makedir "${HOME}"/.config/sxhkd
cat > "${HOME}"/.config/sxhkd/sxhkdrc << SHORTCUTS
# ███████╗██╗  ██╗ ██████╗ ██████╗ ████████╗ ██████╗██╗   ██╗████████╗███████╗
# ██╔════╝██║  ██║██╔═══██╗██╔══██╗╚══██╔══╝██╔════╝██║   ██║╚══██╔══╝██╔════╝
# ███████╗███████║██║   ██║██████╔╝   ██║   ██║     ██║   ██║   ██║   ███████╗
# ╚════██║██╔══██║██║   ██║██╔══██╗   ██║   ██║     ██║   ██║   ██║   ╚════██║
# ███████║██║  ██║╚██████╔╝██║  ██║   ██║   ╚██████╗╚██████╔╝   ██║   ███████║
# ╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝   ╚═╝    ╚═════╝ ╚═════╝    ╚═╝   ╚══════╝

# ----------------------------------------------------
# Programs
#	Win + B                 BurpSuite
#	Win + G                 Google Chrome
#	Win + R                 Launcher
#	Win + Enter             Terminal
# ----------------------------------------------------
# Utilities
#	Win + F                 Toggle Fullscreen
#	Win + M                 Toggle Main Node
#	Win + S                 Toggle Node State
#	Win + W                 Close & Kill
#	Win + Arrows            Change Node
#	Win + Ctrl + Arrows     Move Floating Window
#	Win + Escape            Close Session
#	Win + Tab,
#	Alt + Tab               Next Node
# ----------------------------------------------------

# ----------------------------------------------------
#  Programs
# ----------------------------------------------------

# Program Launcher
super + r
	rofi -show run

# Terminal
super + Return
	gnome-terminal

# Google Chrome
super + g
	google-chrome

# BurpSuite
super + b
	gksudo burp

# ----------------------------------------------------
#  Utilities
# ----------------------------------------------------

# Close Session
super + Escape
	kill -9 -1

# Close and Kill
super + w
	bspc node -c

# Alternate Full Screen
super + f
	bspc desktop -l next

# Change Window State
super + s
	bspc node -t {tiled,floating}

# Current Node as Main Node
super + m
	bspc node -s biggest

# Change Node
super + {Left,Down,Up,Right}
	bspc node -f {west,south,north,east}

# Focus Next Node
{super,alt} + Tab
	bspc node -f next.local

# Focus the Given Desktop
super + {1-9,0}
	bspc desktop -f '^{1-9,10}'

# Send to the Given Desktop
super + shift + {1-9,0}
	bspc node -d '^{1-9,10}'

# Move a Floating Window
super + ctrl + {Left,Down,Up,Right}
	bspc node -v {-20 0,0 20,0 -20,20 0}

# Resize Current Window
super + shift + {Left,Down,Up,Right}
	/home/puma/.config/bspwm/scripts/bspwm_resize {west,south,north,east}
SHORTCUTS

# Scripts
test -d "${HOME}"/.config/bspwm/scripts || makedir "${HOME}"/.config/bspwm/scripts
cat > "${HOME}"/.config/bspwm/scripts/bspwm_resize << SCRIPT
#!/usr/bin/env dash

if bspc query -N -n focused.floating > /dev/null; then
	step=20
else
	step=100
fi

case "\$1" in
	west) dir=right; falldir=left; x="-\$step"; y=0;;
	east) dir=right; falldir=left; x="\$step"; y=0;;
	north) dir=top; falldir=bottom; x=0; y="-\$step";;
	south) dir=top; falldir=bottom; x=0; y="\$step";;
esac

bspc node -z "\$dir" "\$x" "\$y" || bspc node -z "\$falldir" "\$x" "\$y"
SCRIPT
chmod u+x "${HOME}"/.config/bspwm/scripts/bspwm_resize

# xInit
if ! grep -q "exec bspwm" "${HOME}"/.xinitrc
then
    echo "# Execute a customized Window Manager" >> "${HOME}"/.xinitrc
    echo "exec bspwm" >> "${HOME}"/.xinitrc
fi

# Checks
checkfile "${HOME}"/.xinitrc
own "${HOME}"/.config/bspwm/
log "bspwm successfully customized"
own "${HOME}"/.config/sxhkd/
log "sxhkd successfully customized"

# ==== ZSH ====

get zsh

# ==== POWERLEVEL10K ====

info "Installing Powerlevel10k"
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${HOME}"/.config/powerlevel10k 1>/dev/null 2>/dev/null
echo "# ZSH Configuration" > "${HOME}"/.zshrc
echo 'source ~/.config/powerlevel10k/powerlevel10k.zsh-theme' >> "${HOME}"/.zshrc
info "Customizing Powerlevel10k"
nullify wget -q -O "${HOME}/.p10k.zsh" "https://gist.githubusercontent.com/CosasDePuma/1e85ffa318dc335f7dfb7bed318d32d7/raw/${COMMIT}/.p10k.zsh"
log "Powerlevel10k successfully installed and customized"

# ==== ALL DONE! ====

log "All done!"

# Time 1:33
