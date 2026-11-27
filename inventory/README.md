# Private workstation inventory

```bash
bash scripts/inventory-snapshot.sh --plan
bash scripts/inventory-snapshot.sh --capture
bash scripts/inventory-snapshot.sh --compare /path/before/inventory.json /path/after/inventory.json
```

Raw inventory is private, stored under the XDG state directory (normally ~/.local/state/kubuntu-config/inventory). No automatic publication or Git staging is provided. Review and manually transcribe only necessary non-sensitive facts. Inventory can expose software, local paths and private environment names.

Reuses sysup's version capture for APT, user Flatpak, Snap, Rust and official binaries; supplements it with manual APT selections, system Flatpak, Cargo, OS/kernel, Plasma, Python, Docker CLI/Compose, NVIDIA driver version, Conda environment listing and Git commit/dirty state. Docker images requiring rootful access, private services and project-specific Python packages are not queried. Missing tools are reported; failed queries produce a nonzero exit and a private partial record. Compare does not treat unavailable sources as empty inventories. On-host capture and review required.
