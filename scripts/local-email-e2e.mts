/**
 * Iteration 13: Real email confirmation and password recovery with local
 * GoTrue, Mailpit and JWT. No hosted project is contacted or modified.
 */
import assert from 'node:assert/strict';
import {randomUUID} from 'node:crypto';
import {createClient} from '@supabase/supabase-js';
import {waitForMailpitOtp} from './mailpit-otp';
const url=process.env.API_URL||'';
const key=process.env.PUBLISHABLE_KEY||process.env.ANON_KEY||'';
if(process.env.MFD_LOCAL_AUTH_E2E!=='LOCAL_ONLY'||
 !/^http:\/\/(127\.0\.0\.1|localhost):54321\/?$/.test(url)||
 !key||process.env.MFD_DEV_URL||process.env.SUPABASE_SERVICE_ROLE_KEY){
 throw new Error('Refused: local Supabase only, explicit flag required.');
}
const client=()=>createClient(url,key,{
 auth:{autoRefreshToken:false,persistSession:false,detectSessionInUrl:false},
});
const a=client(),b=client();
const email='qa-v13-c-'+randomUUID().slice(0,12)+'@example.test';
const oldPassword='Old!'+randomUUID()+'9Aa';
const newPassword='New!'+randomUUID()+'9Bb';
try{
 const signup=await a.auth.signUp({email,password:oldPassword});
 assert.ifError(signup.error);
 const uid=signup.data.user?.id;
 assert.ok(uid);
 assert.equal(signup.data.session,null,'Unverified signup must not have a session');
 const denied=await a.auth.signInWithPassword({email,password:oldPassword});
 assert.ok(denied.error,'Unconfirmed account must not login');

 const confirm=await waitForMailpitOtp(email,'MFD_QA_CONFIRM_CODE');
 const verified=await a.auth.verifyOtp({email,token:confirm,type:'signup'});
 assert.ifError(verified.error);
 assert.ok(verified.data.session&&verified.data.user?.id===uid);
 const who=await a.auth.getUser();
 assert.ifError(who.error);
 assert.equal(who.data.user.id,uid);
 await a.auth.signOut({scope:'local'});

 const logged=await a.auth.signInWithPassword({email,password:oldPassword});
 assert.ifError(logged.error);
 assert.equal(logged.data.user?.id,uid);
 await a.auth.signOut({scope:'local'});

 const reset=await a.auth.resetPasswordForEmail(email);
 assert.ifError(reset.error);
 const recovery=await waitForMailpitOtp(email,'MFD_QA_RECOVERY_CODE');
 const verifiedRecovery=await a.auth.verifyOtp({email,token:recovery,type:'recovery'});
 assert.ifError(verifiedRecovery.error);
 assert.ok(verifiedRecovery.data.session&&verifiedRecovery.data.user?.id===uid,
  'A successful recovery code must return an authenticated session');
 const updated=await a.auth.updateUser({password:newPassword});
 assert.ifError(updated.error);
 await a.auth.signOut({scope:'local'});

 const oldLogin=await b.auth.signInWithPassword({email,password:oldPassword});
 assert.ok(oldLogin.error,'Old password must be rejected');
 const newLogin=await b.auth.signInWithPassword({email,password:newPassword});
 assert.ifError(newLogin.error);
 assert.equal(newLogin.data.user?.id,uid);
 const data=await b.rpc('my_account_status');
 assert.ifError(data.error);
 assert.equal((data.data as {pending:boolean}).pending,false);

 // A recovery code must be single use.
 const reused=await a.auth.verifyOtp({email,token:recovery,type:'recovery'});
 assert.ok(reused.error,'Used OTP must not grant another session');
 console.log('EMAIL AUTH E2E PASS: signup confirmation required; Mailpit OTP verified; password recovery and rotation; old credentials rejected; OTP single-use.');
}finally{
 await Promise.allSettled([a.auth.signOut({scope:'local'}),b.auth.signOut({scope:'local'})]);
}
