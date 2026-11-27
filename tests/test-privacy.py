#!/usr/bin/env python3
"""Test privacy checks with synthetic Git objects, never real host data."""
import importlib.util
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("privacy_checker", ROOT / "scripts/check-privacy.py")
CHECK = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(CHECK)


class PrivacyTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.git("init", "-q")
        self.write("README.md", b"General setup\n")

    def git(self, *args):
        return subprocess.run(
            ["git", "-C", str(self.root), "-c", "core.hooksPath=/dev/null",
             "-c", "user.name=Fixture", "-c", "user.email=fixture@example.invalid",
             "-c", "commit.gpgSign=false", *args],
            check=True, capture_output=True,
        )

    def write(self, path, data):
        target = self.root / path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(data)
        self.git("add", "-f", "--", path)

    def findings(self):
        return CHECK.scan(self.root)[1]

    def test_generic_content(self):
        self.write("docs/example.md", b"Example: 192.168.1.0/24; $HOME/.config\n")
        self.write("inventory/README.md", b"Instructions only\n")
        self.write("conda/locks/README.md", b"Instructions only\n")
        self.write("conda/environments/science.env.yml", b"name: science\n")
        self.assertEqual(self.findings(), [])

    def test_private_paths(self):
        for path in ("backups/application-launcher/snapshot/sample.desktop",
                     "conda/environments/sample.full.yml", "conda/locks/sample.txt",
                     "inventory/capture.json", "hosts/private/profile.md",
                     "docs/host-acceptance-example.md", "data/.env",
                     "data/hidden.bundle", "menu-portable/sample.menu"):
            self.write(path, b"synthetic\n")
            self.assertIn(("private-path", path), self.findings())

    def test_staged_not_worktree(self):
        self.write("notes.md", b"/" + b"home/" + b"synthetic-user/data")
        (self.root / "notes.md").write_bytes(b"clean but not staged")
        self.assertIn(("absolute-home", "notes.md"), self.findings())
        self.git("add", "notes.md")
        self.assertEqual(self.findings(), [])

    def test_container_scope(self):
        example = b"/" + b"home/" + b"rosdev/.config"
        self.write("robotics/ros2/Dockerfile", example)
        self.assertEqual(self.findings(), [])
        self.write("notes.md", example)
        self.assertIn(("absolute-home", "notes.md"), self.findings())

    def test_mac(self):
        self.write("notes.md", b":".join([b"02", b"11", b"22", b"33", b"44", b"55"]))
        self.assertIn(("mac-address", "notes.md"), self.findings())

    def test_binary_and_symlink(self):
        self.write("raw.dat", b"\0\xff")
        (self.root / "link").symlink_to("README.md")
        self.git("add", "link")
        self.assertIn(("nontext-blob", "raw.dat"), self.findings())
        self.assertIn(("nonregular-entry", "link"), self.findings())

    def test_oversize(self):
        self.write("big.txt", b"x" * (CHECK.MAX_BYTES + 1))
        self.assertIn(("oversize-blob", "big.txt"), self.findings())

    def test_committed_tree(self):
        self.git("commit", "-qm", "clean fixture")
        self.write("inventory/private.json", b"synthetic")
        self.assertEqual(CHECK.scan(self.root, "HEAD")[1], [])
        self.assertIn(("private-path", "inventory/private.json"), self.findings())

    def test_public_diagnostics_redacted(self):
        self.write("inventory/synthetic-private-name.json", b"synthetic-private-value")
        proc = subprocess.run(["python3", str(ROOT / "scripts/check-privacy.py"),
                               "--root", str(self.root), "--index"], capture_output=True)
        self.assertEqual(proc.returncode, 1)
        self.assertNotIn(b"synthetic-private", proc.stdout + proc.stderr)
        self.assertIn(b"private-path", proc.stderr)


if __name__ == "__main__":
    unittest.main()
