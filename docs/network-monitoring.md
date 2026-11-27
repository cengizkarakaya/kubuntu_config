# Network monitoring profile — Kubuntu 26.10 (opt-in)

This profile is independent of the full desktop bootstrap. It installs
**Sniffnet**, **RustNet** (official signed-infrastructure GitHub release
metadata with published SHA-256 digests and downloaded artifact verification),
**iperf3** (Ubuntu APT) and **NetAlertX** (rootful Docker Compose, GHCR).
The GitHub release SHA-256 digest checks integrity of downloads; it is **not**
an independent author signature or a complete supply-chain guarantee.

## Install on the actual Kubuntu workstation

Run from the existing clone as the ordinary desktop user:

```bash
cd ~/kubuntu_config
git pull --ff-only
bash scripts/install-network-monitoring.sh plan
bash scripts/netalertx.sh plan
bash scripts/install-network-monitoring.sh install
bash scripts/install-network-monitoring.sh verify
```

If the clone lives elsewhere, navigate to that directory. The installer
requests sudo only for official APT package installation and Docker commands.
Never use `sudo bash scripts/install-network-monitoring.sh`.
The profile does not modify KDE/Plasma, graphics, router settings, Docker
group membership or existing ROS containers.

**Not installed merely by committing to GitHub:** a `git pull` plus the
explicit install command above is required. If an install stage fails, do
not assume remaining tools are installed. Investigate the error and rerun.

## Applications and permission model

| App | Channel | Invocation | Updates |
| --- | --- | --- | --- |
| iperf3 | Ubuntu signed APT | `iperf3 --version` | Existing `sysup apply` APT stage |
| Sniffnet | Official GitHub stable .deb, SHA-256 checked | `sniffnet` or KDE menu | Re-run `install-network-monitoring.sh update` |
| RustNet (`rustnet-monitor` Debian package) | Official GitHub stable .deb, SHA-256 checked | `rustnet` | Re-run `install-network-monitoring.sh update` |
| NetAlertX | Official GHCR stable version + immutable multi-platform digest | Browser: http://127.0.0.1:20211 | Review version/digest bump, then `netalertx.sh update` |

**RustNet packaging note:** its official `Rustnet_LinuxDEB_amd64.deb` file
has Debian metadata `Package: rustnet-monitor`, although the program is
launched with `rustnet`. This distinction matters for `dpkg-query`,
install/skip/update checks and verification. The installer enforces the
expected internal package name; it must not disable the name check.

The upstream `.deb` packages may set capture permissions for Sniffnet and
RustNet. The installer reports whether `CAP_NET_RAW` is present. If an
application cannot capture packets as your normal user, inspect
`getcap "$(command -v sniffnet)"` or
`getcap "$(command -v rustnet)"` before making permission changes.
`sudo` is **not** the recommended way to launch a full Wayland GUI.

### RustNet permission warning after installation

If `getcap /usr/bin/rustnet` is empty or the installer prints
`CAP_NET_RAW not present`, the upstream package installed successfully but
its optional packet capture capabilities were not applied. The official
RustNet Linux instructions recommend the following **explicit, one-time**
permission adjustment on supported kernels:

```bash
sudo setcap 'cap_net_raw,cap_bpf,cap_perfmon+eip' /usr/bin/rustnet
getcap /usr/bin/rustnet
rustnet
```

These privileges permit raw packet capture, eBPF operations and performance
monitoring without starting the whole terminal as root. They are security
sensitive: only grant them to a binary from a release you trust. The opt-in
installer does **not** silently grant the extra BPF/PERFMON capabilities.
Some filesystem configurations, container restrictions or security policies
may prevent `setcap` from working. After a RustNet .deb upgrade, recheck
with `getcap` because file capabilities can be reset when the binary is
replaced.

### Other update channels

These two manually installed `.deb` files do **not** gain an automatic APT
repository by installation. Unlike iperf3, `sysup apply` cannot discover
future GitHub-only releases. Re-run the explicit update profile to fetch and
verify the latest official stable release. NetAlertX updates are also opt-in:
`sysup apply` does not pull Docker images.

## NetAlertX image provenance and updates

The Compose file pins both a human-readable stable release tag and the immutable
multi-platform manifest digest. Docker pulls the digest, not a mutable `latest`
tag. The initial pin is upstream 26.10.28, as published on the official
[GHCR package page](https://github.com/netalertx/NetAlertX/pkgs/container/netalertx).

For upgrades, review the official stable [release notes](https://github.com/netalertx/NetAlertX/releases)
and verify the corresponding **index** digest on that package page (not a
single-platform manifest). Update the tag and digest together in `compose.yaml`;
review CI, especially the API exposure/guard assumptions. Dependabot may propose
Docker updates; do not auto-merge them. Back up the named volume before applying
an upgrade, then pull the reviewed repository commit and run `netalertx.sh update`
and `check`. The command applies the pinned release; it no longer discovers new
versions by itself. If upstream is newer than the pin, review the upgrade rather
than silently using `latest`. No Docker runtime changes occur from Git alone.

## NetAlertX controls

```bash
bash scripts/netalertx.sh plan     # read-only: local interface and access details
bash scripts/netalertx.sh up       # install/start container, preserve old data
bash scripts/netalertx.sh check    # container running (not a test of device discovery)
bash scripts/netalertx.sh logs     # last 100 container log lines
bash scripts/netalertx.sh update   # apply reviewed pinned image; preserve data
bash scripts/netalertx.sh down     # stop/remove container, KEEP named volume
```

The Compose project is `kubuntu-netalertx`; persistent data belongs to the
Docker-managed named volume `kubuntu-netalertx_netalertx_data`.
The container restarts unless manually stopped and remains operational only
while Kubuntu and Docker Engine are running. No personal device inventory,
database or login details belong in this public repo. Never run
`docker compose down --volumes` unless you deliberately intend to erase data.

The default web listener is restricted to localhost (127.0.0.1:20211).
**Important security distinction:** In upstream NetAlertX **v26.10.28**,
`LISTEN_ADDR=127.0.0.1` limits only the nginx frontend. The separate
Flask/GraphQL backend is hard-coded to `host="0.0.0.0"` in
`server/api_server/api_server_start.py`; it can listen on **all IPv4
interfaces** at port **20212** even though the web UI is local-only.

Upstream source:
https://github.com/netalertx/NetAlertX/blob/v26.10.28/server/api_server/api_server_start.py

**A listener on 0.0.0.0 does not itself prove a remote client can connect**;
firewall rules may already prevent access. Check the listening addresses and
your existing firewall before changing network policy:

```bash
sudo ss -lntp | grep -E ':(20211|20212)\\b'
sudo ufw status verbose
```

If UFW reports `Status: active` and you want **LAN-restricted / local-only
API access** (no direct access over Wi-Fi), you can add the narrowly scoped,
persistent incoming rule for the workstation's actual Wi-Fi interface:

```bash
sudo ufw deny in on wlp5s0 to any port 20212 proto tcp
sudo ufw status numbered
```

Replace `wlp5s0` if your interface changes. This restricts *incoming*
connections on that interface, not the service's socket binding. Review other
active network interfaces as appropriate. Don't apply rules to unrelated
networks; Docker uses host networking here and UFW is the **host** firewall.

If UFW is **inactive**, the command `ufw deny` only saves an inactive
rule; it does **not** protect the service. Do **not** blindly run `ufw enable`
because it can alter SSH and other network access.

### Optional persistent nftables API guard (UFW inactive)

This repo includes a deliberately narrow host rule. It drops incoming
TCP/20212 from **all non-loopback interfaces** while preserving localhost
access needed by nginx. The rule lives in its own nftables `inet` table,
uses an `input` chain with **policy accept**, and does not change UFW,
Docker networks, SSH, the rest of the firewall, or the base `nftables.service`
configuration. It applies to IPv4 and IPv6 input; no UDP traffic is blocked.
The systemd unit re-applies the rule on boot **before Docker starts**.

```bash
cd ~/kubuntu_config
bash scripts/netalertx-api-guard.sh plan
bash scripts/netalertx-api-guard.sh enable
bash scripts/netalertx-api-guard.sh check
```

If `nft` is not installed, install the signed Ubuntu package
`sudo apt install nftables` **without enabling/restarting nftables.service**
and retry. The `enable` step installs only reviewed, **root-owned copies**
of the rule file, tiny privileged helper and systemd one-shot unit.
It is intentionally NOT part of `bootstrap.sh`, `sysup` or the normal
network tools installer. **Nothing is enabled by `git pull` alone.**

Verify the service and unchanged network listener:

```bash
sudo nft list table inet kubuntu_netalertx_api_guard
systemctl is-enabled netalertx-api-guard.service
systemctl is-active netalertx-api-guard.service
sudo ss -lntp | grep -E ':(20211|20212)\\b'
```

NetAlertX still binds `0.0.0.0:20212`, but nftables drops non-loopback
requests before they reach the listening socket. A real connectivity test
from another device on the LAN is recommended; do not infer that traffic
is blocked solely from a local loopback test. Changes to the API port
require updating the guard explicitly. If a different firewall manager
flushes the full nftables ruleset, re-run `check` because the separate
table may disappear.

To disable **only** this guard (do not do this while relying on it for
isolation):

```bash
bash scripts/netalertx-api-guard.sh disable
```

The systemd unit's stop action removes only the dedicated guard table,
not other host firewall rules. Alternatively, stop NetAlertX until you have
a suitable protection:

```bash
bash scripts/netalertx.sh down
```

Never set an invented `GRAPHQL_HOST` or `LISTEN_ADDR` environment variable
expecting it to move the backend binding: the upstream version does not
support that as a backend bind override. Do not change the scanning network
from host networking merely to hide the API: ARP discovery relies on host
network access. The backend uses an API token, but unnecessary network
exposure is still undesirable.

The `netalertx.sh check` command prints a warning on a detected non-loopback
API listener. The warning may remain even if a firewall rule successfully
blocks remote traffic, because socket binding and network reachability are
distinct checks.

Do not expose these ports to the public Internet or configure router port
forwarding. The profile deliberately avoids changing the workstation's
firewall automatically; network access control requires a reviewed host
policy.

### First LAN discovery configuration

Visit http://127.0.0.1:20211 in the Kubuntu browser. A running container does
not guarantee that scanning is enabled. In NetAlertX Settings configure the
`SCAN_SUBNETS` value using the actual **local** IPv4 CIDR and interface.
Check them with:

```bash
ip -4 route
ip -br -4 addr
```

Example **only** (not the user's known subnet):
`['192.168.1.0/24 --interface=enp3s0']`

Pick your true subnet (such as `192.168.0.0/24`) and actual network
interface, save settings and inspect the scan logs. VLANs, guest Wi-Fi,
client isolation, firewalls and devices that block probes may remain invisible.
NetAlertX discovers devices; it does not automatically see all their traffic.

If a TCP/IP scanner has no results, first check that the selected interface
matches the host's default route. Avoid scanning networks you do not own or
administer.

## iperf3 speed tests — two machines required

On the Raspberry Pi (or another host you control):

```bash
sudo apt install iperf3
iperf3 -s
```

On Kubuntu, replacing the address with the actual server address:

```bash
iperf3 -c RPI_IP
iperf3 -c RPI_IP -R
```

First command sends data from Kubuntu to RPi; `-R` reverses direction.
By default iperf3 listens on TCP port 5201 on the server. Only run the
server on trusted LANs, and stop it with Ctrl+C afterward. The `iperf3`
program measures LAN throughput, not ISP download/upload speed.

## Verification and constraints

```bash
bash scripts/install-network-monitoring.sh verify
dpkg-query -W iperf3 sniffnet rustnet-monitor
getcap "$(command -v sniffnet)"
getcap "$(command -v rustnet)"
bash scripts/netalertx.sh check
```

GitHub integration, static Bash checks and Docker Compose validation do not
prove installation on the user's PC. Check actual GUI launch, network capture
and NetAlertX discovery interactively. If re-installing or restoring the PC,
back up the Docker data volume separately; only Compose configuration is
version-controlled.
