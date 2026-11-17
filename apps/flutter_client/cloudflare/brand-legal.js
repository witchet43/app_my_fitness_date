/* Public, sanitized brand published by the owner with MFA. */
(() => {
  'use strict';
  const endpoint = 'https://jtrdvnwbxpfdnbzasvcj.supabase.co/rest/v1/mfd_brand_live?select=version,settings&id=eq.true';
  const key = '__FITTED_PUBLIC_BRAND_KEY__';
  const hex = /^#[0-9a-fA-F]{6}$/;
  const safeLogo = /^https:\/\/jtrdvnwbxpfdnbzasvcj\.supabase\.co\/storage\/v1\/object\/public\/mfd-brand-live\/[0-9a-f-]{36}\/[A-Za-z0-9_-]{4,100}\.(?:png|jpg|webp)$/;
  let lastVersion = -1;
  function rgb(value) {return [1,3,5].map(i => parseInt(value.slice(i,i+2),16));}
  function blend(a,b,r) {
    const lhs=rgb(a),rhs=rgb(b);
    return '#'+lhs.map((v,i)=>Math.round(v*(1-r)+rhs[i]*r).toString(16).padStart(2,'0')).join('');
  }
  function apply(record) {
    if (!record || !Number.isFinite(Number(record.version)) || Number(record.version)<lastVersion) return;
    const s=record.settings;
    if (!s || !s.colors) return;
    const {primary,accent,background}=s.colors;
    if (![primary,accent,background].every(c=>typeof c==='string'&&hex.test(c))) return;
    if (typeof s.name!=='string'||s.name.trim().length<2||s.name.length>60) return;
    lastVersion=Number(record.version);
    const dark=s.mode==='dark', fg=dark?'#F6FBFD':'#172731', neutral=dark?'#B7C6CF':'#667983';
    const root=document.documentElement;
    const colors={
      '--brand-bg':background,
      '--brand-surface':blend(background,dark?'#FFFFFF':'#000000',.065),
      '--brand-raised':blend(background,dark?'#FFFFFF':'#000000',.13),
      '--brand-primary':primary,
      '--brand-accent':accent,
      '--brand-neutral':blend(primary,neutral,.73),
      '--brand-text':fg,
      '--brand-muted':blend(fg,background,.34),
      '--brand-border':blend(fg,background,.72),
      '--brand-link':primary,
    };
    for (const [prop,value] of Object.entries(colors)) root.style.setProperty(prop,value);
    root.style.colorScheme=dark?'dark':'light';
    root.dataset.brandVersion=String(lastVersion);
    document.querySelectorAll('[data-brand-name]').forEach(el=>{el.textContent=s.name});
    const page=document.body.dataset.legalPage==='terms'?'Términos y condiciones':'Aviso de privacidad';
    document.title=page+' | '+s.name;
    const meta=document.querySelector('meta[name="description"]');
    if(meta)meta.content=page+' de '+s.name+'.';
    const theme=document.querySelector('meta[name="theme-color"]');
    if(theme)theme.content=background;
    const mark=document.querySelector('[data-brand-logo]');
    const vector=document.querySelector('[data-brand-vector]');
    if(mark&&vector) {
      if(typeof s.logo==='string'&&safeLogo.test(s.logo)){
        mark.src=s.logo;mark.hidden=false;vector.hidden=true;
        const favicon=document.querySelector('link[rel="icon"]');
        if(favicon)favicon.href=s.logo;
      } else {mark.hidden=true;vector.hidden=false;}
    }
  }
  async function refresh(){
    if (key==='__FITTED_PUBLIC_BRAND_KEY__')return;
    try {
      const response=await fetch(endpoint,{headers:{apikey:key},cache:'no-store',signal:AbortSignal.timeout(6000)});
      if(!response.ok)return;
      const rows=await response.json();
      if(Array.isArray(rows)&&rows.length===1)apply(rows[0]);
    }catch(_) {/* Preserve the last valid theme and accessible legal text. */}
  }
  refresh();
  setInterval(()=>{if(!document.hidden)refresh()},20000);
  document.addEventListener('visibilitychange',()=>{if(!document.hidden)refresh()});
})();