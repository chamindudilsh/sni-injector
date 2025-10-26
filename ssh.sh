#!/usr/bin/bash
cd "$(dirname "$0")" || exit 1

# Usage: get_ini_value <file> <section> <key>
get_ini_value() {
    local file="$1"
    local section="$2"
    local key="$3"
    
    awk -F '=' -v section="$section" -v key="$key" '
    BEGIN { in_section=0 }
    /^[ \t]*;/ { next }       # skip semicolon comments
    /^[ \t]*#/ { next }       # skip hash comments
    /^\s*\[.*\]/ {
        in_section = ($0 ~ "\\[" section "\\]") ? 1 : 0
    }
    in_section {
        k=$1
        gsub(/^[ \t]+|[ \t]+$/, "", k)   # trim spaces from key
        if (k == key) {
            v=$2
            gsub(/^[ \t]+|[ \t]+$/, "", v)   # trim spaces from value
            print v
            exit
        }
    }
    ' "$file"
}

INI_FILE="settings.ini"

# SSH settings are loaded from settings.ini

HOST=$(get_ini_value "$INI_FILE" "ssh" "host")
USERNAME=$(get_ini_value "$INI_FILE" "ssh" "username")
PASSWORD=$(get_ini_value "$INI_FILE" "ssh" "password")
PORT=$(get_ini_value "$INI_FILE" "ssh" "port")

#-Auto login with password
sshpass -p "$PASSWORD" ssh -C -o "ProxyCommand=nc -X CONNECT -x 127.0.0.1:9092 %h %p" "$USERNAME"@"$HOST" -p "$PORT" -v -CND 1080 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null

#-Manual login
#ssh -C -o "ProxyCommand=nc -X CONNECT -x 127.0.0.1:9092 %h %p" "$USERNAME"@"$HOST" -p "$PORT"  -CND 1080 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null
