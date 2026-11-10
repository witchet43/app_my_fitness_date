/** Static integration audit, no network, no credentials and no side effects. */
import {readFileSync,readdirSync,existsSync} from 'node:fs';
import {join,resolve} from 'node:path';
import {evaluateCandidateManifest} from '../src/domain/releaseGate';

const root=resolve(import.meta.dirname,'..');
const file=(p:string)=>readFileSync(join(root,p),'utf8');
const errors:string[]=[];
const warnings:string[]=[];
const manifest=JSON.parse(file('release/readiness.json'));
const readiness=evaluateCandidateManifest(manifest);
errors.push(...readiness.errors);
const workflow=file('.github/workflows/ci.yml');
const tracked=readdirSync(join(root,'supabase/migrations')).filter(n=>/^\d+_.+\.sql$/.test(n)).sort();
const applied=Array.from(workflow.matchAll(/-f supabase\/migrations\/(\d+_[A-Za-z0-9_]+\.sql)/g),m=>m[1]);
if(tracked.length<12)errors.push('Expected full historic SQL migration set; found '+tracked.length);
if(tracked.length!==applied.length||tracked.some((f,i)=>f!==applied[i])){
  errors.push('CI PostgreSQL migration sequence diverges from repository migrations');
}
const tests=readdirSync(join(root,'supabase/tests')).filter(n=>n.endsWith('_integration.sql'));
const executedTests=new Set(
 Array.from(workflow.matchAll(/-f supabase\/tests\/(\S+\.sql)/g),m=>m[1])
);
for(const testFile of tests){
 if(!executedTests.has(testFile))errors.push('Integration test missing from CI: '+testFile);
}
if(!workflow.includes('npx expo export --platform android')||
   !workflow.includes('npx expo export --platform ios')){
 errors.push('Both mobile bundles must be checked in CI');
}
const authWorkflow=file('.github/workflows/local-auth.yml');
for(const required of ['npm run test:auth:local','npm run test:auth:email:local',
                       'supabase@latest stop --no-backup']){
 if(!authWorkflow.includes(required))errors.push('Local Auth cleanup or E2E missing: '+required);
}
const app=JSON.parse(file('app.json'));
if(!/\.dev$/.test(app.expo?.android?.package??'')||
   !/\.dev$/.test(app.expo?.ios?.bundleIdentifier??'')){
 errors.push('Candidate bundle IDs must stay DEV-only');
}
const gitignore=file('.gitignore');
if(!gitignore.includes('.env.*')||!gitignore.includes('node_modules/')){
 errors.push('Missing required local file exclusions');
}
for(const path of ['App.tsx','src/lib/supabase.ts']){
 const content=file(path);
 if(/sb_secret_[A-Za-z0-9]/.test(content)||/SUPABASE_SERVICE_ROLE_KEY\s*=/.test(content)){
  errors.push('Potential privileged key in mobile source: '+path);
 }
}
if(!existsSync(join(root,'package-lock.json'))){
 warnings.push('Missing package-lock.json: npm install resolves floating dependency tree');
}else{
 const pkg=JSON.parse(file('package.json'));
 const lock=JSON.parse(file('package-lock.json'));
 if(lock.name!==pkg.name||lock.packages?.['']?.version!==pkg.version){
   errors.push('npm lockfile root metadata out of sync');
 }
}
if(authWorkflow.includes('supabase@latest')){
 warnings.push('Supabase CLI version floats; pin and renew after verifying a known working release');
}
const summary={
 candidate:manifest.candidate,
 environment:manifest.environment,
 branchPolicy:'draft_pr_only_no_merge',
 migrationsChecked:tracked.length,
 integrationTestsChecked:tests.length,
 buildChecks:['android_js_bundle','ios_js_bundle','postgresql','local_auth_mailpit'],
 manifestValid:readiness.valid,
 betaReady:readiness.betaReady,
 blockedGates:readiness.blockers,
 warnings,errors,
};
console.log(JSON.stringify(summary,null,2));
if(errors.length>0)process.exitCode=1;
if(process.argv.includes('--require-beta')&&!readiness.betaReady)process.exitCode=2;
