/**
 * Closed-beta readiness is evidence-based and DENY-BY-DEFAULT.
 * This is a RELEASE POLICY check, not user authorization.
 * A green CI build alone must never unlock public registration.
 */
export const REQUIRED_GATES=[
  'hosted_email_configuration',
  'external_age_verification',
  'staffed_moderation',
  'legal_privacy_retention',
  'real_auth_erasure_e2e',
  'physical_android_qa',
  'physical_ios_qa',
  'independent_security_review',
  'support_and_incident_response',
] as const;
export type GateId=typeof REQUIRED_GATES[number];
export type GateStatus='pending'|'verified';
export type GateEvidence={status:GateStatus;evidence_url:string|null;verified_at:string|null};
export type CandidateManifest={
 schema_version:1;
 candidate:'v20-deployment-dev';
 project_ref:'jtrdvnwbxpfdnbzasvcj';
 release_channel:'not_published';
 environment:'development';
 gates:Record<GateId,GateEvidence>;
};
export type Readiness={
 valid:boolean;
 betaReady:boolean;
 blockers:GateId[];
 errors:string[];
};
const gateSet=new Set<string>(REQUIRED_GATES);
const validDate=(value:string):boolean=>Number.isFinite(Date.parse(value)) &&
  /^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d/.test(value);
export function evaluateCandidateManifest(raw:unknown):Readiness {
 const errors:string[]=[];
 const blockers:GateId[]=[];
 if(!raw||typeof raw!=='object'||Array.isArray(raw))return{
   valid:false,betaReady:false,blockers:[...REQUIRED_GATES],errors:['Manifest must be an object'],
 };
 const obj=raw as Record<string,unknown>;
 if(obj.schema_version!==1)errors.push('Unsupported schema_version');
 if(obj.candidate!=='v20-deployment-dev')errors.push('Wrong candidate');
 if(obj.project_ref!=='jtrdvnwbxpfdnbzasvcj')errors.push('Wrong project');
 if(obj.environment!=='development'||obj.release_channel!=='not_published'){
   errors.push('Unapproved environment or release channel');
 }
 const entries=obj.gates;
 if(!entries||typeof entries!=='object'||Array.isArray(entries)){
   return{valid:false,betaReady:false,blockers:[...REQUIRED_GATES],
     errors:[...errors,'Missing gates object']};
 }
 const gs=entries as Record<string,unknown>;
 for(const k of Object.keys(gs)){
   if(!gateSet.has(k))errors.push('Unknown gate: '+k);
 }
 for(const id of REQUIRED_GATES){
   const item=gs[id];
   if(!item||typeof item!=='object'||Array.isArray(item)){
     errors.push('Missing or invalid gate: '+id);blockers.push(id);continue;
   }
   const g=item as Record<string,unknown>;
   if(g.status==='pending'){
     blockers.push(id);
     if(g.evidence_url!==null||g.verified_at!==null){
       errors.push('Pending gate must not include claimed evidence: '+id);
     }
   }else if(g.status==='verified'){
     if(typeof g.evidence_url!=='string'||!/^https:\/\//.test(g.evidence_url)
       ||typeof g.verified_at!=='string'||!validDate(g.verified_at)){
       errors.push('Verified gate needs dated HTTPS evidence: '+id);blockers.push(id);
     }
   }else{
     errors.push('Unknown gate status: '+id);blockers.push(id);
   }
 }
 return{valid:errors.length===0,betaReady:errors.length===0&&blockers.length===0,
   blockers,errors};
}
