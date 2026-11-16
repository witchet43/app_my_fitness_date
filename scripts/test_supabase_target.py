#!/usr/bin/env python3
"""No-credentials regression for correct Supabase environment targeting."""
import importlib.util, pathlib, unittest

MODULE_PATH=pathlib.Path(__file__).resolve().parent/'check_supabase_target.py'
spec=importlib.util.spec_from_file_location('b11_target_guard',MODULE_PATH)
module=importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)

PRODUCTION='jtrdvnwbxpfdnbzasvcj'
DEV='z'*20

class SupabaseTargetGuardTests(unittest.TestCase):
    def test_prod_is_never_dev(self):
        with self.assertRaisesRegex(ValueError,'DEV not provisioned'):
            module.validate('development',PRODUCTION)
    def test_prod_ref_only_for_prod(self):
        self.assertTrue(module.validate('production',PRODUCTION))
    def test_future_dev_must_differ_from_production(self):
        fake={'environments':{
          'production':{'project_id':PRODUCTION},
          'development':{'project_id':DEV}
        }}
        self.assertTrue(module.validate('development',DEV,fake))
        with self.assertRaisesRegex(ValueError,'Production Supabase ref'):
            module.validate('development',PRODUCTION,fake)
    def test_wrong_prod_blocked(self):
        with self.assertRaisesRegex(ValueError,'mismatches'):
            module.validate('production',DEV)
    def test_unknown_environment_blocked(self):
        with self.assertRaisesRegex(ValueError,'Unknown environment'):
            module.validate('testing',PRODUCTION)

if __name__=='__main__':
    unittest.main()
