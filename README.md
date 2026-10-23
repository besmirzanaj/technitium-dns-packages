# Technitium DNS Server packages

Unofficial `.deb` and `.rpm` packages of [Technitium DNS Server](https://technitium.com/dns/), built from the official
`DnsServerPortable.tar.gz`. A daily GitHub Action checks for a new upstream release, builds, tests and publishes it
under [Releases](../../releases), and pushes them to Gemfury when `GEMFURY_PUSH_URL` is configured.

Packages are built for x86_64/amd64 and aarch64/arm64 (Raspberry Pi, Orange Pi, Armbian, etc.). The app is managed .NET code, so the contents are identical; only the package architecture differs.

## Install

### Step 1: make the ASP.NET Core runtime available

The packages depend on `aspnetcore-runtime-10.0`, which your package manager installs automatically if a repo provides it.
Ubuntu 24.04 and 26.04 have it in their own repositories, so skip this step there.

On Debian 12/13 (and Raspberry Pi OS or Armbian based on them) add the Microsoft repository:

```bash
. /etc/os-release
curl -fsSL -o /tmp/packages-microsoft-prod.deb "https://packages.microsoft.com/config/debian/$VERSION_ID/packages-microsoft-prod.deb"
sudo dpkg -i /tmp/packages-microsoft-prod.deb
sudo apt update
```

On RHEL, Alma and Rocky 8/9/10:

```bash
sudo rpm -Uvh "https://packages.microsoft.com/config/rhel/$(rpm -E %rhel)/packages-microsoft-prod.rpm"
```

If your RHEL clone already ships .NET 10 in its own repos you can skip this, but it does no harm.

| Distro | Where `aspnetcore-runtime-10.0` comes from |
|---|---|
| Ubuntu 24.04, 26.04 | distro archive |
| Debian 12, 13 | [Microsoft repo](https://learn.microsoft.com/dotnet/core/install/linux-debian) |
| RHEL 8/9/10 and clones | distro AppStream, or the [Microsoft repo](https://learn.microsoft.com/dotnet/core/install/linux-rhel) |

### Step 2a: from the package repository (recommended)

The packages are also published to a Gemfury repository, so `apt` and `dnf` install the latest version and upgrade it with
the rest of the system. The repo works for both x86_64 and arm64.

Debian, Ubuntu, Raspberry Pi OS, Armbian:

```bash
echo "deb [trusted=yes] https://apt.fury.io/cloudalbania/ /" | sudo tee /etc/apt/sources.list.d/cloudalbania.list
sudo apt update
sudo apt install technitium-dns-server
```

RHEL, Alma, Rocky:

```bash
sudo tee /etc/yum.repos.d/cloudalbania.repo <<'EOF'
[cloudalbania]
name=CloudAlbania
baseurl=https://yum.fury.io/cloudalbania/
enabled=1
gpgcheck=0
EOF
sudo dnf install technitium-dns-server
```

The repo is not GPG-signed (`trusted=yes` / `gpgcheck=0`), so only use it if you trust that I built it, or install from the
GitHub release below.

### Step 2b: from the GitHub release

If you would rather not add a repository, download the package from the [latest release](../../releases/latest). This needs
only `curl`, and no version number: it asks the GitHub API for the latest release and picks the file for your architecture.

Debian, Ubuntu, Raspberry Pi OS, Armbian:

```bash
curl -fsSLO "$(curl -s https://api.github.com/repos/besmirzanaj/technitium-dns-packages/releases/latest \
  | grep -o "https://[^\"]*_$(dpkg --print-architecture)\.deb")"
sudo apt install ./technitium-dns-server_*.deb
```

RHEL, Alma, Rocky:

```bash
curl -fsSLO "$(curl -s https://api.github.com/repos/besmirzanaj/technitium-dns-packages/releases/latest \
  | grep -o "https://[^\"]*\.$(uname -m)\.rpm")"
sudo dnf install ./technitium-dns-server-*.rpm
```

Then open `http://<host>:5380/` and set the admin password.

## Testing

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
