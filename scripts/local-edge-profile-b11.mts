/**
 * TRUE cross-layer QA: GoTrue JWT -> local Edge HTTP -> PostgREST -> RLS.
 * No hosted credentials, deploys, service keys, or real dating profiles.
 */
import assert from 'node:assert/strict';
import {randomUUID} from 'node:crypto';
import {createClient} from '@supabase/supabase-js';
import {waitForMailpitOtp} from './mailpit-otp';

const url=process.env.API_URL||'';
const publicKey=process.env.PUBLISHABLE_KEY||process.env.ANON_KEY||'';
const localEdge='http://127.0.0.1:54321/functions/v1/member-api-v26';
if(process.env.MFD_LOCAL_AUTH_E2E!=='LOCAL_ONLY' ||
 !/^http:\/\/127\.0\.0\.1:54321\/?$/.test(url) ||
 !publicKey ||
 process.env.MFD_DEV_URL || process.env.SUPABASE_SERVICE_ROLE_KEY){
 throw new Error('Refused: non-local Supabase or missing isolated QA flag');
}
const client=()=>createClient(url,publicKey,{
 auth:{autoRefreshToken:false,persistSession:false,detectSessionInUrl:false},
});
const a=client(),b=client(),anon=client();
const runId=randomUUID().slice(0,12);
const password='Pa!'+randomUUID()+'9Mm';
const email=(suffix:string)=>'qa-v13-'+suffix+'-'+runId+'@example.test';

async function request(method:string,path:string,token?:string,data?:unknown){
 const response=await fetch(localEdge+path,{
  method,headers:{
   'apikey':publicKey,
   ...(token?{'Authorization':'Bearer '+token}:{}),
   'Content-Type':'application/json',
   'Origin':'http://127.0.0.1:5173',
  },
  ...(data===undefined?{}:{body:JSON.stringify(data)}),
 });
 const value=await response.json().catch(()=>null);
 return {status:response.status,value,
  origin:response.headers.get('access-control-allow-origin')};
}
async function verified(clientInstance:ReturnType<typeof client>,identifier:string){
 const signup=await clientInstance.auth.signUp({email:identifier,password});
 assert.ifError(signup.error);
 assert.equal(signup.data.session,null);
 const otp=await waitForMailpitOtp(identifier,'MFD_QA_CONFIRM_CODE');
 const confirm=await clientInstance.auth.verifyOtp({
  email:identifier,token:otp,type:'signup',
 });
 assert.ifError(confirm.error);
 assert.ok(confirm.data.session?.access_token);
 return {uid:confirm.data.user!.id,token:confirm.data.session!.access_token};
}
const rhythm={
 answers:{
  sport:'running',frequency:'two_three',window:'early_morning',
  weekday:'home',sleep:'early_bird',intent:'long_term',together:'balanced',
 },
 additional_sports:['yoga'],
 weekends:['brunch','recovery'],
 interests:['books','music'],
 challenge:'My first 21 km',
 weeknight:'Light dinner',
 support:'Respect recovery days',
};
try{
 const options=await fetch(localEdge+'/v1/dating/rhythm',{
  method:'OPTIONS',
  headers:{Origin:'http://127.0.0.1:5173',
   'Access-Control-Request-Method':'PUT',
   'Access-Control-Request-Headers':'authorization,content-type'},
 });
 assert.ok(options.status>=200 && options.status<300,
  'CORS preflight may return 200 or 204 through the local proxy');
 // Kong local intercepts OPTIONS and may return '*' before our Edge
 // handler. This is acceptable ONLY for this disposable loopback QA proxy.
 // The member API's actual response still requires explicit origin and JWT.
 assert.ok(['*','http://127.0.0.1:5173'].includes(
  options.headers.get('access-control-allow-origin')??''),
  'Local proxy preflight must be CORS-compatible');
 const noToken=await request('GET','/v1/dating/rhythm');
 assert.equal(noToken.status,401,'Anonymous profile is not accessible');
 const personA=await verified(a,email('a'));
 const personB=await verified(b,email('b'));
 const noConsent=await request('PUT','/v1/dating/rhythm',personA.token,rhythm);
 assert.equal(noConsent.status,403,'Consent is mandatory before storing rhythm');
 const accepted=await request('POST','/v1/dating/consent',personA.token,{opt_in:true});
 assert.equal(accepted.status,201);
 assert.equal(accepted.value?.recorded,true);
 const saved=await request('PUT','/v1/dating/rhythm',personA.token,rhythm);
 assert.equal(saved.status,200,'Edge must successfully persist real JWT profile');
 assert.deepEqual(saved.value?.profile?.answers,rhythm.answers);
 const restored=await request('GET','/v1/dating/rhythm',personA.token);
 assert.equal(restored.status,200);
 assert.deepEqual(restored.value?.profile?.answers,rhythm.answers);
 assert.equal(restored.origin,'http://127.0.0.1:5173');
 const other=await request('GET','/v1/dating/rhythm',personB.token);
 assert.equal(other.status,200);
 assert.equal(other.value?.profile,null,
  'B must never view A owner-scoped lifestyle');
 const poisoned=await request('PUT','/v1/dating/rhythm',personB.token,{
  ...rhythm,user_id:personA.uid,
 });
 assert.equal(poisoned.status,400,
  'B cannot choose an arbitrary owner identity in JSON');
 const discovery=await request('GET','/v1/dating/b11/candidates',personA.token);
 assert.equal(discovery.status,403,'Dating release remains disabled');
 await a.auth.signOut({scope:'local'});
 const logged=await a.auth.signInWithPassword({
  email:email('a'),password,
 });
 assert.ifError(logged.error);
 assert.equal(logged.data.user?.id,personA.uid);
 const reload=await request('GET','/v1/dating/rhythm',
  logged.data.session!.access_token);
 assert.deepEqual(reload.value?.profile?.answers,rhythm.answers,
  'PostgREST must preserve preferences after signing out/in');
 const disabled=await request('POST','/v1/dating/disable',
  logged.data.session!.access_token,{});
 assert.equal(disabled.status,200);
 assert.equal(disabled.value?.status,'disabled');
 const after=await request('GET','/v1/dating/rhythm',
  logged.data.session!.access_token);
 assert.equal(after.status,200);
 assert.equal(after.value?.profile,null,
  'Profile must be erased on consent withdrawal');
 console.log('LOCAL EDGE B11 E2E PASS: HTTP CORS, JWT verify, separate consent, real profile write/read, BOLA, re-login persistence, release gate, optout purge');
}finally{
 await Promise.allSettled([
  a.auth.signOut({scope:'local'}),
  b.auth.signOut({scope:'local'}),
  anon.auth.signOut({scope:'local'}),
 ]);
}
