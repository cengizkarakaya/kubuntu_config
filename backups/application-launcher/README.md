# KDE Application Launcher backup

The **actual personal snapshot is not present yet**. It must be captured on the user's Kubuntu machine and manually reviewed before GitHub upload.

Commands from the repository root:

```bash
bash scripts/menu-backup.sh --capture       # private local snapshot, does NOT upload
bash scripts/menu-backup.sh --stage-repo    # typed approval; stages in this repo
# Review every snapshot file (this repository is PUBLIC).
git add backups/application-launcher/snapshot
git commit -m 'Add reviewed KDE menu snapshot'
git push
```

After formatting and cloning the updated repository:

```bash
bash scripts/menu-backup.sh --plan-restore
bash scripts/menu-backup.sh --restore
```

Only user-specific .desktop, .directory and .menu files are captured. The snapshot does not include packages, ~/.config/kwinrc, browser profiles, passwords, display mappings or user data. Restore makes timestamped local backups of replaced files and rebuilds KDE's application cache. Prefer the original user name/home path because launcher Exec entries may have absolute paths.

**PUBLIC REPOSITORY WARNING:** arbitrary .desktop and .menu files can contain private URLs, paths or secrets. The script has a basic token-pattern guard; it cannot guarantee that files are safe to publish. Manually inspect before committing. Do not use this public repository for sensitive data.
