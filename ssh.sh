#!/usr/bin/bash
cd "$(dirname "$0")" || exit 1

# Usage: get_ini_value <file> <section> <key>
get_ini_value() {
  local file="$1" section="$2" key="$3"

  local raw
  raw=$(awk -F '=' -v section="$section" -v key="$key" '
    BEGIN { in_section=0 }
    /^[ \t]*;/ { next }       # skip semicolon comments
    /^[ \t]*#/ { next }       # skip hash comments
    /^\s*\[.*\]/ {
        in_section = ($0 ~ "\\[" section "\\]") ? 1 : 0
    }
    in_section {
        # split on =, but allow equals in value (take first "=" as separator)
        split($0, parts, "=")
        k=parts[1]
        gsub(/^[ \t]+|[ \t]+$/, "", k)
        if (k == key) {
            # rebuild value from parts[2..n]
            v=""
            for (i=2; i<=length(parts); i++) {
              v = v (i==2 ? "" : "=") parts[i]
            }
            gsub(/^[ \t]+|[ \t]+$/, "", v)
            print v
            exit
        }
    }
  ' "$file" 2>/dev/null || true)

  if [ -z "${raw:-}" ]; then
    printf '%s' ""
    return
  fi

  # Strip Windows CRs, surrounding single/double quotes, and surrounding whitespace
  # Also remove stray control characters just in case
  # Use parameter expansion and tr
  raw=$(printf '%s' "$raw" | tr -d '\r' | sed -e 's/^[ \t]*//;s/[ \t]*$//')
  # remove surrounding quotes if present
  raw="${raw%\"}"
  raw="${raw#\"}"
  raw="${raw%\'}"
  raw="${raw#\'}"
  # remove non-printable characters
  raw=$(printf '%s' "$raw" | tr -cd '\11\12\15\40-\176')

  printf '%s' "$raw"
}

INI_FILE="settings.ini"

if [ ! -f "$INI_FILE" ]; then
  echo "ERROR: $INI_FILE not found in $(pwd)" >&2
  exit 2
fi

HOST=$(get_ini_value "$INI_FILE" "ssh" "host")
USERNAME=$(get_ini_value "$INI_FILE" "ssh" "username")
PASSWORD=$(get_ini_value "$INI_FILE" "ssh" "password")
PORT=$(get_ini_value "$INI_FILE" "ssh" "port")

LOCAL_IP=$(get_ini_value "$INI_FILE" "settings" "local_ip")
LISTEN_PORT=$(get_ini_value "$INI_FILE" "settings" "listen_port")

# sanitize PORT to only allow digits
PORT_SANITIZED=$(printf '%s' "$PORT" | sed -E 's/[^0-9].*//g')

if [ -z "$PORT_SANITIZED" ]; then
  echo "ERROR: port value is empty or invalid ('$PORT')" >&2
  exit 3
fi

echo "Using port: '$PORT_SANITIZED'"

echo "${LOCAL_IP}":"${LISTEN_PORT}"

# Auto login with password

sshpass -p "${PASSWORD}" ssh -C -o "ProxyCommand=nc -X CONNECT -x "${LOCAL_IP}":"${LISTEN_PORT}" %h %p" "${USERNAME}"@"${HOST}" -p "${PORT_SANITIZED}" -v -CND 1080 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null

# Manual login

#ssh -C -o "ProxyCommand=nc -X CONNECT -x "${LOCAL_IP}":"${LISTEN_PORT}" %h %p" "${USERNAME}"@"${HOST}" -p "${PORT_SANITIZED}" -CND 1080 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null
