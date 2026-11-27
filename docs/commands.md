# Workstation command reference

Run from the repository root as the normal user unless explicitly documented
otherwise. A plan is not an installation. Commands marked apply/install/build
can change software, configuration or data; read the corresponding guide first.

| Area | Preview / inspection | Explicit operation |
| --- | --- | --- |
| Core installation | `bash verify.sh` | `bash bootstrap.sh --core-only` or `bash bootstrap.sh` |
| Preserve Plasma | `bash verify.sh --skip-plasma` | `bash bootstrap.sh --skip-plasma` |
| Science APT | `bash scripts/install-science.sh --plan` | `bash scripts/install-science.sh --install` |
| Versions | `bash scripts/version-audit.sh` | None (audit only) |
| Maintenance | `sysup check`, `sysup status`, `sysup summary`, `sysup logs`, `sysup doctor` | `sysup apply`, `sysup auto`, `sysup resume`, `sysup resume --auto`, `sysup cancel` |
| Shell/terminal | `bash scripts/check-shell-terminal.sh` | See workstation reference |
| GPU | `bash scripts/gpu-diagnostics.sh` | Manual driver management only |
| Hardware | See [hardware diagnostics](hardware-diagnostics.md) | Manual service activation only |
| Dual boot | `bash scripts/dualboot-diagnostics.sh`, `bash scripts/configure-dualboot.sh --dry-run` | `bash scripts/configure-dualboot.sh --apply` (typed confirmation) |
| KDE menu | `bash scripts/menu-backup.sh --plan-restore` | `--capture`, `--stage-repo`, `--restore` (same script, separate actions) |
| Science launchers | `bash scripts/setup-scientific-launchers.sh --check` | `bash scripts/setup-scientific-launchers.sh --install` |
| Gaia Sky | `bash scripts/install-astronomy-gaia.sh --plan` | `bash scripts/install-astronomy-gaia.sh --install` |
| Celestia | `bash scripts/build-celestia-stable.sh --plan` | `bash scripts/build-celestia-stable.sh --build` |
| OpenSpace | `bash scripts/build-openspace.sh --plan`, `--check-apt` | `--build`, `--resume` (same script) |
| Astronomy launchers | `python3 scripts/install-astronomy-launchers.py --check` | `python3 scripts/install-astronomy-launchers.py --install` |
| ROS 2 | `bash scripts/ros2-env.sh plan`, `status`, `check` | `up`, `shell`, `down` (same script) |
| RViz2 and ROS GUI | `bash scripts/ros2-env.sh rviz-plan`, `rviz-check` | `rviz-up`, `rviz`, `rqt`, `rqt-graph`, `rqt-console`, `rqt-image`, `plotjuggler`, `rviz-stop` (same script) |
| ROS launchers | `python3 scripts/install-ros2-launchers.py --check` | `python3 scripts/install-ros2-launchers.py --install` |
| TIO | `bash scripts/ros2-tio.sh plan`, `status` | `init`, `build`, `run` (same script) |
| Network tools | `bash scripts/install-network-monitoring.sh plan`, `verify` | `install`, `update` (same script) |
| NetAlertX | `bash scripts/netalertx.sh plan`, `check`, `logs` | `up`, `update`, `down` (same script, preserves volume) |
| NetAlertX API guard | `bash scripts/netalertx-api-guard.sh plan`, `check` | `enable`, `disable` (same script, narrow firewall rule) |
| Inventory | `bash scripts/inventory-snapshot.sh --plan` | `--capture`, `--compare BEFORE AFTER` (private files) |
| Conda | `bash scripts/conda-envs.sh plan`, `list` | `export NAME`, `restore NAME FILE --kind yaml --apply`, `verify NAME --profile fenicsx` (or sage; see guide) |
| Restic | `bash scripts/backup-personal.sh --plan` | `--init`, `--backup`, `--verify`, `--list`, `--restore ID` with reviewed options |
| Repository checks | `python3 -B tests/test-policy-legacy.py`, `python3 -B scripts/check-policy.py`, `python3 -B tests/test-policy.py` | None (CI/fixture checks) |

The full option syntax and prerequisites are in the
[workstation reference](workstation-reference.md), [ROS guide](../robotics/ros2/README.md),
[astronomy guide](astronomy-simulators.md), [network guide](network-monitoring.md),
[Conda guide](../conda/README.md), [inventory guide](../inventory/README.md)
and [backup guide](backup-and-recovery.md). Never run an apply command merely
because it appears in this index. Internal helpers are not user-facing entry points.
