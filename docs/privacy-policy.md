# Public repository privacy policy

Public Git contains reusable configuration, package requests, scripts and
general documentation, not actual host inventory, private recovery captures,
full Conda exports, exact installed-package locks or personal acceptance logs.
Keep those in private XDG state and independent encrypted backups.

Run before committing:

```bash
python3 -B scripts/check-privacy.py --index
python3 -B tests/test-privacy.py
```

CI scans the entire committed tree using `--tree HEAD`, not the working
directory. The checker rejects known private artifact paths, unexpected
absolute host HOME paths, MAC-address-shaped values, nonregular entries
(symlinks and submodules), non-UTF-8/NUL-containing files and blobs larger
than 2 MiB. The known ROS container HOME is allowed only in its specific
source and test files. Generic subnet examples are not blanket-banned.
Review any new binary asset or legitimate exception separately.

The default output contains rule IDs and counts only. Use
`--local-details` **only in a private local terminal** to see escaped file
paths. Matching values are never printed. Do not upload local diagnostics.

The gate is deliberately heuristic: it cannot recognize all personal
information, all encodings, hardware models or private network addresses.
It does not examine commit messages, author metadata, old history, GitHub
PR bodies, external caches or untracked files. Gitleaks is a separate
credential/history check. A successful scan is not permission to publish
personal data. Inspect staged changes manually. CI runs after a push has
already transferred data to GitHub; required checks protect merges, not
the initial disclosure. Local hooks are a separate opt-in safeguard.

Historical deletion requires a separate reviewed rewrite and local backups.
Never commit a list of real private identifiers as a public denylist.

## Optional local Git hooks

After reviewing the current source, explicitly install hooks from the checkout:

```bash
python3 -B scripts/privacy-hooks.py --install
python3 -B scripts/privacy-hooks.py --status
```

Installation copies the scanner and runner into the existing Git hooks
directory, so they do not depend on the staged or modified working-copy code.
It refuses existing hooks/guard files or a configured core.hooksPath; no hooks
are automatically installed by bootstrap/sysup. Status checks installed copies
against current source. To update or remove them, first inspect and back up the
four managed files (pre-commit, pre-push, privacy-guard-run.py,
privacy-guard-check.py), then remove only those confirmed managed files and
explicitly reinstall if needed. Never replace unrelated hooks.

The optional literal denylist lives only at
`${XDG_STATE_HOME:-$HOME/.local/state}/kubuntu-config/privacy-guard/denylist.txt`.
Its parent must be owned by the user and private (0700 recommended); the file
must be owned by the user, mode 0600, regular, UTF-8, outside Git.
Use one case-sensitive literal per line (at least four bytes, max 256 entries,
64 KiB total); blank and comment lines are ignored. No regex or public values
are supplied. Edit locally, never paste the list into a command or public log.
A missing list is allowed; an invalid or insecure existing list blocks the hook.

The pre-commit hook scans the index; pre-push checks outgoing commit trees,
including intermediate commits, plus denylist matches in commit metadata,
pushed ref names and direct annotated tag messages. A new branch/tag is
conservatively checked through its reachable history; legacy private content
may block a new ref until history is cleaned. Missing old remote objects block
push; inspect and fetch before retrying. Deleting refs transfers no new objects.
This is a local safety net, not a security boundary: hooks can be bypassed
or disabled, and other clones need their own installation. Never use
--no-verify to evade a finding. It does not replace a full secret/history audit.
