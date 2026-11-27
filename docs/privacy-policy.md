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
