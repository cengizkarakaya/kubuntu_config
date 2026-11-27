# Hardware diagnostics

Use `inxi` for hardware inventory, `rasdaemon` for supported kernel RAS events and `ddcutil` for external monitor DDC/CI. The core manifest uses configured signed Ubuntu APT repositories. Verify the actual package versions, service state and display access on each target machine.

## Restore and verify

On an existing installation, if needed:

```bash
sudo apt-get update
sudo apt-get install --no-remove inxi rasdaemon ddcutil
sudo systemctl enable --now rasdaemon.service
dpkg-query -W inxi rasdaemon ddcutil
systemctl is-enabled rasdaemon.service
systemctl is-active rasdaemon.service
sudo ras-mc-ctl --summary
```

The package may already enable the service on install. The explicit enable
command is for a fresh restore or an inactive service that the user wishes to
enable. Do not restart a working daemon merely to check it.

## Read-only diagnostics

```bash
inxi -v8 -z
sudo ras-mc-ctl --summary
sudo ras-mc-ctl --errors
sudo journalctl -u rasdaemon.service -b --no-pager
systemctl --failed
systemctl --user --failed
```

Run inxi as the desktop user for session graphics/audio context; use
`sudo inxi -ma -z` if privileged DIMM information is necessary.
Review all output before sharing: even with `-z`, identifiers or paths may
remain. Keep raw reports, device identifiers, journal excerpts, and the local
RAS database out of the public repository.

RAS records only supported events observed while monitoring is active.
Zero recorded errors do not prove RAM, CPU, GPU, or PCIe stability.
SIGNAL events are a separate category; inspect the full records before
classifying them. They do not by themselves establish hardware failure.
Neither tool performs a physical RAM test, stress test, or repairs hardware.

## External monitor DDC/CI and KDE PowerDevil

If PowerDevil logs I2C permission errors, inspect the Ubuntu `ddcutil` package and its packaged udev rules. Do not grant broad device permissions or assume monitor compatibility.

Verify after installation from the active graphical session:

```bash
ddcutil --version
dpkg -L ddcutil | grep -E 'udev|rules'
ddcutil detect
journalctl --user -b -u plasma-powerdevil.service --no-pager
```

The package owns the udev rules; allow APT to resolve its dependencies.
If PowerDevil started before the rules were installed, save work and log
out/in or reboot at a convenient time, then check fresh logs. Detection
does not prove every PowerDevil function works. Do not hard-code I2C bus
numbers, grant world-writable device access, add users to the i2c group,
copy custom rules, scan unrelated I2C buses, or change monitor settings
automatically. Review detection output before sharing; it contains monitor
serial numbers.

## Verification policy

Existing `verify.sh` and `scripts/version-audit.sh` check the core package
manifest. Check service state and actual RAS output separately on the host.
Do not change BIOS, XMP, microcode, GPU drivers, firmware, device permissions,
or boot settings as part of diagnostics. Do not automatically run stress
tests, especially given prior elevated CPU temperature under load.
