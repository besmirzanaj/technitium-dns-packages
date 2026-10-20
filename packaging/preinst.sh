#!/bin/sh
set -e
if ! getent passwd dns-server >/dev/null 2>&1; then
    if command -v useradd >/dev/null 2>&1; then
        useradd --system -M --shell /usr/sbin/nologin --user-group dns-server
    else
        addgroup -S dns-server; adduser -H -S -D -s /bin/false -G dns-server dns-server
    fi
fi
exit 0
