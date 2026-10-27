/**
 * Management API Auth configuration for the exact HOSTED DEV project only.
 * Usage:
 *   SUPABASE_ACCESS_TOKEN=... npm run auth:hosted:audit
 *   MFD_HOSTED_AUTH_APPROVAL=LOCK_jtrdvnwbxpfdnbzasvcj \
 *     SUPABASE_ACCESS_TOKEN=... npm run auth:hosted:lock
 *
 * NEVER log the API token, raw Auth config (may contain SMTP secrets),
 * private mail templates, or email addresses.
 */
import {readFile} from 'node:fs/promises';
import {HOSTED_DEV_PROJECT,hostedAuthPatch,inspectHostedAuth,
 type SafeAuthSettings} from '../src/domain/hostedAuthPolicy';

const mode=process.argv[2];
if(mode!=='audit'&&mode!=='lock')throw Error('Expected audit or lock');
if(process.env.CI==='true'){
  throw Error('Cannot perform hosted management changes from GitHub Actions.');
}
const token=process.env.SUPABASE_ACCESS_TOKEN;
if(!token||token.length<15)throw Error('SUPABASE_ACCESS_TOKEN required (operator machine only)');
if(process.env.MFD_HOSTED_AUTH_PROJECT &&
   process.env.MFD_HOSTED_AUTH_PROJECT!==HOSTED_DEV_PROJECT){
  throw Error('Project mismatch: refusing cross-project operation');
}
const templates={
 confirmation:await readFile(new URL('../supabase/templates/hosted-confirmation.html',import.meta.url),'utf8'),
 recovery:await readFile(new URL('../supabase/templates/hosted-recovery.html',import.meta.url),'utf8'),
};
const patch=hostedAuthPatch(templates);
const url='https://api.supabase.com/v1/projects/'+HOSTED_DEV_PROJECT+'/config/auth';
const common={Authorization:'Bearer '+token,Accept:'application/json'};
async function inspectRemote():Promise<SafeAuthSettings>{
 const res=await fetch(url,{headers:common,signal:AbortSignal.timeout(15000)});
 if(!res.ok)throw Error('Auth config GET failed with HTTP '+res.status);
 return await res.json() as SafeAuthSettings;
}
const initial=inspectHostedAuth(await inspectRemote(),templates);
console.log(JSON.stringify({project:HOSTED_DEV_PROJECT,mode,configuration:initial},null,2));
if(mode==='audit'){
  if(!initial.ready)process.exitCode=2;
}else{
  if(process.env.MFD_HOSTED_AUTH_APPROVAL!=='LOCK_'+HOSTED_DEV_PROJECT){
    throw Error('Explicit MFD_HOSTED_AUTH_APPROVAL=LOCK_'+HOSTED_DEV_PROJECT+' required');
  }
  if(initial.ready){
    console.log('Already matches verified locked policy; no changes made.');
  }else{
    const res=await fetch(url,{
      method:'PATCH',
      headers:{...common,'Content-Type':'application/json'},
      body:JSON.stringify(patch),
      signal:AbortSignal.timeout(15000),
    });
    if(!res.ok)throw Error('Auth config PATCH failed with HTTP '+res.status);
    // Do not print the PATCH response: Auth config can include secrets.
    const verified=inspectHostedAuth(await inspectRemote(),templates);
    console.log(JSON.stringify({project:HOSTED_DEV_PROJECT,
      action:'lock_signup_and_install_otp_templates',configuration:verified},null,2));
    if(!verified.ready)throw Error('Hosted Auth policy did not verify after update');
  }
}
