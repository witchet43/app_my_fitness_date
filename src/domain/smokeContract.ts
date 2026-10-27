export function isPrivateCandidate(raw:unknown):boolean{
  if(!raw||typeof raw!=='object'||Array.isArray(raw))return false;
  const o=raw as Record<string,unknown>;
  const allowed=['user_id','display_name','city','sports'];
  return typeof o.user_id==='string' &&
    typeof o.display_name==='string' &&
    typeof o.city==='string' &&
    Array.isArray(o.sports) &&
    Object.keys(o).every(k=>allowed.includes(k));
}
export function isOwnedExport(raw:unknown,uid:string):boolean{
  if(!raw||typeof raw!=='object'||Array.isArray(raw))return false;
  const o=raw as Record<string,unknown>;
  if(!o.account||typeof o.account!=='object')return false;
  const me=o.account as Record<string,unknown>;
  if(me.id!==uid||o.export_version!==1)return false;
  const expectedArrays=['posts','organized_events','event_rsvps','blocked_user_ids',
    'own_notifications','reports_i_submitted','appeals_i_submitted','training_slots'];
  return expectedArrays.every(k=>Array.isArray(o[k]));
}
