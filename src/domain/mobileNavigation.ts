export type MobileTab = 'community'|'together'|'dating'|'inbox'|'admin'|'account';
export type MobileTabSpec = {id:MobileTab;title:string;emoji:string};
export const BASE_TABS:MobileTabSpec[]=[
  {id:'community',title:'Comunidad',emoji:'◉'},
  {id:'together',title:'Actividades',emoji:'◎'},
  {id:'dating',title:'Citas',emoji:'♡'},
];
const EXTRA_TABS:Record<'inbox'|'admin'|'account',MobileTabSpec>={
  inbox:{id:'inbox',title:'Buzón',emoji:'✉'},
  admin:{id:'admin',title:'Moderación',emoji:'⚑'},
  account:{id:'account',title:'Cuenta',emoji:'⚙'},
};
export type MobileNavigationState = {
  authenticated:boolean; verified:boolean; deletionPending:boolean; moderator:boolean;
};
/** Tabs hidden until account-gate check completes; pending deletion isolates account actions. */
export function tabsForAccount(state:MobileNavigationState):MobileTabSpec[]{
  if(!state.authenticated)return BASE_TABS;
  if(!state.verified)return [];
  if(state.deletionPending)return [EXTRA_TABS.account];
  return [...BASE_TABS,EXTRA_TABS.inbox,
    ...(state.moderator?[EXTRA_TABS.admin]:[]),EXTRA_TABS.account];
}
export function tabAccessible(tab:MobileTab,state:MobileNavigationState):boolean{
 return tabsForAccount(state).some(item=>item.id===tab);
}
