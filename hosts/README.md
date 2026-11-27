# Optional host configuration

Keep hardware inventories, monitor arrangements, disk identifiers, real KWin
rule IDs and local paths in private recovery storage, not in Git.

Configure displays using KDE System Settings > Display and Monitor. Avoid
hard-coded connector IDs. Use Ubuntu's recommended signed NVIDIA driver only
when needed and after review. Do not automatically modify firmware, partitions,
EFI, or GRUB. For dual boot, use the read-only diagnostics first and back up
both drives.

## Optional native Alacritty window placement

The tool has no host-specific defaults. Choose the rule UUID and geometry
locally after reviewing the actual display layout and scaling. For an existing
rule use its private UUID; for a new rule generate one with `uuidgen`.

```bash
bash hosts/configure-alacritty-window.sh --help
# Set RULE_UUID, POSITION (x,y), SIZE (width,height) locally first.
bash hosts/configure-alacritty-window.sh --apply "$RULE_UUID" "$POSITION" "$SIZE"
```

The script preserves unrelated rules and their order, backs up the existing
configuration and verifies written keys. Reusing the same UUID and parameters
is idempotent. Position and size use Apply Initially, not last-position memory.
Never run this automatically from bootstrap or sysup. Keep the chosen values
and the original configuration in private backups. Live KWin behavior needs
a desktop test.
