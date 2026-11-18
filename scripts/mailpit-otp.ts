import assert from 'node:assert/strict';
import {setTimeout as sleep} from 'node:timers/promises';

const BASE='http://127.0.0.1:54324';
type MailList={messages?:Array<{ID:string;To?:Array<{Address?:string}>}>};
type MailMessage={Text?:string;HTML?:string};
export async function waitForMailpitOtp(email:string,marker:string):Promise<string>{
 if(!/^qa-v1[23]-[abc]-[a-z0-9-]+@example\.test$/.test(email) ||
  !['MFD_QA_CONFIRM_CODE','MFD_QA_RECOVERY_CODE'].includes(marker)){
   throw new Error('Local-only test email or message kind required');
 }
 if(process.env.MFD_LOCAL_AUTH_E2E!=='LOCAL_ONLY'||
   !/^http:\/\/(127\.0\.0\.1|localhost):54321\/?$/.test(process.env.API_URL||'')){
   throw new Error('Mailpit access allowed only for local Auth E2E');
 }
 for(let attempt=0;attempt<70;attempt++){
  try{
   const response=await fetch(BASE+'/api/v1/messages?limit=100');
   if(response.ok){
    const page=await response.json() as MailList;
    for(const item of (page.messages||[])){
     if(!(item.To||[]).some(to=>to.Address?.toLowerCase()===email.toLowerCase()))continue;
     if(!/^[A-Za-z0-9_-]+$/.test(item.ID))continue;
     const detail=await fetch(BASE+'/api/v1/message/'+encodeURIComponent(item.ID));
     if(!detail.ok)continue;
     const m=await detail.json() as MailMessage;
     const body=(m.Text||'')+'\n'+(m.HTML||'');
     const otp=body.match(new RegExp(marker+':\\s*(\\d{6,10})'));
     if(otp)return otp[1];
    }
   }
  }catch{ /* Mailpit startup may still be in progress. */ }
  await sleep(350);
 }
 assert.fail('Mailpit did not receive the expected local-only email OTP');
}
