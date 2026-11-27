# Private KDE Application Launcher backup

From the repository root:

```bash
bash scripts/menu-backup.sh --capture
bash scripts/menu-backup.sh --prepare-private
```

The raw capture and portable copy are stored in `menu-current` and
`menu-portable` under `${XDG_STATE_HOME:-$HOME/.local/state}/kubuntu-config`.
Previous copies are retained. Review the contents locally and protect both
directories with an independent encrypted backup. Never commit either snapshot;
the old public staging action is disabled. HOME substitution is not anonymization.

After reinstalling, recover the private portable directory at the same relative
state location (owned by the desktop user, mode 0700). Review commands and paths
before restoring:

```bash
bash scripts/menu-backup.sh --plan-restore
bash scripts/menu-backup.sh --restore
```

Restore renders `@HOME@`, rejects unsupported custom XDG destinations and
backs up conflicts before replacing files. It requires typed confirmation.
Only launcher files and menu categories are captured; packages, executables,
icons, other KDE settings and application data require separate recovery.
