#!/bin/sh
set -e
mkdir -p /etc/dns /var/log/technitium/dns
chown -R dns-server:dns-server /opt/technitium/dns /etc/dns /var/log/technitium/dns

if [ -d /run/systemd/system ]; then
    systemctl daemon-reload >/dev/null 2>&1 || true
    systemctl enable dns.service >/dev/null 2>&1 || true
    systemctl restart dns.service >/dev/null 2>&1 || true
    if systemctl is-active --quiet systemd-resolved 2>/dev/null; then
        echo "Note: systemd-resolved is active and may hold port 53. To free it:"
        echo "  systemctl disable --now systemd-resolved && rm /etc/resolv.conf && echo 'nameserver 127.0.0.1' > /etc/resolv.conf"
    fi
fi
echo "Technitium DNS Server web console: http://$(cat /proc/sys/kernel/hostname):5380/"
exit 0
