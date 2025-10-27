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

# --- helper: GNOME GUI proxy ---
set_system_socks_proxy() {
    local host="$1"
    local port="$2"

    if command -v gsettings >/dev/null 2>&1 && \
       gsettings writable org.gnome.system.proxy.socks host >/dev/null 2>&1; then
        echo "INFO: Setting system proxy (GUI) to SOCKS ${host}:${port}..."
        gsettings set org.gnome.system.proxy mode 'manual'
        gsettings set org.gnome.system.proxy.socks host "${host}"
        gsettings set org.gnome.system.proxy.socks port "${port}"
    else
        echo "Skipping GNOME gsettings — not available or not writable."
        echo -e "\nINFO: Set socks proxy to 127.0.0.1:1080 manually.\n"
    fi 
}

clear_system_proxy() {
    if command -v gsettings >/dev/null 2>&1 && \
       gsettings writable org.gnome.system.proxy.socks host >/dev/null 2>&1; then
        echo "INFO: Clearing system proxy (GUI)..."
        gsettings set org.gnome.system.proxy mode 'none'
        gsettings reset org.gnome.system.proxy.socks host || true
        gsettings reset org.gnome.system.proxy.socks port || true
    else
        echo "Skipping GNOME gsettings — not available or not writable."
        echo -e "\nINFO: Reset socks proxy manually.\n"
    fi
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
    echo -e "ERR: tmux session '${SESSION}' is already running. Attach tmux to see logs.\nHINT: tmux attach -t "${SESSION}"\n"
    status_tmux
    status_proxy 
    echo -e "\nUsage: $0 start|stop|status"   
    exit 0
  fi

  echo "Starting tmux session '${SESSION}'..."
  # Pane 1: main.py
  tmux new-session -d -s "${SESSION}" "bash -lc '${PYTHON_BIN} ${MAIN_PY}; echo \"main.py exited. Press Enter\"; read'"
  sleep 1
  # Pane 2: ssh.sh
  tmux split-window -v -t "${SESSION}" "bash -lc '${SSH_SH}; echo \"ssh.sh exited. Press Enter\"; read'"
  tmux select-layout -t "${SESSION}" tiled || true

  echo "INFO: tmux session '${SESSION}' started in background. Attach tmux to see logs."
  echo -e "HINT: tmux attach -t ${SESSION} \n\nUsage: $0 start|stop|status"
}

stop_tmux_and_cleanup() {
  if tmux has-session -t "${SESSION}" 2>/dev/null; then
    echo "Killing tmux session '${SESSION}'..."
    tmux kill-session -t "${SESSION}"
  else
    echo "No tmux session '${SESSION}' found."
  fi
  echo -e "\nCleanup:"
  clear_system_proxy
  unset_proxy_envs
  echo "Stopped. System proxy cleared."
}

status_tmux() {
    if ! tmux has-session -t "${SESSION}" 2>/dev/null; then
        echo "Tmux session: NOT RUNNING"
        return
    fi

    echo "Tmux session: RUNNING"

    # Get PIDs of pane 0 (main.py) and pane 1 (ssh.sh)
    PANE_PIDS=$(tmux list-panes -t "$SESSION" -F '#{pane_index} #{pane_pid}')
    MAIN_PID=$(echo "$PANE_PIDS" | awk '$1==0 {print $2}')
    SSH_PID=$(echo "$PANE_PIDS" | awk '$1==1 {print $2}')

    # Check each PID is alive
    if ps -p "$MAIN_PID" >/dev/null 2>&1; then
        echo "  main.py: running"
    else
        echo "  main.py: not running"
    fi

    if ps -p "$SSH_PID" >/dev/null 2>&1; then
        echo "  ssh.sh : running"
    else
        echo "  ssh.sh : not running"
    fi
}

status_proxy() {
    # var init
    PROXY_MODE="unknown"
    PROXY_HOST="unknown"
    PROXY_PORT="unknown"

    if command -v gsettings >/dev/null 2>&1 && \
       gsettings writable org.gnome.system.proxy.socks host >/dev/null 2>&1; then
        PROXY_MODE=$(gsettings get org.gnome.system.proxy mode | tr -d "'")
        if [ "$PROXY_MODE" = "manual" ]; then
            PROXY_HOST=$(gsettings get org.gnome.system.proxy.socks host | tr -d "'")
            PROXY_PORT=$(gsettings get org.gnome.system.proxy.socks port)
        fi
    else
        echo ""
    fi

    if [ "$PROXY_MODE" = "manual" ]; then
        echo "Proxy: MANUAL (SOCKS $PROXY_HOST:$PROXY_PORT)"
    else
        echo "Proxy: $PROXY_MODE"
    fi
}

# --- check files & tmux ---
if [ ! -f "$MAIN_PY" ]; then
  echo "ERROR: main.py not found in $(pwd)" >&2
  exit 2
fi
if [ ! -f "$SSH_SH" ]; then
  echo "ERROR: ssh.sh not found in $(pwd)" >&2
  exit 2
fi

if ! command -v tmux >/dev/null 2>&1; then
  echo "ERROR: tmux not installed. sudo apt install tmux" >&2
  exit 3
fi

# --- Main case ---
case "$ACTION" in
    start|"") 
        echo "Launching main.py and ssh.sh in tmux session '${SESSION}'..."
        start_tmux
        set_system_socks_proxy "$SOCKS_HOST" "$SOCKS_PORT"
        export_proxy_envs "$SOCKS_HOST" "$SOCKS_PORT"
        ;;
    stop)
        stop_tmux_and_cleanup
        ;;
    status)
        status_tmux
        status_proxy
        echo -e "\nUsage: $0 start|stop|status"
        ;;
    *)
        echo "Usage: $0 start|stop|status"
        exit 1
        ;;
esac

exit 0

