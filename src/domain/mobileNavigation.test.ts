import assert from 'node:assert/strict';
import test from 'node:test';
import {tabAccessible,tabsForAccount,type MobileNavigationState} from './mobileNavigation';

const base:MobileNavigationState={
 authenticated:true,verified:true,deletionPending:false,moderator:false,
};
test('demo navigation shows only public tabs',()=>{
 const tabs=tabsForAccount({...base,authenticated:false});
 assert.deepEqual(tabs.map(t=>t.id),['community','together','dating']);
 assert.equal(tabAccessible('account',{...base,authenticated:false}),false);
});
test('no data surfaces when account gate is unresolved',()=>{
 for(const pending of [true,false]){
  const state={...base,verified:false,deletionPending:pending,moderator:true};
  assert.deepEqual(tabsForAccount(state),[]);
  assert.equal(tabAccessible('admin',state),false);
 }
});
test('normal sessions expose community, activities, dating, inbox and account',()=>{
 assert.deepEqual(tabsForAccount(base).map(t=>t.id),[
 'community','together','dating','inbox','account']);
 assert.equal(tabAccessible('admin',base),false);
});
test('moderator tab is conditional and access is never granted by label alone',()=>{
 assert.deepEqual(tabsForAccount({...base,moderator:true}).map(t=>t.id),[
 'community','together','dating','inbox','admin','account']);
});
test('pending account deletion isolates a single account tab',()=>{
 for(const moderator of [true,false]){
  const state={...base,deletionPending:true,moderator};
  assert.deepEqual(tabsForAccount(state).map(t=>t.id),['account']);
  for(const tab of ['community','together','dating','inbox','admin'] as const){
   assert.equal(tabAccessible(tab,state),false);
  }
 }
});
