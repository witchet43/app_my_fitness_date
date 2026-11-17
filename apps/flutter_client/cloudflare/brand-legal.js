/* Public, sanitized brand published by the owner with MFA. */
(() => {
  'use strict';
  const endpoint = 'https://jtrdvnwbxpfdnbzasvcj.supabase.co/rest/v1/mfd_brand_live?select=version,settings&id=eq.true';
  const key = '__FITTED_PUBLIC_BRAND_KEY__';
  const hex = /^#[0-9a-fA-F]{6}$/;
  const safeLogo = /^https:\/\/jtrdvnwbxpfdnbzasvcj\.supabase\.co\/storage\/v1\/object\/public\/mfd-brand-live\/[0-9a-f-]{36}\/[A-Za-z0-9_-]{4,100}\.(?:png|jpg|webp)$/;
  // Equivalent lightweight SVGs for the twenty Flutter catalogue motifs.
  // Entries are source-owned geometry, never markup provided by users.
  const vectors=[
    ['M43 53 C60 23 85 30 120 30 C148 30 173 31 179 29 C175 52 151 66 124 66 C100 66 77 60 63 86 C47 95 36 107 26 121 C28 91 32 71 43 53Z',
     'M28 113 C51 88 61 80 94 80 C118 78 128 76 137 72 C128 93 114 108 94 110 C75 109 69 113 61 129 C45 165 21 174 14 158 C9 142 13 130 28 113Z'],
    ['M15 54 C30 20 77 15 86 43 C96 72 36 86 15 54','M50 28 A22 22 0 1 1 50 72'],
    ['M32 26 A23 23 0 1 0 50 66','M68 74 A23 23 0 1 0 50 34'],
    ['M14 42 Q46 39 78 21 M16 58 Q47 49 79 38','M18 75 Q52 63 80 53'],
    ['M12 77 L40 27 L63 63 L74 46 L89 77','M31 77 L54 42 L78 77'],
    ['M10 50 L28 50 L38 36 L49 73 L60 27 L69 50 L89 50','M10 50 L12 50'],
    ['M12 69 H88 M23 69 A27 27 0 0 1 77 69','M50 18 V27 M21 38 L27 44 M79 38 L73 44'],
    ['M23 28 L77 73 M23 73 L77 28','M23 28 H77 M23 73 H77'],
    ['M16 75 C36 72 41 47 74 29','M54 27 L77 27 L77 49'],
    ['M50 10 L78 50 L50 90 L22 50 Z','M50 26 L61 50 L50 73 L39 50 Z'],
    ['M50 50 C33 22 13 31 14 51 C16 73 39 72 50 50 C66 22 90 30 86 51 C82 73 65 74 50 50','M50 50 L51 50'],
    ['M26 70 V34 M50 70 V25 M74 70 V16','M18 79 H85'],
    ['M12 71 L37 25 L63 71 Z','M40 77 L65 31 L90 77 Z'],
    ['M16 23 Q52 23 74 50 M16 50 H74 M16 77 Q52 77 74 50','M66 38 L79 50 L66 62'],
    ['M10 29 C35 7 60 51 90 29 M10 50 C35 28 60 72 90 50','M10 71 C35 49 60 93 90 71'],
    ['M50 8 L59 40 L92 50 L59 60 L50 92 L41 60 L8 50 L41 40 Z','M46 50 H54'],
    ['M14 44 A23 23 0 1 1 47 64','M86 56 A23 23 0 1 1 53 36'],
    ['M20 78 C10 47 68 62 56 31 Q51 18 80 19','M20 78 L20 78 M56 31 L56 31'],
    ['M18 70 A35 35 0 0 1 82 70 M50 20 V80','M18 30 A35 35 0 0 0 82 30'],
    ['M50 11 V31 M50 69 V89 M11 50 H31 M69 50 H89 M22 22 L36 36 M64 64 L78 78','M78 22 L64 36 M36 64 L22 78'],
    ['M50 84 Q53 57 50 41 M49 57 Q16 55 24 26 Q47 27 49 57','M51 44 Q51 17 81 17 Q79 39 51 44'],
  ];
  function renderVector(node,id,primary,accent){
    const index=Number(id.slice(8));
    if(!Number.isInteger(index)||index<0||index>=vectors.length)return;
    const ns='http://www.w3.org/2000/svg';
    const parts=vectors[index].map((d,i)=>{
      const element=document.createElementNS(ns,'path');
      element.setAttribute('d',d);
      element.style.fill=index===0?(i===0?'#DDE7EC':'#8196A2'):'none';
      element.style.fillOpacity=index===0?(i===0?'.91':'.73'):'1';
      element.style.stroke=index===0?'none':(i===0?primary:accent);
      element.style.strokeWidth=index===0?'0':(i===0?'6':'4.5');
      element.style.strokeLinecap='round';
      element.style.strokeLinejoin='round';
      return element;
    });
    node.setAttribute('viewBox',index===0?'0 0 200 200':'0 0 100 100');
    node.replaceChildren(...parts);
  }
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
      } else {
        mark.hidden=true;
        vector.hidden=false;
        if(typeof s.logo==='string' && /^catalog:([0-9]|1[0-9]|20)$/.test(s.logo)){
          renderVector(vector,s.logo,primary,accent);
        }
      }
    }
  }
  async function refresh(){
    if (key.startsWith('__'))return;
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