# Python security analysis

Bandit complements Ruff, syntax checks, Gitleaks and privacy policy.
CI installs the Ubuntu-packaged Bandit from signed APT repositories and
records its actual version and system Python version. The security job uses
Ubuntu 24.04 LTS and its system Python explicitly to avoid old Bandit/new
Python AST incompatibilities. A synthetic detection probe must succeed before
the real scan. Internal scanner errors remain blocking. This follows the distribution's supported
package rather than pinning an unreviewed PyPI dependency graph.

The initial gate scans every tracked Python source file, including tests and
ROS launch files. It ignores source-level nosec suppressions. High severity
findings at any confidence are blocking; medium and low severity findings are
reported for manual review. No blanket rule exclusions or automatic source
rewrites are introduced. Scan errors, malformed reports, missing file metrics
and inconsistent scanner exit status fail the job.

CI prints rule IDs, severity/confidence counts and file/line locations, not
source snippets or the JSON report. Findings are heuristics, not proof of an
exploitable vulnerability. For example, subprocess calls without a shell
can be legitimate when arguments and executable trust are controlled. Review
those call sites before deciding whether to harden them.

The scanner is a CI-only dependency; bootstrap and sysup do not install it.
For a local review with an existing trusted Bandit installation, from the
repository root:

```bash
git ls-files -z -- '*.py' | xargs -0 -r bandit --ignore-nosec
```

The local command prints source excerpts and reports all severities. Do not
publish raw local reports or run the scanner against personal state directories.
