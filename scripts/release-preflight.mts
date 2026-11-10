/**
 * Deployment preflight. Read-only. Refuses real-user distribution by default.
 * QA DEMO is a synthetic offline build; it NEVER initializes Supabase.
 */
import {createHash} from 'node:crypto';
import {readFileSync} from 'node:fs';
import {resolve,join} from 'node:path';
import {evaluateCandidateManifest} from '../src/domain/releaseGate';

const root=resolve(import.meta.dirname,'..');
const read=(path:string)=>readFileSync(join(root,path),'utf8');
const manifest=JSON.parse(read('release/readiness.json')) as unknown;
const evaluated=evaluateCandidateManifest(manifest);
const app=JSON.parse(read('app.json')) as {
  expo?:{slug?:string;name?:string;android?:{package?:string};ios?:{bundleIdentifier?:string}},
};
const eas=JSON.parse(read('eas.json')) as {
  build?:Record<string,{
    distribution?:string;
    env?:Record<string,string>;
    android?:{buildType?:string};
    ios?:{simulator?:boolean};
  }>,
};
const mode=process.argv[2];
const errors:string[]=[];
const expectedProject='jtrdvnwbxpfdnbzasvcj';
const devBundle='com.myfitnessdate.dev';

if(!evaluated.valid)errors.push(...evaluated.errors);
if((manifest as {project_ref?:unknown}).project_ref!==expectedProject){
 errors.push('Unexpected Supabase project ref');
}
if(app.expo?.slug!=='my-fitness-date'||app.expo?.name!=='my_fitness_date'||
 app.expo?.android?.package!==devBundle||
 app.expo?.ios?.bundleIdentifier!==devBundle){
 errors.push('Native identifier is not the development package');
}
const builds=eas.build??{};
const profiles=Object.keys(builds);
if(profiles.length!==2||
 !profiles.includes('qa-demo-android')||
 !profiles.includes('qa-demo-ios-simulator')){
 errors.push('Only 2 closed-offline QA profiles may be present before launch');
}
const android=builds['qa-demo-android'];
const ios=builds['qa-demo-ios-simulator'];
if(android?.distribution!=='internal'||android.android?.buildType!=='apk'||
 android.env?.EXPO_PUBLIC_MFD_DEMO_BUILD!=='YES'){
 errors.push('Android QA must produce an offline internal APK');
}
if(ios?.distribution!=='internal'||ios.ios?.simulator!==true||
 ios.env?.EXPO_PUBLIC_MFD_DEMO_BUILD!=='YES'){
 errors.push('iOS QA must target an offline simulator, not a public store/device');
}
for(const profile of Object.values(builds)){
 if(Object.keys(profile.env??{}).some(key=>/SUPABASE|SECRET|TOKEN/i.test(key))){
  errors.push('Unexpected credentials or backend URL in EAS build profile');
 }
}
const lock=JSON.parse(read('package-lock.json')) as {
  name?:string;version?:string;packages?:Record<string,{version?:string}>;
};
const pkg=JSON.parse(read('package.json')) as {name?:string;version?:string};
if(pkg.name!==lock.name||pkg.version!==lock.packages?.['']?.version){
 errors.push('package-lock.json does not match package.json');
}
const source=read('src/lib/supabase.ts');
if(!source.includes('isDemoOnlyFlag(process.env.EXPO_PUBLIC_MFD_DEMO_BUILD)')||
 !source.includes('shouldConnectBackend(')){
 errors.push('Demo-only runtime backend isolation is missing');
}
if(mode==='demo'){
 if(process.env.EXPO_PUBLIC_MFD_DEMO_BUILD!=='YES'){
  errors.push('EXPO_PUBLIC_MFD_DEMO_BUILD=YES required for demo build');
 }
 if(process.env.EXPO_PUBLIC_SUPABASE_URL||
    process.env.EXPO_PUBLIC_SUPABASE_PUBLISHABLE_KEY||
    process.env.SUPABASE_SERVICE_ROLE_KEY){
   errors.push('Demo build must not receive Supabase env variables');
 }
}else if(mode==='beta'){
 if(!evaluated.betaReady)errors.push('Beta release denied: '+evaluated.blockers.join(','));
 errors.push('No production profile configured; independent deployment approval needed');
}else{
 errors.push('Expected mode demo or beta (beta mode is intentionally blocked)');
}
const summary={
 candidate:(manifest as {candidate?:string}).candidate,
 deploymentMode:mode,
 distribution:mode==='demo'?'synthetic_offline_qa_only':'BLOCKED',
 appId:devBundle,
 lockSha256:createHash('sha256').update(read('package-lock.json')).digest('hex'),
 manifestValid:evaluated.valid,
 betaReady:evaluated.betaReady,
 blockers:evaluated.blockers,
 errors,
};
console.log(JSON.stringify(summary,null,2));
if(errors.length)process.exitCode=1;
