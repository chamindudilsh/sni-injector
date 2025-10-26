#!/usr/bin/env bash
# run_sni.sh — start/stop sni-injector in one tmux session and toggle system+env proxy
# Usage:
#   ./run_sni.sh start
#   ./run_sni.sh stop

set -eo pipefail

cd "$(dirname "$0")" || exit 1

SESSION="sni-injector"
SOCKS_HOST="127.0.0.1"
SOCKS_PORT=1080
ACTION="$1"

PYTHON_BIN="python3"       # change to ./venv/bin/python if you use venv
MAIN_PY="./main.py"
SSH_SH="./ssh.sh"

# --- helper: GUI proxy ---
set_system_socks_proxy() {
  local host="$1"
  local port="$2"
  echo "Setting system proxy (GUI) to SOCKS ${host}:${port}..."
  gsettings set org.gnome.system.proxy mode 'manual'
  gsettings set org.gnome.system.proxy.socks host "${host}"
  gsettings set org.gnome.system.proxy.socks port "${port}"
}

clear_system_proxy() {
  echo "Clearing system proxy (GUI)..."
  gsettings set org.gnome.system.proxy mode 'none'
  gsettings reset org.gnome.system.proxy.socks host || true
  gsettings reset org.gnome.system.proxy.socks port || true
}

# --- helper: env vars ---
export_proxy_envs() {
  local host="$1" port="$2"
  local socks_uri="socks5h://${host}:${port}"
  export ALL_PROXY="$socks_uri"
  export all_proxy="$socks_uri"
  export HTTP_PROXY="$socks_uri"
  export http_proxy="$socks_uri"
  export HTTPS_PROXY="$socks_uri"
  export https_proxy="$socks_uri"
  echo "Exported proxy env vars for this shell."
}

unset_proxy_envs() {
  unset ALL_PROXY all_proxy HTTP_PROXY http_proxy HTTPS_PROXY https_proxy || true
  echo "Unset proxy environment variables."
}

# --- tmux launcher ---
start_tmux() {
  if tmux has-session -t "${SESSION}" 2>/dev/null; then
    echo "tmux session '${SESSION}' already running — attaching..."
    tmux attach -t "${SESSION}"
    return
  fi

  echo "Starting tmux session '${SESSION}'..."
  # Pane 1: main.py
  tmux new-session -d -s "${SESSION}" "bash -lc '${PYTHON_BIN} ${MAIN_PY}; echo \"main.py exited. Press Enter\"; read'"
  sleep 1
  # Pane 2: ssh.sh
  tmux split-window -v -t "${SESSION}" "bash -lc '${SSH_SH}; echo \"ssh.sh exited. Press Enter\"; read'"
  tmux select-layout -t "${SESSION}" tiled || true

  # Only attach if a terminal exists
  if [ -t 1 ]; then
    tmux attach -t "${SESSION}"
  else
    echo "tmux session '${SESSION}' started in background."
  fi
}

stop_tmux_and_cleanup() {
  if tmux has-session -t "${SESSION}" 2>/dev/null; then
    echo "Killing tmux session '${SESSION}'..."
    tmux kill-session -t "${SESSION}"
  else
    echo "No tmux session '${SESSION}' found."
  fi
  clear_system_proxy
  unset_proxy_envs
  echo "Stopped. System proxy cleared."
}

# --- check files ---
if [ ! -f "$MAIN_PY" ]; then
  echo "ERROR: main.py not found in $(pwd)" >&2
  exit 2
fi
if [ ! -f "$SSH_SH" ]; then
  echo "ERROR: ssh.sh not found in $(pwd)" >&2
  exit 2
fi

# --- main ---
case "$ACTION" in
  start|"")
    if ! command -v tmux >/dev/null 2>&1; then
      echo "ERROR: tmux not installed. sudo apt install tmux" >&2
      exit 3
    fi
    if ! command -v gsettings >/dev/null 2>&1; then
      echo "ERROR: gsettings not found." >&2
      exit 4
    fi

    set_system_socks_proxy "$SOCKS_HOST" "$SOCKS_PORT"
    export_proxy_envs "$SOCKS_HOST" "$SOCKS_PORT"

    echo "Launching main.py and ssh.sh in tmux session '${SESSION}'..."
    start_tmux
    ;;
  stop)
    stop_tmux_and_cleanup
    ;;
  *)
    echo "Usage: $0 start|stop"
    exit 1
    ;;
esac

exit 0

