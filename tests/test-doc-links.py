import importlib.util
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("links", ROOT / "scripts/check-doc-links.py")
LINKS = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(LINKS)


class LinkTests(unittest.TestCase):
    def setUp(self):
        temp = tempfile.TemporaryDirectory()
        self.addCleanup(temp.cleanup)
        self.root = Path(temp.name)
        (self.root / "guide.md").write_text("# A heading\n## Same\n## Same\n", encoding="utf-8")
        (self.root / "file name.txt").touch()

    def check_text(self, text):
        (self.root / "README.md").write_text(text, encoding="utf-8")
        return LINKS.check(self.root, [Path("README.md")])

    def test_valid(self):
        self.assertEqual(self.check_text("[guide](guide.md#a-heading) [duplicate](guide.md#same-1)\n"
                                         "[file](<file name.txt>) [online](https://example.org)\n"
                                         "[ref]: guide.md\n"), [])

    def test_invalid(self):
        errors = self.check_text("[missing](bad.md) [anchor](guide.md#absent) [escape](../bad.md)\n"
                                 "[ref]: missing.md\n")
        self.assertEqual(len(errors), 4)

    def test_code_examples_ignored(self):
        fence = chr(96) * 3
        self.assertEqual(self.check_text(f"{fence}md\n[example](missing.md)\n{fence}\n"
                                         f"{chr(96)}[example](missing.md){chr(96)}\n"), [])

    def test_relative_from_nested(self):
        folder = self.root / "docs"
        folder.mkdir()
        (folder / "page.md").write_text("[guide](../guide.md#same)\n", encoding="utf-8")
        self.assertEqual(LINKS.check(self.root, [Path("docs/page.md")]), [])


if __name__ == "__main__":
    unittest.main()
