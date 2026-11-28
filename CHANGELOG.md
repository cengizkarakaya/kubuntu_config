# Changelog

Changes to repository configuration and tooling are recorded here. This is not an installed-software version inventory or a statement of successful host verification.

## Unreleased

### Privacy migration follow-up

- Replace the previous hosting repository with an independent
  repository while preserving the audited Git history and v1.0.0 tag.
- Delete the retired repository; historical pull-request records
  were not migrated.
- Verify anonymous API access, raw-file access and mirror cloning.
  Known superseded sensitive objects and historical PR references
  were inaccessible through the replacement public repository.
- Hosting-provider backups and previously downloaded third-party
  copies remain outside the verification scope.
- Remove obsolete local Git recovery copies while retaining the
  reviewed clean bundle and private workstation recovery archives.

### CI and security

- Require full commit SHA pinning for GitHub Actions and retain
  read-only default workflow token permissions.
- Enable secret scanning, push protection, Dependabot vulnerability
  alerts and security updates.
- Protect main with ten required CI checks, strict status checks,
  administrator enforcement and force-push/deletion restrictions.
- Upgrade actions/checkout to v7.0.1 with successful CI validation.
- Correct the NetAlertX Dependabot ecosystem to docker-compose and
  verify successful updater execution.
- Pin the ROS 2 Lyrical base image to an immutable upstream
  multi-platform digest and add weekly Dependabot Docker monitoring.
  Host rebuild and runtime verification remain separate acceptance
  requirements.
- Add conditional ROS 2 image CI validation: immutable reference
  checks, registry digest and architecture verification, an uncached
  amd64 build and an isolated non-root runtime smoke test.
  Physical host, arm64 build and graphical runtime validation remain
  separate acceptance requirements.
- Require ros2-image-validation as the eleventh protected-main
  status check, including administrator enforcement.
  Unrelated changes receive lightweight static pin validation
  without downloading or building the ROS image.
- Extend conditional ROS 2 CI to build the RViz2 graphical overlay
  without cache using the locally validated development image.
  Verify graphical package availability, non-root execution and
  runtime-directory permissions without GPU or display access.
  Physical OpenGL and interactive GUI validation remain separate
  acceptance requirements.

## v1.0.0 — repository milestone

This milestone documents the reviewed configuration and privacy migration. It is not a frozen upstream package snapshot, a clean-install acceptance record, or a verified disaster-recovery release.

### Privacy migration

- Rewrite the public branch history to remove targeted personal records and retire obsolete branches; keep private recovery copies outside the public checkout.
- Restore the reviewed configuration tree and update the exact historical Gitleaks false-positive fingerprint.
- Configure main-branch protection with required status checks and no force pushes.
- At this milestone, historical hosting-service PR references remained an unresolved exposure path. See the subsequent privacy migration follow-up above.

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

- Add blocking compilation of all tracked Python files and checksum-pinned Ruff correctness and default-rule checks.

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

- Template launcher HOME paths in private portable snapshots and render them on explicit restore.

- Add non-reformatting EditorConfig defaults; preserve Arch-compatible dotfiles.

### Verification

- Document separate Conda and pip recovery limits; preserve minimal package requests without publishing host exports.

- Retain separate guidance for Conda smoke tests, numerical verification and private build provenance.

- Keep detailed host acceptance records private; CI success does not establish clean-install or encrypted recovery success.

- CI and host verification are tracked separately. Clean-install acceptance, independent physical backup and full encrypted recovery remain unverified. See [compatibility matrix](docs/compatibility.md) and [release policy](docs/release-policy.md).
- Imported Arch parity provenance and the Yazi Nord flavor license remain unresolved; see [third-party notices](THIRD_PARTY_NOTICES.md). This milestone is not a comprehensive license clearance.
