import unittest
from fitted_change_scope import classify

class ScopeTests(unittest.TestCase):
    def test_ui(self):
        d=classify(["apps/flutter_client/lib/main.dart"])
        self.assertTrue(d["flutter"])
        self.assertFalse(d["database"])
        self.assertFalse(d["edge"])
    def test_db(self):
        d=classify(["supabase/migrations/202611180000_change.sql"])
        self.assertTrue(d["database"])
        self.assertTrue(d["full_gate"])
        self.assertFalse(d["flutter"])
    def test_edge(self):
        d=classify(["supabase/functions/fit-ia-v1/index.ts"])
        self.assertTrue(d["edge"])
    def test_docs(self):
        d=classify(["docs/example.md"])
        self.assertTrue(d["documentation_only"])
        self.assertFalse(d["flutter"])
    def test_unknown_is_conservative(self):
        self.assertTrue(classify(["new_app/main.dart"])["flutter"])

if __name__=="__main__": unittest.main()
