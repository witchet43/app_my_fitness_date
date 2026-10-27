/**
 * Iteration 12: Real GoTrue/Auth + PostgREST + RLS E2E against a *local*
 * Supabase stack. This test does NOT use any hosted dev credentials.
 * It creates two synthetic users only in ephemeral local Auth.
 */
import assert from 'node:assert/strict';
import { randomUUID } from 'node:crypto';
import { createClient, type SupabaseClient } from '@supabase/supabase-js';
import { isPrivateCandidate, isOwnedExport } from '../src/domain/smokeContract';
import { readPendingFlag } from '../src/domain/sessionGate';
import { waitForMailpitOtp } from './mailpit-otp';

const apiUrl = process.env.API_URL || '';
const publicKey = process.env.PUBLISHABLE_KEY || process.env.ANON_KEY || '';
if (process.env.MFD_LOCAL_AUTH_E2E !== 'LOCAL_ONLY' ||
    !/^http:\/\/(127\.0\.0\.1|localhost):54321\/?$/.test(apiUrl) ||
    !publicKey ||
    process.env.MFD_DEV_URL ||
    process.env.SUPABASE_SERVICE_ROLE_KEY) {
  throw new Error('Refused: requires explicit LOCAL_ONLY and loopback Supabase API, no hosted credentials.');
}
const client = (): SupabaseClient => createClient(apiUrl, publicKey, {
  auth: { persistSession:false,autoRefreshToken:false,detectSessionInUrl:false },
});
const anon=client(), a=client(), b=client(), alternate=client();
const runId=randomUUID().slice(0,12);
const password='Qa!'+randomUUID()+'9xT';
const addr=(s:string)=>'qa-v12-'+s+'-'+runId+'@example.test';
const checks:string[]=[];
function required<T>(value:T|null|undefined,label:string):T {
 assert.ok(value,label);return value;
}
async function login(c:SupabaseClient,email:string):Promise<string>{
 const r=await c.auth.signInWithPassword({email,password});
 assert.ifError(r.error);
 assert.ok(r.data.session,'real GoTrue session must be issued');
 const remote=await c.auth.getUser();
 assert.ifError(remote.error);
 assert.equal(remote.data.user.id,r.data.user.id);
 return required(r.data.user.id,'user ID');
}
async function rpc(c:SupabaseClient,name:string,args?:Record<string,unknown>):Promise<any>{
 const r=await c.rpc(name,args);
 assert.ifError(r.error);
 return r.data;
}
async function saveDating(c:SupabaseClient,name:string,gymId:string,mode:string,start:number,end:number){
 await rpc(c,'save_dating_setup',{
   p_display_name:name,p_city:'Querétaro',p_sports:['Running'],
   p_dob:'1992-01-01',p_gym_id:gymId,p_mode:mode,
   p_weekly_slots:mode==='other_gyms'?[]:[{day:1,startMinutes:start,endMinutes:end}],
   p_dating_enabled:true,
 });
}
async function candidateIds(c:SupabaseClient){
 const rows=await rpc(c,'discover_dating_candidates',{p_limit:10}) as unknown[];
 assert.ok(Array.isArray(rows));
 assert.ok(rows.every(isPrivateCandidate),'No gym, DOB, mode or weekly schedule may leave Dating RPC');
 return rows.map(x=>(x as {user_id:string}).user_id);
}
try{
 const unauth=await anon.rpc('my_account_export');
 assert.ok(unauth.error,'anonymous export must fail');
 const anonPosts=await anon.from('community_posts').select('id').limit(1);
 assert.ok(anonPosts.error||anonPosts.data?.length===0,'anon post feed inaccessible');
 checks.push('anonymous access denied');

 // Sign-up uses real local Auth and returns actual signed JWTs.
 const users=await Promise.all([a.auth.signUp({email:addr('a'),password}),
                                b.auth.signUp({email:addr('b'),password})]);
 for(const u of users){
   assert.ifError(u.error);
   assert.ok(u.data.user&&!u.data.session,
     'local Auth must require email confirmation before issuing JWT');
 }
 const uidA=required(users[0].data.user?.id,'A id');
 const uidB=required(users[1].data.user?.id,'B id');
 for(const [user,email] of [[a,addr('a')],[b,addr('b')]] as const){
   const otp=await waitForMailpitOtp(email,'MFD_QA_CONFIRM_CODE');
   const verified=await user.auth.verifyOtp({email,token:otp,type:'signup'});
   assert.ifError(verified.error);
   assert.ok(verified.data.session,'email confirmation must issue a valid session');
 }
 checks.push('Mailpit confirmation OTP required for real local signup');
 assert.notEqual(uidA,uidB);

 const wrong=await alternate.auth.signInWithPassword({email:addr('a'),password:'wrong-password'});
 assert.ok(wrong.error,'incorrect password must fail');
 assert.equal((await login(alternate,addr('a'))),uidA);
 assert.equal((await login(b,addr('b'))),uidB);
 const authA=await a.auth.getUser();
 assert.ifError(authA.error);
 assert.equal(authA.data.user.id,uidA);
 checks.push('real Auth signup, invalid login, password login and JWT session');

 const statA=await rpc(a,'my_account_status');
 assert.equal(readPendingFlag(statA),false);
 assert.equal(readPendingFlag(await rpc(b,'my_account_status')),false);
 const statusB=await rpc(b,'my_account_export');
 assert.ok(isOwnedExport(statusB,uidB),'export B must only have B account identity');
 assert.equal((await rpc(a,'is_moderator')),false);
 checks.push('account gate, private export and moderator role');

 const profileA=await a.from('social_profiles').insert({
   user_id:uidA,display_name:'QA Runner A',city:'Querétaro',sports:['Running'],
 }).select('user_id').single();
 assert.ifError(profileA.error);
 const profileB=await b.from('social_profiles').insert({
   user_id:uidB,display_name:'QA Runner B',city:'Querétaro',sports:['Running'],
 }).select('user_id').single();
 assert.ifError(profileB.error);
 const post=await a.from('community_posts').insert({
   author_id:uidA,sport:'Running',body:'QA V12 local GoTrue post',
 }).select('id').single();
 assert.ifError(post.error);
 const postId=required(post.data?.id,'post id');
 const view=await b.from('community_posts').select('id,author_id,body').eq('id',postId);
 assert.ifError(view.error);
 assert.equal(view.data?.length,1);
 const spoof=await b.from('community_posts').insert({
   author_id:uidA,sport:'Running',body:'Prohibited impersonation',
 });
 assert.ok(spoof.error,'B must not author content as A');
 const remove=await b.from('community_posts').delete().eq('id',postId);
 assert.ifError(remove.error);
 const still=await a.from('community_posts').select('id').eq('id',postId);
 assert.ifError(still.error);assert.equal(still.data?.length,1);
 checks.push('real signed post create, read, impersonation denied, cross-account delete denied');

 const gyms=await a.from('gyms').select('id,name').order('name').limit(2);
 assert.ifError(gyms.error);
 assert.equal(gyms.data?.length,2);
 const gymA=required(gyms.data?.[0]?.id,'gym A');
 const gymB=required(gyms.data?.[1]?.id,'gym B');
 await saveDating(a,'QA Runner A',gymA,'same_gym_other_time',420,510);
 await saveDating(b,'QA Runner B',gymA,'same_gym_other_time',539,620);
 assert.equal((await candidateIds(a)).includes(uidB),false,'29-min gap prohibited');
 await saveDating(b,'QA Runner B',gymA,'same_gym_other_time',540,620);
 assert.equal((await candidateIds(a)).includes(uidB),true,'30-min gap permitted');
 await saveDating(b,'QA Runner B',gymA,'other_gyms',0,0);
 assert.equal((await candidateIds(a)).includes(uidB),false,'reciprocal consent required');
 await saveDating(b,'QA Runner B',gymB,'other_gyms',0,0);
 assert.equal((await candidateIds(a)).includes(uidB),true,'different gym candidate allowed');
 checks.push('real JWT Gym Shield same-gym 29/30m, reciprocity, different gym');

 await rpc(b,'request_account_deletion');
 assert.equal(readPendingFlag(await rpc(b,'my_account_status')),true);
 const hidden=await a.from('social_profiles').select('user_id').eq('user_id',uidB);
 assert.ifError(hidden.error);assert.equal(hidden.data?.length,0,'pending account must be hidden');
 assert.equal((await candidateIds(a)).includes(uidB),false,'pending deletion ineligible for Dating');
 const denied=await b.from('community_posts').insert({
   author_id:uidB,sport:'Running',body:'Should not be accepted during pending deletion',
 });
 assert.ok(denied.error,'pending account cannot publish');
 await rpc(b,'cancel_account_deletion');
 assert.equal(readPendingFlag(await rpc(b,'my_account_status')),false);
 const restored=await a.from('social_profiles').select('user_id').eq('user_id',uidB);
 assert.ifError(restored.error);assert.equal(restored.data?.length,1);
 const disabled=await b.rpc('my_dating_setup');
 assert.ifError(disabled.error);
 assert.equal((disabled.data as Array<{dating_enabled:boolean}>)[0]?.dating_enabled,false,
   'Dating must stay disabled following cancelled deletion');
 checks.push('pending deletion hide and publishing denied; cancel without Dating reconsent');

 await b.auth.signOut({scope:'local'});
 const gone=await b.auth.getSession();
 assert.ifError(gone.error);assert.equal(gone.data.session,null,'local session removed');
 assert.equal((await login(b,addr('b'))),uidB);
 const bPost=await b.from('community_posts').select('id').eq('id',postId);
 assert.ifError(bPost.error);assert.equal(bPost.data?.length,1);
 checks.push('local signout, login with new JWT and session identity preserved');

 console.log('LOCAL AUTH E2E PASS: '+checks.join(' | '));
} finally {
 // Supabase CLI runner destroys the entire local stack and volumes; this
 // also avoids leaving QA accounts on a connected remote Supabase project.
 await Promise.allSettled([a.auth.signOut({scope:'local'}),b.auth.signOut({scope:'local'}),
   alternate.auth.signOut({scope:'local'})]);
}
