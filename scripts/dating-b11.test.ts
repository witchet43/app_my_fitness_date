import test from "node:test";
import assert from "node:assert/strict";
import {validateRhythmB11,reasonCatalogB11} from "../supabase/functions/member-api-v26/rhythm_validation_b11";

const candidate = () => ({
 answers: {
   sport:"running", frequency:"two_three", window:"morning",
   training_mode:"consistent", weekday:"home", sleep:"early_bird",
   intent:"long_term", together:"balanced",
 },
 additional_sports:["yoga","hyrox"],
 weekends:["brunch","recovery"],
 interests:["music","pets"],
 challenge:"Primer medio maratón",weeknight:"Algo tranquilo",
 support:"Respeto de días de preparación",
});

test("real FITTED profile accepts only explicit public preference codes",()=>{
 const verified=validateRhythmB11(candidate());
 assert.ok(verified);
 assert.equal(verified.answers.sport,"running");
 assert.deepEqual(verified.additional_sports,["yoga","hyrox"]);
});

test("no gym, exact schedule, owner-id, unreviewed fields or duplicate tokens",()=>{
 for(const attempt of [
   {...candidate(),gym_id:"secret"},
   {...candidate(),user_id:"somebody-else"},
   {...candidate(),answers:{...candidate().answers,privacy:"allow_same_gym"}},
   {...candidate(),answers:{...candidate().answers,exact_location:"home"}},
   {...candidate(),answers:{...candidate().answers,frequency:"06:32"}},
   {...candidate(),additional_sports:["yoga","yoga"]},
   {...candidate(),weekends:["brunch","unapproved"]},
   {...candidate(),interests:["not_public"]},
   {...candidate(),support:"x".repeat(121)},
 ]){
   assert.equal(validateRhythmB11(attempt),null);
 }
});

test("compatibility reasons never reveal private gym or exact time",()=>{
 assert.equal(Object.keys(reasonCatalogB11).length,12);
 for(const reason of Object.values(reasonCatalogB11)){
   assert.ok(["high","medium","low"].includes(reason.priority));
   assert.ok(!reason.es.includes("%"));
   assert.ok(!reason.en.includes("%"));
   assert.ok(!/gym_id|latitude|longitude|exact|calories|body.?fat/i.test(
     reason.es+" "+reason.en));
 }
 assert.equal(reasonCatalogB11.sport_different_ok.priority,"low");
 assert.equal(reasonCatalogB11.intent_aligned.priority,"high");
});
