#!/bin/sh
# Install each package in a clean container (real runtime dependency from distro/Microsoft repos) and probe the server.
# Usage: scripts/test.sh [target...]   targets: ubuntu24 ubuntu26 debian12 debian13 rhel8 rhel9 rhel10
set -u
cd "$(dirname "$0")/.."
APT='apt-get update -qq && apt-get install -y -qq curl ca-certificates >/dev/null'
msdeb() { echo "$APT && curl -fsSL -o /tmp/ms.deb https://packages.microsoft.com/config/debian/$1/packages-microsoft-prod.deb && dpkg -i /tmp/ms.deb >/dev/null && apt-get update -qq"; }
msrpm() { echo "dnf -q -y install util-linux >/dev/null && rpm -Uvh https://packages.microsoft.com/config/rhel/$1/packages-microsoft-prod.rpm >/dev/null"; }
DEBI='apt-get install -y /dist/technitium-dns-server_*_all.deb'
RPMI='dnf -y install /dist/technitium-dns-server-*.noarch.rpm'
run() { # name image setup install
  echo "=== $1 ($2) ==="
  docker run --rm --platform "${PLATFORM:-linux/amd64}" -v "$PWD/dist":/dist:ro "$2" sh -c "
    set -e
    $3
    $4
    id dns-server
    su -s /bin/sh dns-server -c 'cd /opt/technitium/dns && /usr/bin/dotnet DnsServerApp.dll /etc/dns >/var/log/technitium/dns/test.out 2>&1 &'
    for i in \$(seq 40); do curl -fs -o /dev/null http://127.0.0.1:5380/ && break; sleep 1; done
    curl -fsS -o /dev/null -w 'web console HTTP %{http_code}\n' http://127.0.0.1:5380/
    dotnet --list-runtimes
  " >"dist/test-$1.log" 2>&1 && { echo PASS; grep -E 'web console|AspNetCore' "dist/test-$1.log"; } || { echo "FAIL (see dist/test-$1.log)"; tail -8 "dist/test-$1.log"; }
}
targets="${*:-ubuntu24 ubuntu26 debian12 debian13 rhel8 rhel9 rhel10}"
for t in $targets; do case $t in
  ubuntu24) run $t ubuntu:24.04 "$APT" "$DEBI" ;;
  ubuntu26) run $t ubuntu:26.04 "$APT" "$DEBI" ;;
  debian13) run $t debian:13 "$(msdeb 13)" "$DEBI" ;;
  debian12) run $t debian:12 "$(msdeb 12)" "$DEBI" ;;
  rhel8)    run $t almalinux:8  "$(msrpm 8)"  "$RPMI" ;;
  rhel9)    run $t almalinux:9  "$(msrpm 9)"  "$RPMI" ;;
  rhel10)   run $t almalinux:10 "$(msrpm 10)" "$RPMI" ;;
esac; done
