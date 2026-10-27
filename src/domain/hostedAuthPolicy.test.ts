import {URL} from 'node:url';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import test from 'node:test';
import {canShowQaSignup,hostedAuthPatch,inspectHostedAuth,
  HOSTED_DEV_PROJECT,SUBJECT_CONFIRM,SUBJECT_RECOVERY} from './hostedAuthPolicy';
const templates={
 confirmation:readFileSync(new URL('../../supabase/templates/hosted-confirmation.html',import.meta.url),'utf8'),
 recovery:readFileSync(new URL('../../supabase/templates/hosted-recovery.html',import.meta.url),'utf8'),
};
test('only explicit local QA may display sign-up, never hosted',()=>{
 assert.equal(canShowQaSignup('http://127.0.0.1:54321','LOCAL_QA_ONLY'),true);
 assert.equal(canShowQaSignup('http://localhost:54321/','LOCAL_QA_ONLY'),true);
 for(const url of [undefined,'','https://'+HOSTED_DEV_PROJECT+'.supabase.co',
  'https://evil.test','http://127.0.0.1:54322','http://127.0.0.1:54321.evil.com']){
   assert.equal(canShowQaSignup(url,'LOCAL_QA_ONLY'),false);
 }
 assert.equal(canShowQaSignup('http://127.0.0.1:54321',undefined),false);
 assert.equal(canShowQaSignup('http://127.0.0.1:54321','true'),false);
});
test('both hosted templates carry OTP but no link/token hash or secrets',()=>{
 for(const body of Object.values(templates)){
   assert.ok(body.includes('{{ .Token }}'));
   assert.equal(body.split('{{ .Token }}').length,2);
   assert.equal(body.includes('{{ .ConfirmationURL }}'),false);
   assert.equal(body.includes('{{ .TokenHash }}'),false);
   assert.equal(/service_role|sb_secret_|SUPABASE_ACCESS_TOKEN/.test(body),false);
 }
});
test('hosted patch locks signup and retains email verification',()=>{
 const patch=hostedAuthPatch(templates);
 assert.deepEqual(Object.keys(patch).sort(),[
   'disable_signup','mailer_autoconfirm','mailer_subjects_confirmation',
   'mailer_subjects_recovery','mailer_templates_confirmation_content',
   'mailer_templates_recovery_content'].sort());
 assert.equal(patch.disable_signup,true);
 assert.equal(patch.mailer_autoconfirm,false);
 assert.equal(patch.mailer_subjects_confirmation,SUBJECT_CONFIRM);
 assert.equal(patch.mailer_subjects_recovery,SUBJECT_RECOVERY);
 assert.equal(Object.values(patch).some(v=>typeof v==='string'&&v.includes('sb_secret_')),false);
});
test('readiness does not pass on missing flags, wrong templates or public signup',()=>{
 const patch=hostedAuthPatch(templates);
 const good={...patch,external_email_enabled:true};
 assert.equal(inspectHostedAuth(good,templates).ready,true);
 assert.equal(inspectHostedAuth({...good,disable_signup:false},templates).ready,false);
 assert.equal(inspectHostedAuth({...good,mailer_autoconfirm:true},templates).ready,false);
 assert.equal(inspectHostedAuth({...good,external_email_enabled:false},templates).ready,false);
 assert.equal(inspectHostedAuth({...good,mailer_templates_recovery_content:'old'},templates).ready,false);
 assert.equal(inspectHostedAuth({},templates).ready,false);
});
