# Changelog

Changes to repository configuration and tooling are recorded here. This is not an installed-software version inventory or a statement of successful host verification.

## Unreleased

### Licensing

- Add MIT licensing for original project material, preserve the Nord license notice, and document third-party dependencies and unresolved import provenance.

### CI and security

- Convert remaining personal setup reports and observed application lists into generic recovery guidance; keep actual acceptance records private.

- Add a read-only shfmt audit for tracked Bash files, including extensionless commands; report formatting debt without rewriting shell source.

- Add independent signed-distribution Bandit scanning of tracked Python source, blocking high severity and incomplete scans while reporting other findings for review.

- Resolve reviewed Python lint findings and require the pinned Ruff default rule set in addition to the explicit correctness baseline.

- Enforce a documented Bash execution-mode baseline with independent negative fixtures; preserve existing runtime semantics and exception reasons.

- Add opt-in local pre-commit and pre-push guards with private literal matching and disposable Git integration tests; never overwrite existing hooks.

- Add a redacted committed-tree and staged-index privacy gate with synthetic Git fixtures; block known private artifacts and high-confidence personal path patterns.

- Add blocking compilation of all tracked Python files and checksum-pinned Ruff correctness checks; report default Ruff lint debt without automatic formatting.

- Pin NetAlertX to the official stable release and immutable multi-platform digest; document reviewed upgrades.

- Pin GitHub Actions checkout references and limit workflow token permissions.
- Add weekly Dependabot review for GitHub Actions references.
- Add a checksum-verified, redacted Gitleaks history scan.
- Add blocking ShellCheck warning-level checks; resolve findings before merging this work.

### Maintenance

- Replace host-specific hardware, window geometry, build metadata and acceptance reports with generic guidance; require explicit KWin placement parameters and retain private recovery records.

- Retain minimal generic Conda manifests; keep actual full exports and platform locks in private recovery storage only.

- Keep KDE menu captures and portable copies outside Git; disable public staging, remove tracked personal snapshots and test private recovery behavior.

- Respect the configured BreezeDark KDE palette and existing user-local ble.sh provider; keep fresh installs on signed APT and report manual provenance separately.

- Streamline README while preserving the full workstation reference; reorganize AGENTS without dropping rules; centralize commands and compatibility/release policy.
- Extract all legacy CI assertions, add independent declarative policy fixtures and offline local Markdown link checks.

- Add private workstation inventory/comparison, Conda export/recovery, manual build records and explicit encrypted Restic backup with recovery checklist. Actual host data and backup/restore validation remain outstanding.

- Template reviewed KDE launcher home paths and render them on explicit restore.

- Add non-reformatting EditorConfig defaults; preserve Arch-compatible dotfiles.

### Verification

- Document separate Conda and pip recovery limits; preserve minimal package requests without publishing host exports.

- Retain separate guidance for Conda smoke tests, numerical verification and private build provenance.

- Keep detailed host acceptance records private; CI success does not establish clean-install or encrypted recovery success.

- CI and host verification are tracked separately. A release or tag labelled verified requires recorded on-host acceptance checks; no such tag is created by this change.
