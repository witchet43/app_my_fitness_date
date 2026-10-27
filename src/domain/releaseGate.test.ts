import assert from 'node:assert/strict';
import test from 'node:test';
import {evaluateCandidateManifest,REQUIRED_GATES} from './releaseGate';
const pending=Object.fromEntries(REQUIRED_GATES.map(k=>[k,{
 status:'pending',evidence_url:null,verified_at:null,
}]));
const manifest=()=>({
 schema_version:1,candidate:'v19-integration-dev',project_ref:'jtrdvnwbxpfdnbzasvcj',
 release_channel:'not_published',environment:'development',gates:structuredClone(pending),
});
test('candidate is structurally valid but never beta ready by default',()=>{
 const r=evaluateCandidateManifest(manifest());
 assert.equal(r.valid,true);assert.equal(r.betaReady,false);
 assert.deepEqual(r.blockers,REQUIRED_GATES);
});
test('neither CI nor an incomplete QA report can bypass gates',()=>{
 const copy=manifest();
 copy.gates.external_age_verification={status:'verified',evidence_url:null,verified_at:null};
 const r=evaluateCandidateManifest(copy);
 assert.equal(r.betaReady,false);assert.equal(r.valid,false);
});
test('project/channel drift is invalid',()=>{
 for(const patch of [
   {project_ref:'production'},
   {environment:'production'},
   {release_channel:'public'},
   {schema_version:2},
 ]){
   const r=evaluateCandidateManifest({...manifest(),...patch});
   assert.equal(r.valid,false);assert.equal(r.betaReady,false);
 }
});
test('each verified gate needs dated HTTPS evidence',()=>{
 const x=manifest();
 x.gates.hosted_email_configuration={
  status:'verified',evidence_url:'https://github.com/example/proof',
  verified_at:'2026-10-27T23:00:00Z',
 };
 const r=evaluateCandidateManifest(x);
 assert.equal(r.valid,true);assert.equal(r.betaReady,false);
 assert.equal(r.blockers.includes('hosted_email_configuration'),false);
});
test('all requirements must have independent evidence',()=>{
 const m=manifest();
 for(const gate of REQUIRED_GATES){
   m.gates[gate]={status:'verified',evidence_url:'https://github.com/example/proof-'+gate,
     verified_at:'2026-10-27T23:00:00Z'};
 }
 const r=evaluateCandidateManifest(m);
 assert.equal(r.valid,true);
 assert.equal(r.betaReady,true);
});
test('unknown and missing gate definitions fail closed',()=>{
 const missing=manifest();delete (missing.gates as Record<string,unknown>).physical_ios_qa;
 assert.equal(evaluateCandidateManifest(missing).valid,false);
 const extra=manifest();(extra.gates as Record<string,unknown>).unknown={status:'verified'};
 assert.equal(evaluateCandidateManifest(extra).valid,false);
});
