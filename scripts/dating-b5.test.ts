import assert from "node:assert/strict";
import test from "node:test";
import {validateDatingPreferencesB5} from
  "../supabase/functions/member-api-v26/dating_validation";

const base = {
  intent:"serious", frequency:"weekly",mode:"other_gyms",
  requested:true,sports:["running","hyrox"],
};

test("B5 ignores forged identity and private gym identifiers",()=>{
  const result=validateDatingPreferencesB5({
    ...base, user_id:"another-person", age_verified:true,
    gym_id:"private-gym", slots:[{"day":1}],
  });
  assert.ok(result);
  assert.equal(Object.hasOwn(result,"user_id"),false);
  assert.equal(Object.hasOwn(result,"age_verified"),false);
  assert.equal(Object.hasOwn(result,"gym_id"),false);
  assert.equal(Object.hasOwn(result,"slots"),false);
  assert.deepEqual(result.p_sports,["running","hyrox"]);
});

test("B5 rejects malformed choice, incorrect flag and extra sports",()=>{
  assert.equal(validateDatingPreferencesB5({...base,intent:"immediate_chat"}),null);
  assert.equal(validateDatingPreferencesB5({...base,requested:"true"}),null);
  assert.equal(validateDatingPreferencesB5({...base,sports:["running","running"]}),null);
  assert.equal(validateDatingPreferencesB5({...base,sports:["gym-name-private"]}),null);
  assert.equal(validateDatingPreferencesB5({...base,sports:Array(9).fill("running")}),null);
  assert.equal(validateDatingPreferencesB5(null),null);
  assert.equal(validateDatingPreferencesB5([]),null);
});

test("B5 accepts explicit opt-out and empty interests",()=>{
  const result=validateDatingPreferencesB5({
    ...base,requested:false,sports:[],mode:"same_gym_other_time",
  });
  assert.equal(result?.p_requested,false);
  assert.equal(result?.p_mode,"same_gym_other_time");
});
