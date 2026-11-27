#!/usr/bin/env python3
"""Local hook tests against disposable worktrees and a local bare remote."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class HookTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.base = Path(self.tmp.name)
        self.root = self.base / "repo"
        self.root.mkdir()
        self.env = dict(os.environ, XDG_STATE_HOME=str(self.base / "state"),
                        GIT_CONFIG_GLOBAL="/dev/null", GIT_CONFIG_NOSYSTEM="1")
        self.git("init", "-q", "-b", "main")
        self.git("config", "user.name", "Fixture")
        self.git("config", "user.email", "fixture@example.invalid")
        self.git("config", "commit.gpgSign", "false")
        (self.root / "README.md").write_text("Generic\n")
        self.git("add", "README.md")
        self.git("commit", "-qm", "initial")
        self.remote = self.base / "remote.git"
        self.git("init", "--bare", "-q", str(self.remote))
        self.git("remote", "add", "origin", str(self.remote))
        self.git("push", "-q", "origin", "main")
        self.git("config", "core.autocrlf", "false")

    def run_cmd(self, *args, ok=True):
        proc = subprocess.run(args, cwd=self.root, env=self.env, capture_output=True)
        if ok and proc.returncode:
            self.fail(proc.stderr.decode(errors="replace"))
        return proc

    def git(self, *args, ok=True):
        return self.run_cmd("git", *args, ok=ok)

    def install(self, ok=True):
        # Installer is normally used as an ordinary desktop user.
        return self.run_cmd("python3", "-B", str(ROOT / "scripts/privacy-hooks.py"), "--install", ok=ok)

    def denylist(self):
        parent = self.base / "state/kubuntu-config/privacy-guard"
        parent.mkdir(parents=True, mode=0o700)
        path = parent / "denylist.txt"
        path.write_text("fixture-private-value\n")
        path.chmod(0o600)
        return path

    def stage(self, text):
        (self.root / "notes.md").write_text(text)
        self.git("add", "notes.md")

    def test_hooks_and_private_denylist(self):
        self.denylist()
        self.install()
        self.stage("fixture-private-value")
        proc = self.git("commit", "-qm", "blocked", ok=False)
        self.assertNotEqual(proc.returncode, 0)
        self.assertNotIn(b"fixture-private-value", proc.stdout + proc.stderr)
        self.stage("public recipe")
        self.git("commit", "-qm", "clean")
        self.git("push", "-q", "origin", "main")
        self.run_cmd("python3", "-B", str(ROOT / "scripts/privacy-hooks.py"), "--status")

    def test_intermediate_commit_is_blocked(self):
        self.denylist()
        self.stage("fixture-private-value")
        self.git("commit", "-qm", "intermediate")
        self.stage("clean final tree")
        self.git("commit", "-qm", "cleanup")
        self.install()
        proc = self.git("push", "-q", "origin", "main", ok=False)
        self.assertNotEqual(proc.returncode, 0)
        self.assertNotIn(b"fixture-private-value", proc.stdout + proc.stderr)
        self.assertIn(b"Privacy guard", proc.stderr)
        self.assertEqual(self.git("rev-parse", "origin/main").stdout,
                         self.git("--git-dir", str(self.remote), "rev-parse", "main").stdout)

    def test_private_commit_message(self):
        self.denylist()
        self.stage("clean tree")
        self.git("commit", "-qm", "fixture-private-value")
        self.install()
        self.assertNotEqual(self.git("push", "origin", "main", ok=False).returncode, 0)

    def test_existing_hooks_are_preserved(self):
        existing = self.root / ".git/hooks/pre-commit"
        existing.write_text("existing hook\n")
        self.assertNotEqual(self.install(ok=False).returncode, 0)
        self.assertEqual(existing.read_text(), "existing hook\n")
        self.assertFalse((existing.parent / "pre-push").exists())

    def test_custom_hooks_path_refused(self):
        self.git("config", "core.hooksPath", str(self.base / "other"))
        self.assertNotEqual(self.install(ok=False).returncode, 0)
        self.assertFalse((self.base / "other").exists())

    def test_insecure_denylist_blocks_commit(self):
        path = self.denylist()
        path.chmod(0o644)
        self.install()
        self.stage("clean")
        self.assertNotEqual(self.git("commit", "-qm", "blocked", ok=False).returncode, 0)

    def test_annotated_tag_message(self):
        self.denylist()
        self.git("tag", "-a", "v-test", "-m", "fixture-private-value")
        self.install()
        self.assertNotEqual(self.git("push", "origin", "v-test", ok=False).returncode, 0)


if __name__ == "__main__":
    unittest.main()
