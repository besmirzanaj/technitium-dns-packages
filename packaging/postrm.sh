#!/bin/sh
set -e
[ -d /run/systemd/system ] && systemctl daemon-reload >/dev/null 2>&1 || true
# /etc/dns and /var/log/technitium are user data and are kept; removed on purge only
case "$1" in
    purge) rm -rf /opt/technitium /etc/dns /var/log/technitium
           userdel dns-server >/dev/null 2>&1 || true ;;
esac
exit 0
