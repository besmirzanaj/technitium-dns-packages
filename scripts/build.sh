#!/bin/sh
# Usage: scripts/build.sh [VERSION]   (default: latest GitHub release of TechnitiumSoftware/DnsServer)
set -eu
cd "$(dirname "$0")/.."
VERSION="${1:-$(curl -fsSL https://api.github.com/repos/TechnitiumSoftware/DnsServer/releases/latest | sed -n 's/.*"tag_name": *"v\{0,1\}\([^"]*\)".*/\1/p')}"
[ -n "$VERSION" ] || { echo "cannot determine version" >&2; exit 1; }
echo "Building technitium-dns-server $VERSION"
rm -rf stage dist; mkdir -p stage/opt/technitium/dns dist
curl -fsSL https://download.technitium.com/dns/DnsServerPortable.tar.gz | tar -xz -C stage/opt/technitium/dns
rm -f stage/opt/technitium/dns/{start.bat,start.sh,systemd.service,openrc.service,DnsServerApp.exe} stage/opt/technitium/dns/*.pdb
chmod -R go-w stage; find stage -type d -exec chmod 755 {} +; find stage -type f -exec chmod 644 {} +
for f in deb rpm; do
  docker run --rm -e VERSION="$VERSION" -v "$PWD":/w -w /w goreleaser/nfpm:latest package -f nfpm.yaml -p $f -t dist/
done
ls -l dist
