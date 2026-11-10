import assert from 'node:assert/strict';
import test from 'node:test';
import {isPrivateCandidate,isOwnedExport} from './smokeContract';
test('candidate projection never leaks training, gym or age fields',()=>{
 const base={user_id:'a',display_name:'QA',city:'Qro',sports:['Running']};
 assert.equal(isPrivateCandidate(base),true);
 for(const field of ['gym_id','date_of_birth','weekly_slots','start_minute','email']) {
   assert.equal(isPrivateCandidate({...base,[field]:'secret'}),false);
 }
 assert.equal(isPrivateCandidate({display_name:'QA'}),false);
});
test('export belongs to requested identity and keeps expected fields',()=>{
 const base={export_version:1,account:{id:'a'},
   posts:[],organized_events:[],event_rsvps:[],blocked_user_ids:[],
   own_notifications:[],reports_i_submitted:[],appeals_i_submitted:[],training_slots:[]};
 assert.equal(isOwnedExport(base,'a'),true);
 assert.equal(isOwnedExport(base,'b'),false);
 assert.equal(isOwnedExport({...base,posts:null},'a'),false);
});
