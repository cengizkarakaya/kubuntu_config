"""Independent fixtures for strict-mode policy; do not execute installers."""

import importlib.util
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("bash_policy", ROOT / "scripts/check-bash-modes.py")
CHECK = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(CHECK)


class BashPolicyTests(unittest.TestCase):
    def test_failfast_headers(self):
        for flags in ("set -Eeuo pipefail", "set -euo pipefail"):
            self.assertIsNone(CHECK.check_header("#!/bin/bash\n# comment\n" + flags, "failfast"))

    def test_missing_or_late_header(self):
        for source in ("echo hello\n", "set -u\n", "echo hello\nset -euo pipefail\n"):
            self.assertEqual(CHECK.check_header(source, "failfast"), "missing-failfast-header")

    def test_disabling_strict_option(self):
        for command in ("set +e", "set +o pipefail", "set +u"):
            self.assertEqual(CHECK.check_header("set -euo pipefail\n" + command, "failfast"),
                             "strict-option-disabled")

    def test_collect(self):
        self.assertIsNone(CHECK.check_header("set -uo pipefail\n", "collect"))
        self.assertEqual(CHECK.check_header("set -euo pipefail\n", "collect"),
                         "invalid-collector-header")

    def test_interactive(self):
        self.assertIsNone(CHECK.check_header("set -u\n", "interactive"))
        self.assertEqual(CHECK.check_header("set -euo pipefail\n", "interactive"),
                         "invalid-interactive-header")

    def test_sourced(self):
        self.assertIsNone(CHECK.check_header("helper() { return 1; }\n", "sourced"))
        for command in ("set -euo pipefail", "set +u", "set -o pipefail", "set -o errexit"):
            self.assertEqual(CHECK.check_header(command, "sourced"), "sourced-option-change")

    def test_discovery_and_stale_exception(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            subprocess.run(["git", "init", "-q", tmp], check=True)
            (root / "policy").mkdir()
            (root / "policy/bash-modes.toml").write_text(
                '[exceptions]\n"removed.sh" = {mode="collect", reason="fixture"}\n')
            (root / "new-command").write_text("#!/usr/bin/env bash\nset -u\n")
            (root / "new.sh").write_text("#!/bin/bash\nset -Eeuo pipefail\n")
            subprocess.run(["git", "-C", tmp, "add", "new-command", "new.sh"], check=True)
            count, errors = CHECK.violations(root)
            self.assertEqual(count, 2)
            self.assertIn("new-command: missing-failfast-header", errors)
            self.assertIn("removed.sh: stale exception", errors)

    def test_actual_sourced_ble_helper_preserves_options(self):
        for flags in ("set -euo pipefail", "set +e; set +u; set +o pipefail"):
            proc = subprocess.run(
                ["bash", "--noprofile", "--norc", "-c",
                 flags + '; before=$-; pipe=$(set -o | grep "^pipefail"); '
                 'source "$1"; [[ $- == "$before" && $(set -o | grep "^pipefail") == "$pipe" ]]',
                 "bash", str(ROOT / "scripts/ble-provider.sh")], capture_output=True, check=False)
            self.assertEqual(proc.returncode, 0)


if __name__ == "__main__":
    unittest.main()
