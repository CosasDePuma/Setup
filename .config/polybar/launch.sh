#!/bin/sh
#  ____   ___   _      __ __  ____    ____  ____
# |    \ /   \ | |    |  |  ||    \  /    ||    \
# |  o  )     || |    |  |  ||  o  )|  o  ||  D  \
# |   _/|  O  || |___ |  ~  ||     ||     ||    /
# |  |  |     ||     ||___, ||  O  ||  _  ||    \
# |  |  |     ||     ||     ||     ||  |  ||  .  \
# |__|   \___/ |_____||____/ |_____||__|__||__|\_|

# Terminate already running instances
killall -q polybar
# Wait until the process have been shut down
while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done
# Launch a new instance
polybar puma &
