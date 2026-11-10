/**
 * Deployment mode is a property compiled into the JavaScript bundle.
 * DEMO_ONLY always prevents initializing a Supabase client, even when the
 * runner inadvertently contains real hosted environment variables.
 * This is not the server-side Auth signup or eligibility enforcement.
 */
export function isDemoOnlyFlag(flag:unknown):boolean{return flag==='YES';}
export function shouldConnectBackend(
 demoFlag:unknown,url:unknown,publishableKey:unknown,
):boolean{
 if(isDemoOnlyFlag(demoFlag))return false;
 if(typeof url!=='string'||typeof publishableKey!=='string')return false;
 try{
   const u=new URL(url);
   if(u.protocol!=='https:' && !(
     u.protocol==='http:'&&(u.hostname==='127.0.0.1'||u.hostname==='localhost')
   ))return false;
   if(u.username||u.password||u.search||u.hash)return false;
   if(!publishableKey.trim()||publishableKey.startsWith('sb_secret_')||
      publishableKey.startsWith('eyJ'))return false;
   return true;
 }catch{return false;}
}
