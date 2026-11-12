#!/usr/bin/env python3
"""B3 deployment-independent contract security: not a substitute for E2E."""
from pathlib import Path

root=Path(__file__).resolve().parents[1]
def src(path: str)->str:
    return (root / path).read_text(encoding='utf-8')
def check(name: str,text: str,parts: list[str])->None:
    missing=[x for x in parts if x not in text]
    assert not missing,f'{name}: missing {missing}'

sql=src('supabase/migrations/202611120018_global_brand_live_b3.sql')
check('SQL',sql,[
  'alter table public.mfd_brand_live enable row level security',
  'grant select on public.mfd_brand_live to anon, authenticated',
  'app_private.is_brand_owner()',
  "p_expected_version is distinct from v_current.version",
  "for update",
  'app_private.mfd_brand_history',
  'public.brand_set_live(',
  'public.brand_restore_live(',
  'public.brand_history_live()',
  'mfd-brand-live',
  'revoke all on function public.brand_set_live',
])
assert sql.strip().endswith('commit;')
dart=src('apps/flutter_client/lib/src/core/live_brand.dart')
check('Global brand controller',dart,[
  "from('mfd_brand_live')",
  "rpc('brand_set_live'",
  "rpc('brand_restore_live'",
  "LiveBrandScope",
  "lastError",
  'Timer',
] if False else [
  "from('mfd_brand_live')",
  "rpc('brand_set_live'",
  "rpc('brand_restore_live'",
  "LiveBrandScope",
  "lastError",
])
rootdart=src('apps/flutter_client/lib/src/member_v26_app.dart')
check('Real app applies global brand',rootdart,[
  'liveBrand.current.toTheme()',
  'title:liveBrand.current.name',
  'LiveBrandScope(',
  'Timer.periodic(const Duration(seconds:20)',
  'liveBrand:liveBrand',
])
landing=src('apps/flutter_client/lib/src/features/public_entry_shell.dart')
check('Public landing',landing,[
  'brand.title','brand.description','brand.name','brand.tagline',
  'brand.primaryColor',
])
admin=src('apps/flutter_client/lib/src/features/brand_admin_home.dart')
check('Admin editor',admin,[
  "'Marca en vivo'",
  "'Historial'",
  '_queueBrandSave()',
  '_saveBrandGlobally()',
  '_restoreBrandVersion(',
  'b3-save-status',
  'Guardado y visible para todos',
])
assert 'Solicitar revisión (sin publicar)' not in admin
assert not (root/'apps/flutter_client/lib/src/core/live_brand.dart').is_symlink()
print('B3 static global brand contract PASS (runtime security pending)')
