#!/bin/sh
set -e
# $1 is "remove"/"upgrade" (deb) or 0/1 (rpm); only stop on real removal
case "$1" in
    remove|0)
        if [ -d /run/systemd/system ]; then
            systemctl disable --now dns.service >/dev/null 2>&1 || true
        fi ;;
esac
exit 0
