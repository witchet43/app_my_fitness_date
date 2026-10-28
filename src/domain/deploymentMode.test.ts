import assert from 'node:assert/strict';
import test from 'node:test';
import {isDemoOnlyFlag,shouldConnectBackend} from './deploymentMode';

const url='https://jtrdvnwbxpfdnbzasvcj.supabase.co';
const publicKey='sb_publishable_synthetic_test_only';
test('QA demo cannot connect to hosted, even with accidental env credentials',()=>{
 for(const backend of [
   [url,publicKey],
   ['http://127.0.0.1:54321',publicKey],
   [url,'sb_secret_FORBIDDEN'],
 ]){
   assert.equal(shouldConnectBackend('YES',...backend),false);
 }
 assert.equal(isDemoOnlyFlag('YES'),true);
 assert.equal(isDemoOnlyFlag('yes'),false);
});
test('published client never accepts secret keys or unsafe URLs',()=>{
 assert.equal(shouldConnectBackend(undefined,url,publicKey),true);
 for(const key of ['sb_secret_NOT_ALLOWED','eyJhbGciOiJSUzI1NiIs','',undefined]){
   assert.equal(shouldConnectBackend(undefined,url,key),false);
 }
 for(const uri of ['http://evil.tld','file:///tmp/a',
   'https://user:pass@project.supabase.co','https://project.supabase.co?q=secret',
   'https://project.supabase.co#fragment','']){
   assert.equal(shouldConnectBackend(undefined,uri,publicKey),false);
 }
});
test('local Supabase Auth remains possible only with explicit non-demo mode',()=>{
 assert.equal(shouldConnectBackend(undefined,'http://localhost:54321',publicKey),true);
 assert.equal(shouldConnectBackend('YES','http://localhost:54321',publicKey),false);
});
