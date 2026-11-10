"""Local tests for registry integrity and fail-closed release gate."""
import csv
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from check_saas_factory import REGISTER, validate, validate_existing_release_gates

class FactoryComplianceTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        with REGISTER.open(encoding="utf-8-sig", newline="") as handle:
            cls.rows = list(csv.DictReader(handle))

    def test_registry_has_all_219_unique_ids(self):
        self.assertEqual([], validate(self.rows))

    def test_release_is_not_approved_without_p0_evidence(self):
        failures = validate(self.rows, release=True)
        self.assertTrue(any("unresolved P0" in item for item in failures))

    def test_existing_beta_gates_still_block_release(self):
        reasons = validate_existing_release_gates()
        self.assertTrue(any("Beta gate pending" in reason for reason in reasons))
        self.assertTrue(any("not_published" in reason for reason in reasons))

    def test_duplicate_ids_are_rejected(self):
        failures = validate(self.rows + [self.rows[0]])
        self.assertTrue(any("Duplicate control" in item for item in failures))

    def test_claiming_compliance_without_evidence_fails(self):
        rows = [dict(r) for r in self.rows]
        rows[0]["estado"] = "CUMPLE"
        failures = validate(rows)
        self.assertTrue(any("CUMPLE requires owner and evidence" in x for x in failures))

if __name__ == "__main__":
    unittest.main()
