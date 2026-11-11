import tempfile
import unittest
from pathlib import Path

import build_v26_legal_pages


class LegalReleaseV26Tests(unittest.TestCase):
    def test_drafts_cannot_go_live(self):
        root = Path(__file__).resolve().parents[1]
        for slug, (relative, _) in build_v26_legal_pages.DOCUMENTS.items():
            draft = root / relative.replace("_APPROVED", "_DRAFT")
            self.assertTrue(draft.exists(), str(draft))
            with self.assertRaises(ValueError):
                build_v26_legal_pages.validate_approved(
                    draft.read_text(encoding="utf-8"), slug)

    def test_no_partial_publish_when_terms_absent(self):
        with tempfile.TemporaryDirectory() as d:
            base = Path(d)
            source = base / "docs/legal"
            source.mkdir(parents=True)
            source.joinpath("PRIVACY_V26_APPROVED.md").write_text(
                "# Aviso de privacidad\n## 1. Responsable\n" +
                "ARCO domicilio responsable atención de derechos " * 38 +
                "\nhttps://my-fitness-date.pages.dev/privacy/\n",
                encoding="utf-8")
            with self.assertRaises(FileNotFoundError):
                build_v26_legal_pages.stage(base, base / "dist")
            self.assertFalse((base / "dist/privacy/index.html").exists())

    def test_approved_pages_are_static_escaped_and_at_correct_routes(self):
        with tempfile.TemporaryDirectory() as d:
            base = Path(d)
            source = base / "docs/legal"
            source.mkdir(parents=True)
            for slug, (relative, _) in build_v26_legal_pages.DOCUMENTS.items():
                text = (
                    "# Documento My Fitness Date\n## 1. Responsabilidad\n" +
                    "ARCO derechos de privacidad identidad y domicilio " * 42 +
                    "\nPrueba segura <script>alert(1)</script>.\n" +
                    f"https://my-fitness-date.pages.dev/{slug}/\n"
                )
                (base / relative).write_text(text, encoding="utf-8")
            build_v26_legal_pages.stage(base, base / "dist")
            for slug in ("privacy", "terms"):
                page = (base / "dist" / slug / "index.html").read_text(encoding="utf-8")
                self.assertIn("<!doctype html>", page)
                self.assertIn(f'/{slug}/', page)
                self.assertIn("&lt;script&gt;", page)
                self.assertNotIn("<script>", page)


if __name__ == "__main__":
    unittest.main()
