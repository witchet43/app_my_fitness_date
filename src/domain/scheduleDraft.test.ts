import { strict as assert } from 'node:assert';
import { test } from 'node:test';
import { parseScheduleDrafts } from './scheduleDraft';

test('multiple recurring slots on different days retain distinct times', () => {
 const result = parseScheduleDrafts([
  { id:1,day:1,start:'07:00',end:'08:30' },
  { id:2,day:3,start:'19:00',end:'20:30' },
  { id:3,day:1,start:'18:00',end:'19:00' },
 ], true);
 assert.equal(result.ok,true);
 if (result.ok) assert.deepEqual(result.slots.map(s=>[s.day,s.startMinutes,s.endMinutes]),[
   [1,420,510],[1,1080,1140],[3,1140,1230]]);
});
test('overlapping time blocks for same weekday fail closed',()=>{
 const result = parseScheduleDrafts([
 {id:1,day:2,start:'07:00',end:'08:30'},
 {id:2,day:2,start:'08:00',end:'09:00'}],true);
 assert.equal(result.ok,false);
});
test('adjacent slots are permitted and schedule can be empty in strict other-gym mode',()=>{
 assert.equal(parseScheduleDrafts([],false).ok,true);
 assert.equal(parseScheduleDrafts([],true).ok,false);
 assert.equal(parseScheduleDrafts([
  {id:1,day:1,start:'07:00',end:'08:00'},
  {id:2,day:1,start:'08:00',end:'09:00'}],true).ok,true);
});
test('invalid and overnight intervals rejected; 24:00 allowed only as end',()=>{
 assert.equal(parseScheduleDrafts([{id:1,day:1,start:'24:00',end:'24:00'}],true).ok,false);
 assert.equal(parseScheduleDrafts([{id:1,day:1,start:'23:00',end:'01:00'}],true).ok,false);
 assert.equal(parseScheduleDrafts([{id:1,day:1,start:'23:00',end:'24:00'}],true).ok,true);
 assert.equal(parseScheduleDrafts([{id:1,day:7,start:'07:00',end:'08:00'}],true).ok,false);
});
test('limit fourteen and no duplicate blocks',()=>{
 const fifteen=Array.from({length:15},(_,i)=>({id:i,day:1,start:'07:00',end:'08:00'}));
 assert.equal(parseScheduleDrafts(fifteen,true).ok,false);
 assert.equal(parseScheduleDrafts(fifteen.slice(0,2),true).ok,false);
});
