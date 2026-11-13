/** B11: strict, owner-scoped three-rhythm payload. No gyms or routine times. */
export type RhythmDraftB11 = {
  answers: Record<string,string>;
  additional_sports: string[];
  weekends: string[];
  interests: string[];
  challenge: string;
  weeknight: string;
  support: string;
};
const enums: Record<string,readonly string[]> = {
  sport:["running","strength","cycling","hyrox","crossfit","boxing","yoga",
    "pilates","barre","swimming","hiking","climbing","racket","walking","other"],
  frequency:["flexible","two_three","four_five","six_plus"],
  window:["early_morning","morning","midday","evening","flexible"],
  training_mode:["recreational","consistent","focused","competitive"],
  training_with:["solo","friends","partner","mixed"],
  competitions:["never","sometimes","regularly"],
  weekday:["home","sometimes_out","often_out"],
  sleep:["early_bird","flexible","night_owl"],
  alcohol:["prefer_not","none","occasional","social","frequent"],
  food:["prefer_not","unrestricted","vegetarian","vegan","other"],
  travel:["flexible","train_away","rest_and_disconnect"],
  intent:["long_term","open_to_serious","intentional","exploring"],
  together:["balanced","more_together","independent"],
  train_partner:["often","sometimes","rarely","separately"],
  active_importance:["not_required","nice_to_have","important"],
  weekend:["early_training","brunch","nightlife","outdoors","recovery","family"],
  interests:["music","art","writing","gaming","cooking","pets","concerts",
    "outdoors","books","culture"],
};
function codes(input:unknown,values:readonly string[],limit:number):string[]|null {
  if(!Array.isArray(input)||input.length>limit ||
     input.some(x=>typeof x!=="string"||!values.includes(x))||
     new Set(input).size!==input.length) return null;
  return input as string[];
}
export function validateRhythmB11(input:unknown):RhythmDraftB11|null {
  if(!input||typeof input!=="object"||Array.isArray(input))return null;
  const data=input as Record<string,unknown>;
  if(Object.keys(data).some(k=>!["answers","additional_sports","weekends",
     "interests","challenge","weeknight","support"].includes(k)))return null;
  const answers=data.answers;
  if(!answers||typeof answers!=="object"||Array.isArray(answers))return null;
  const answer=answers as Record<string,unknown>;
  if(Object.entries(answer).some(([k,v])=>!enums[k] ||
      ["weekend","interests"].includes(k) ||
      typeof v!=="string"||!enums[k].includes(v)))return null;
  const sports=codes(data.additional_sports,enums.sport,7);
  const weekends=codes(data.weekends,enums.weekend,6);
  const interests=codes(data.interests,enums.interests,10);
  if(!sports||!weekends||!interests)return null;
  for(const [k,max] of [["challenge",100],["weeknight",120],["support",120]] as const){
    if(typeof data[k]!=="string"||data[k].length>max)return null;
  }
  return {
    answers:answer as Record<string,string>,
    additional_sports:sports,weekends,interests,
    challenge:data.challenge as string,
    weeknight:data.weeknight as string,
    support:data.support as string,
  };
}

export const reasonCatalogB11:Record<string,{es:string;en:string;priority:string}>={
  sleep_similar:{es:"Sus ritmos de descanso son parecidos.",en:"Their sleep rhythms align.",priority:"high"},
  sleep_discuss:{es:"Sus descansos difieren; conviene conversarlo.",en:"Their sleep patterns differ; discuss it.",priority:"high"},
  weekday_similar:{es:"Disfrutan semanas similares.",en:"They enjoy similar weekdays.",priority:"high"},
  weekday_discuss:{es:"Prefieren diferentes planes entre semana.",en:"Their weekday preferences differ.",priority:"high"},
  intent_aligned:{es:"Comparten intención de relación.",en:"Their relationship intentions align.",priority:"high"},
  intent_discuss:{es:"Sus expectativas pueden ser distintas.",en:"Their relationship intentions may differ.",priority:"high"},
  autonomy_aligned:{es:"Coinciden en autonomía y tiempo compartido.",en:"They agree on togetherness and independence.",priority:"high"},
  autonomy_discuss:{es:"Conviene hablar de tiempo juntos.",en:"Discuss time spent together.",priority:"high"},
  training_similar:{es:"Su frecuencia de actividad es similar.",en:"Their training frequency aligns.",priority:"medium"},
  training_respect:{es:"Tienen entrenamientos diferentes: pueden respetarse.",en:"Their training routines differ and can be respected.",priority:"medium"},
  sport_shared_low:{es:"Comparten deporte, sin que eso defina el match.",en:"They share a sport; that does not define compatibility.",priority:"low"},
  sport_different_ok:{es:"Practican deportes distintos: no es un impedimento.",en:"They enjoy different sports, and that is fine.",priority:"low"},
};
