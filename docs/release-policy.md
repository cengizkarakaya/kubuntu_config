# Repository version and tag policy

Tags describe this configuration repository, not an immutable snapshot of
all upstream packages. APT candidates and official stable releases are
resolved at installation time where documented.

- Use an annotated `vMAJOR.MINOR.PATCH` tag for a reviewed, CI-passing repository
  milestone. Major: incompatible workflow changes; minor: new opt-in features;
  patch: fixes or documentation. Record changes in CHANGELOG.md.
- A host-verified tag such as `verified-kubuntu-26.10-YYYY-MM-DD` requires a
  recorded real acceptance run on that exact commit and OS, including relevant
  recovery and application checks. CI alone is insufficient.
- Never move an existing published tag or rewrite history. If a release is
  flawed, document the issue and create a new tag after the fix.
- Never label untested hardware, scientific results, Conda or personal backups
  as verified.

Example, **only after reviewing the commit, CI and selecting a new version**:

```bash
git fetch --tags origin
git switch main
git pull --ff-only
git status --short
git log -1 --oneline
git tag --list
# Example version; choose a new unused value after review.
git tag -a v1.0.0 -m "Reviewed repository milestone (CI only)"
git push origin refs/tags/v1.0.0
```

The tag commands do not install software or prove recoverability. Do not
publish a verified tag until the acceptance evidence in
[compatibility matrix](compatibility.md) is available. No tag is created by
this documentation change.
