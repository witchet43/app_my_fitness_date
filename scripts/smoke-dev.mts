/**
 * Read-only Supabase hosted DEV smoke checks with TWO existing controlled
 * QA accounts. No sign-up, no inserts, no settings changes, no deletion.
 *
 * Run manually using credentials injected locally (never commit .env):
 *   MFD_QA_RUN=CONFIRM_READ_ONLY_DEV npm run smoke:dev
 */
import assert from 'node:assert/strict';
import { createClient } from '@supabase/supabase-js';
import { isPrivateCandidate, isOwnedExport } from '../src/domain/smokeContract';

const EXPECTED_URL='https://jtrdvnwbxpfdnbzasvcj.supabase.co';
const env=process.env;
if(env.MFD_QA_RUN!=='CONFIRM_READ_ONLY_DEV' || env.MFD_DEV_URL!==EXPECTED_URL) {
  throw new Error('El smoke test exige confirmación explícita y la URL exacta del proyecto DEV.');
}
const required=['MFD_DEV_PUBLISHABLE_KEY','MFD_QA_A_EMAIL','MFD_QA_A_PASSWORD',
                'MFD_QA_B_EMAIL','MFD_QA_B_PASSWORD'] as const;
for(const name of required) {
  if(!env[name])throw new Error('Variable obligatoria ausente: '+name);
}
if(env.MFD_QA_A_EMAIL===env.MFD_QA_B_EMAIL) {
  throw new Error('Se requieren dos cuentas QA distintas.');
}
const key=env.MFD_DEV_PUBLISHABLE_KEY!;
if(key.startsWith('sb_secret_') || key.startsWith('eyJ')) {
  throw new Error('Solo usa una clave publishable; nunca una secret/service_role.');
}
const client=()=>createClient(EXPECTED_URL,key,{
  auth:{autoRefreshToken:false,persistSession:false,detectSessionInUrl:false},
});
const anon=client();
const a=client();
const b=client();
const outcomes:string[]=[];
try{
  const noSessionExport=await anon.rpc('my_account_export');
  assert.ok(noSessionExport.error,'Anon no debe poder exportar datos');
  outcomes.push('anon no puede exportar datos');

  const noSessionGyms=await anon.from('gyms').select('id').limit(1);
  assert.ok(noSessionGyms.error || (noSessionGyms.data||[]).length===0,
   'Anon no debe acceder al catálogo privado de miembros');
  outcomes.push('anon no puede consultar catálogo autenticado');

  async function checkAccount(c:ReturnType<typeof client>,email:string,password:string){
    const {data,error}=await c.auth.signInWithPassword({email,password});
    if(error)throw error;
    const uid=data.user?.id;
    assert.ok(uid && data.session,'La cuenta QA debe estar confirmada y activa');
    const remoteUser=await c.auth.getUser();
    assert.ifError(remoteUser.error);
    assert.equal(remoteUser.data.user.id,uid);

    const status=await c.rpc('my_account_status');
    assert.ifError(status.error);
    assert.equal(typeof (status.data as {pending?:unknown}|null)?.pending,'boolean');
    assert.equal((status.data as {pending:boolean}).pending,false,
      'Una cuenta QA con baja pendiente no puede usarse');

    const exported=await c.rpc('my_account_export');
    assert.ifError(exported.error);
    assert.ok(isOwnedExport(exported.data,uid),
      'El RPC de exportación debe contener únicamente la identidad actual');

    const inbox=await c.rpc('my_notifications',{p_limit:5});
    assert.ifError(inbox.error);
    assert.ok(Array.isArray(inbox.data));
    const moderator=await c.rpc('is_moderator');
    assert.ifError(moderator.error);
    assert.equal(typeof moderator.data,'boolean');
    return uid;
  }
  const uidA=await checkAccount(a,env.MFD_QA_A_EMAIL!,env.MFD_QA_A_PASSWORD!);
  const uidB=await checkAccount(b,env.MFD_QA_B_EMAIL!,env.MFD_QA_B_PASSWORD!);
  assert.notEqual(uidA,uidB);
  outcomes.push('dos sesiones reales y JWT válidos de QA');

  for(const c of [a,b]) {
    const gyms=await c.from('gyms').select('id,name,city').limit(5);
    assert.ifError(gyms.error);
    assert.ok((gyms.data||[]).length>=1);
    const posts=await c.from('community_posts')
      .select('id,author_id,sport,body').limit(5);
    assert.ifError(posts.error);
    const events=await c.from('sport_events')
      .select('id,title,starts_at').limit(5);
    assert.ifError(events.error);
    const profile=await c.rpc('my_dating_setup');
    assert.ifError(profile.error);
  }
  outcomes.push('comunidad, eventos y datos privados propios accesibles');

  // Discovery consumes one rate-limit token. Enable only if explicitly
  // requested; always ensure candidates expose no gym/schedule/DOB data.
  if(env.MFD_QA_PROBE_DATING==='YES_CONSUME_QUOTA') {
    const r=await a.rpc('discover_dating_candidates',{p_limit:10});
    assert.ifError(r.error);
    assert.ok((r.data||[]).every(isPrivateCandidate),
     'Discovery reveló campos de entrenamiento o datos de edad');
    assert.ok(!(r.data||[]).some(x=>x.user_id===uidA),
     'Discovery incluye a la propia cuenta');
    outcomes.push('discover no expone campos privados y excluye cuenta propia');
  }
  console.log('QA DEV OK: '+outcomes.join(' | '));
} finally {
  // Only clears the TWO temporary local sessions. No Auth users are removed.
  await Promise.allSettled([a.auth.signOut({scope:'local'}),b.auth.signOut({scope:'local'})]);
}
