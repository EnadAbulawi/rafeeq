"""Regression checks for clean-clone content preparation."""
import json
from pathlib import Path
import tempfile
import unittest

from prepare_content import ROOT, json_digest, prepare


class ContentPreparationTest(unittest.TestCase):
    def test_json_fingerprint_preserves_text_but_ignores_serialization(self):
        value = {"text": "سُبْحَانَ الله", "count": 3}
        serialized = json.dumps(value, ensure_ascii=False, indent=2)
        self.assertEqual(json_digest(value), json_digest(json.loads(serialized)))
        self.assertNotEqual(json_digest(value), json_digest({**value, "count": 4}))

    def test_clean_output_matches_existing_dataset_and_keeps_local_edits(self):
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory)
            prepare(output, ROOT / "design")
            generated = output / "assets/data/adhkar.json"
            self.assertEqual(json.loads(generated.read_text(encoding="utf8")),
                             json.loads((ROOT / "assets/data/adhkar.json").read_text(encoding="utf8")))
            generated.write_text('[{"local": true}]', encoding="utf8")
            with self.assertRaises(ValueError):
                prepare(output, ROOT / "design")
            self.assertEqual(json.loads(generated.read_text(encoding="utf8")), [{"local": True}])


if __name__ == "__main__":
    unittest.main()
