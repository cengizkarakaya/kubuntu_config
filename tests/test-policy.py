"""Negative fixtures for policy failures; preserve independent safety checks."""

import importlib.util
import shutil
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("policy_checker", ROOT / "scripts/check-policy.py")
CHECK = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(CHECK)


class PolicyTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        for name in ("policy/invariants.toml", "packages/apt.txt", "packages/flatpak.tsv", "bootstrap.sh"):
            dest = self.root / name
            dest.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(ROOT / name, dest)

    def append(self, path, text):
        with (self.root / path).open("a", encoding="utf-8") as stream:
            stream.write("\n" + text + "\n")

    def test_current_policy(self):
        self.assertEqual(CHECK.violations(self.root), [])

    def test_forbidden_apt(self):
        self.append("packages/apt.txt", "dolphin-plugins")
        self.assertIn("apt: forbidden dolphin-plugins", CHECK.violations(self.root))

    def test_required_apt(self):
        file = self.root / "packages/apt.txt"
        file.write_text("\n".join(line for line in file.read_text().splitlines()
                                  if line.split("#", 1)[0].strip() != "yazi"))
        self.assertIn("apt: missing required yazi", CHECK.violations(self.root))

    def test_forbidden_flatpak(self):
        self.append("packages/flatpak.tsv", "net.cozic.joplin_desktop\tJoplin")
        self.assertIn("flatpak: forbidden net.cozic.joplin_desktop", CHECK.violations(self.root))

    def test_optional_tools_not_bootstrap(self):
        self.append("bootstrap.sh", "bash scripts/backup-personal.sh")
        self.assertIn("bootstrap: forbidden backup-personal.sh", CHECK.violations(self.root))


if __name__ == "__main__":
    unittest.main()
