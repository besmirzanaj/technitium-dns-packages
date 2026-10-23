# Technitium DNS Server packages

Unofficial `.deb` and `.rpm` packages of [Technitium DNS Server](https://technitium.com/dns/), built from the official
`DnsServerPortable.tar.gz`. A daily GitHub Action checks for a new upstream release, builds, tests and publishes it
under [Releases](../../releases), and pushes them to Gemfury when `GEMFURY_PUSH_URL` is configured.

Packages are built for x86_64/amd64 and aarch64/arm64 (Raspberry Pi, Orange Pi, Armbian, etc.). The app is managed .NET code, so the contents are identical; only the package architecture differs.

## Install

Download from the [latest release](../../releases/latest).

Debian / Ubuntu:

    sudo apt install ./technitium-dns-server_<version>_<amd64|arm64>.deb

RHEL / Alma / Rocky:

    sudo dnf install ./technitium-dns-server-<version>-1.<x86_64|aarch64>.rpm

Then open `http://<host>:5380/`.

## ASP.NET Core runtime dependency

The packages depend on `aspnetcore-runtime-10.0`, which your package manager installs automatically if a repo provides it:

| Distro | Source |
|---|---|
| Ubuntu 24.04, 26.04 | distro archive |
| Debian 12, 13 | [Microsoft repo](https://learn.microsoft.com/dotnet/core/install/linux-debian) (`packages-microsoft-prod.deb`) |
| RHEL 8/9/10 and clones | distro AppStream, or the [Microsoft repo](https://learn.microsoft.com/dotnet/core/install/linux-rhel) |

Each release is install-tested in CI with one deb (Ubuntu 24.04) and one rpm (AlmaLinux 9). Locally, `scripts/test.sh` covers
Ubuntu 24.04/26.04, Debian 12/13 and AlmaLinux 8/9/10 on x86_64 or arm64 (`PLATFORM=linux/arm64`). The systemd unit itself is not exercised there (no systemd in containers).

## Layout

| Path | |
|---|---|
| App | `/opt/technitium/dns` |
| Config / data | `/etc/dns` |
| Logs | `/var/log/technitium/dns` |
| Service | `dns.service` (user `dns-server`) |

Unlike the official `install.sh`, the package does not disable `systemd-resolved` or rewrite `/etc/resolv.conf`.
If port 53 is taken: `systemctl disable --now systemd-resolved`, then point `/etc/resolv.conf` at `127.0.0.1`.
Config and logs are kept on removal; `purge` (deb) deletes them.

## Building locally

Requires Docker.

    scripts/build.sh [version]   # output in dist/
    PLATFORM=linux/arm64 scripts/test.sh [targets]   # ubuntu24 ubuntu26 debian12 debian13 rhel8 rhel9 rhel10

Not affiliated with Technitium.

## Gemfury

The workflow pushes each new release to Gemfury using the repo secret `GEMFURY_PUSH_URL` (the full push URL including
token, same convention as dnsglobe). Without the secret the step is skipped.
