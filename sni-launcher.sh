#!/usr/bin/env bash
# GUI launcher for sni-injector using Zenity
# Shows tmux session & proxy status

cd "$(dirname "$0")" || exit 1

SNI_SCRIPT="./run_sni.sh"
SESSION="sni-injector"

# Check if tmux session exists
if tmux has-session -t "$SESSION" 2>/dev/null; then
  TMUX_STATUS="Running"
else
  TMUX_STATUS="Stopped"
fi

# Check if system proxy is set
PROXY_MODE=$(gsettings get org.gnome.system.proxy mode)
if [[ "$PROXY_MODE" == "'manual'" ]]; then
  SOCKS_HOST=$(gsettings get org.gnome.system.proxy.socks host | tr -d "'")
  SOCKS_PORT=$(gsettings get org.gnome.system.proxy.socks port)
  PROXY_STATUS="Enabled ($SOCKS_HOST:$SOCKS_PORT)"
else
  PROXY_STATUS="None"
fi

# Show Zenity dialog with status
CHOICE=$(zenity --width=400 --height=220 --list --radiolist \
  --title="SNI Injector Launcher" \
  --text="SNI Injector Status:\n\nTmux session: $TMUX_STATUS\nSystem proxy: $PROXY_STATUS\n\nFor Logs: tmux attach -t sni-injector\n\nChoose an action:" \
  --column="Select" --column="Action" \
  TRUE "Start" FALSE "Stop" \
  --separator=":")

# handle cancel
if [ -z "$CHOICE" ]; then
  exit 0
fi

# map choice to action
if [[ "$CHOICE" == *Start* ]]; then
  ACTION="start"
elif [[ "$CHOICE" == *Stop* ]]; then
  ACTION="stop"
else
  exit 0
fi

# Run the actual script
if [[ "$ACTION" == "start" ]]; then
  SOCKS_PORT=1080
  "$SNI_SCRIPT" start "$SOCKS_PORT"
elif [[ "$ACTION" == "stop" ]]; then
  "$SNI_SCRIPT" stop
fi


