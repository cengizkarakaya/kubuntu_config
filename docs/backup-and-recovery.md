# Encrypted personal recovery backup

Restic is opt-in; no bootstrap, sysup, scheduled jobs, prune or automatic restore. Install the Ubuntu signed package separately after APT review: `sudo apt install restic`. This is not a full-disk image. The script accepts only a local repository on a separate mounted filesystem outside HOME and the public Git tree. A different filesystem is not proof of a different physical disk: use a separate physical device, confirm mount with `findmnt`, and keep another offline copy. Restic encrypts repository data but a lost password means lost access. Keep the password securely outside Git and separately from the backup medium.

```bash
bash scripts/backup-personal.sh --plan
mkdir -p ~/.local/state/kubuntu-config
cp backups/personal-manifest.txt ~/.local/state/kubuntu-config/personal-manifest.txt
# EDIT and verify each entry; do not just use the candidate list unchanged.
# Replace /media/USER/BACKUP with your actual existing mounted external directory.
bash scripts/backup-personal.sh --plan --manifest ~/.local/state/kubuntu-config/personal-manifest.txt --repo /media/USER/BACKUP/restic-kubuntu
bash scripts/backup-personal.sh --init --repo /media/USER/BACKUP/restic-kubuntu
bash scripts/backup-personal.sh --backup --repo /media/USER/BACKUP/restic-kubuntu --manifest ~/.local/state/kubuntu-config/personal-manifest.txt
bash scripts/backup-personal.sh --list --repo /media/USER/BACKUP/restic-kubuntu
bash scripts/backup-personal.sh --verify --repo /media/USER/BACKUP/restic-kubuntu
```

Close Firefox, Anki, Zotero, IDEs and other apps writing data before backup. Missing paths are reported, not silently ignored; verify actual project locations, media and profile contents. The script does not follow symlink sources or cross nested filesystems. Docker named volumes (NetAlertX), root-owned system data and databases require separate consistent backup procedures. No archives or raw manifest containing private project names belong in Git.

For a recovery rehearsal create an empty staging directory, not a live profile or project, then restore into it. Restic restores recorded paths beneath the staging directory; inspect before selectively copying back. Never overwrite an existing working profile blindly.

```bash
mkdir -m700 ~/recovery-test
bash scripts/backup-personal.sh --restore latest --repo /media/USER/BACKUP/restic-kubuntu --target "$HOME/recovery-test"
```

CI uses a mocked restic CLI and does not prove encryption, media durability, consistency or data restore. Real `--backup`, `--verify` and sample restore with a disposable target are mandatory on-host acceptance checks. Do not mark verified until they pass.
