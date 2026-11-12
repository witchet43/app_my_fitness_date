(() => {
  "use strict";
  // Public publishable key only. Credentials and privileged role decisions
  // are never stored in the browser or inferred from editable user claims.
  const base = "https://jtrdvnwbxpfdnbzasvcj.supabase.co";
  const key = "sb_publishable_IAPJ1C1EdLg155iMOgRNfg_i6OWuJkk";
  const el = id => document.getElementById(id);
  let accessToken = "";
  let currentAdmin = null;
  let pendingFactor = null;
  let currentDraft = null;
  let savedDrafts = [];
  let palettes = [];
  let assets = [];
  const urls = new Map();
  const defaults = {
    name: "My Fitness Date", tagline: "Conexiones con intención.",
    title: "Personas afines a tu forma de vivir.",
    description: "Un espacio elegante para quienes buscan compartir valores y construir relaciones estables.",
    colors: {primary:"#28463D",accent:"#B49A6A",background:"#F7F5F0"},
    paletteName:"Bosque",font:"system:Georgia",logo:"catalog:0",
    media:{cover_desktop:null,cover_mobile:null,login_image:null,onboarding_image:null,app_image:null,illustration:null},
    radius:12,mode:"light",layout:"editorial"
  };
  let state = structuredClone(defaults), device = "desktop";
  const catalog = [
    ["Monograma","M"],["Cadencia","≋"],["Cumbres","⌃"],["Vínculo","∞"],["Pulso","∿"],
    ["Brújula","✧"],["Trayectoria","↗"],["Horizonte","━"],["Geometría","◇"],["Movimiento","⌁"]
  ];

  function message(text,error=false) {
    el("feedback").textContent = text;
    el("feedback").style.background = error ? "#963b36" : "#143c30";
  }
  function show(id) {
    for(const name of ["login-screen","mfa-screen","studio"])el(name).hidden=name!==id;
  }
  function fail(messageText) {
    message(messageText || "No fue posible completar la solicitud",true);
  }
  const hex = x => typeof x==="string" && /^#[0-9a-fA-F]{6}$/.test(x);
  function safeText(v,max){return String(v??"").slice(0,max);}
  function authorizedHeaders(extra={}) {
    return {apikey:key, ...(accessToken?{Authorization:"Bearer "+accessToken}:{}), ...extra};
  }
  async function request(route, {method="GET",body,raw=false,headers={}}={}) {
    const response = await fetch(base+route, {
      method, credentials:"omit",
      headers:authorizedHeaders({
        ...(raw?{}:{"Content-Type":"application/json"}),
        ...headers
      }),
      ...(body===undefined?{}:{body:raw?body:JSON.stringify(body)})
    });
    if(!response.ok){
      // Never display raw backend text containing private data or secrets.
      if(response.status===401)throw Error("Sesión vencida o credenciales incorrectas.");
      if(response.status===403)throw Error("Operación denegada por los permisos administrativos o MFA.");
      if(response.status===404)throw Error("Servicio administrativo aún no desplegado.");
      if(response.status===409)throw Error("Conflicto: el recurso ya existe; consulta los cambios más recientes.");
      throw Error("Servicio de administración no disponible (HTTP "+response.status+").");
    }
    if(response.status===204)return null;
    return raw?response.blob():response.json();
  }
  function authHeaders(){return authorizedHeaders();}
  function identityReset(){
    accessToken="";currentAdmin=null;pendingFactor=null;
    el("admin-password").value="";el("totp-code").value="";
    urls.forEach(url=>URL.revokeObjectURL(url));urls.clear();
    show("login-screen");
  }
  async function signIn(event) {
    event.preventDefault();
    const email=el("admin-email").value.trim();
    const password=el("admin-password").value;
    identityReset();
    try{
      const result=await request("/auth/v1/token?grant_type=password",{
        method:"POST",body:{email,password}
      });
      accessToken=result.access_token;
      if(!accessToken)throw Error("La autenticación no devolvió una sesión.");
      // A member's ordinary Google/email session CANNOT enroll admin MFA.
      const allowed=await request("/rest/v1/rpc/brand_admin_status",{
        method:"POST",body:{}
      });
      if(allowed!==true)throw Error("Esta cuenta no pertenece al rol administrativo independiente.");
      currentAdmin=await request("/auth/v1/user");
      if(!currentAdmin || !currentAdmin.id)throw Error("No se pudo validar identidad administrativa.");
      const factors=await factorsForCurrentAdmin();
      const verified=factors.find(f=>f.factor_type==="totp"&&f.status==="verified");
      if(verified){
        pendingFactor=verified.id;
        el("enroll-note").hidden=true;
        el("mfa-explanation").textContent="Introduce el código TOTP de tu autenticador.";
      }else{
        const enrolled=await request("/auth/v1/factors",{
          method:"POST",
          body:{factor_type:"totp",friendly_name:"Brand Studio — My Fitness Date"}
        });
        pendingFactor=enrolled.id;
        if(!pendingFactor)throw Error("No se pudo iniciar inscripción MFA.");
        el("totp-secret").textContent=enrolled.totp?.secret||"Consulta tu autenticador";
        el("enroll-note").hidden=false;
        el("mfa-explanation").textContent="Configura tu autenticador con la clave privada y confirma con el código TOTP.";
      }
      show("mfa-screen");
    }catch(error){
      identityReset();
      fail(error.message);
    }
  }
  async function factorsForCurrentAdmin() {
    if(Array.isArray(currentAdmin.factors)) return currentAdmin.factors;
    try{
      const record=await request("/auth/v1/factors");
      if(Array.isArray(record))return record;
      if(Array.isArray(record?.factors))return record.factors;
      if(Array.isArray(record?.totp))return record.totp;
    }catch(_){}
    return [];
  }
  async function verifyMfa(event) {
    event.preventDefault();
    const code=el("totp-code").value.trim();
    if(!/^\d{6}$/.test(code)){fail("El código MFA debe tener seis dígitos.");return;}
    try{
      const challenge=await request("/auth/v1/factors/"+encodeURIComponent(pendingFactor)+"/challenge",{
        method:"POST",body:{}
      });
      const result=await request("/auth/v1/factors/"+encodeURIComponent(pendingFactor)+"/verify",{
        method:"POST",body:{challenge_id:challenge.id,code}
      });
      if(!result.access_token)throw Error("MFA no devolvió una sesión válida.");
      accessToken=result.access_token;
      // Authorization is enforced again by PostgreSQL under fresh AAL2 JWT.
      const allowed=await request("/rest/v1/rpc/brand_admin_session",{method:"POST",body:{}});
      if(allowed!==true)throw Error("La sesión no alcanzó MFA AAL2 o perdió privilegios.");
      el("totp-secret").textContent="";
      el("totp-code").value="";
      el("admin-identity").textContent="Administrador · "+currentAdmin.email;
      show("studio");
      await loadCatalogs();
      render();
      message("Acceso administrativo validado con MFA. El diseño sigue en borrador privado.");
    }catch(error){fail(error.message);}
  }
  function dataPayload(){
    const c=state.colors;
    if(![c.primary,c.accent,c.background].every(hex))throw Error("Los colores deben ser hexadecimal válido.");
    if(!state.name.trim())throw Error("El nombre de marca es obligatorio.");
    return {
      name: safeText(state.name,60),tagline:safeText(state.tagline,120),
      title:safeText(state.title,170),description:safeText(state.description,400),
      colors:{...c},paletteName:safeText(state.paletteName,70),
      font:state.font,logo:state.logo,media:{...state.media},
      radius:state.radius,mode:state.mode,layout:state.layout
    };
  }
  function updateFromInputs(){
    state.name=el("brand-name").value.slice(0,60);
    state.tagline=el("brand-tagline").value.slice(0,120);
    state.title=el("hero-title").value.slice(0,170);
    state.description=el("hero-text").value.slice(0,400);
    state.colors={
      primary:el("color-primary").value,
      accent:el("color-accent").value,
      background:el("color-background").value
    };
    state.paletteName=el("palette-name").value.slice(0,70);
    state.font=el("font-select").value;
    state.logo=el("logo-select").value;
    state.radius=Number(el("radius").value);
    state.mode=el("appearance").value;
    state.layout=el("layout").value;
    render();
  }
  function syncInputs(){
    el("brand-name").value=state.name;
    el("brand-tagline").value=state.tagline;
    el("hero-title").value=state.title;
    el("hero-text").value=state.description;
    el("color-primary").value=hex(state.colors?.primary)?state.colors.primary:defaults.colors.primary;
    el("color-accent").value=hex(state.colors?.accent)?state.colors.accent:defaults.colors.accent;
    el("color-background").value=hex(state.colors?.background)?state.colors.background:defaults.colors.background;
    el("palette-name").value=state.paletteName;
    const fontSelect=el("font-select"),logoSelect=el("logo-select");
    if([...fontSelect.options].some(x=>x.value===state.font))fontSelect.value=state.font;
    if([...logoSelect.options].some(x=>x.value===state.logo))logoSelect.value=state.logo;
    el("radius").value=String(state.radius);
    el("appearance").value=state.mode;
    el("layout").value=state.layout;
  }
  function imageUrl(assetId){
    return urls.get(assetId)||"";
  }
  function render(){
    const c=state.colors;
    const stage=el("stage");
    for(const name of ["primary","accent","background"]){
      stage.style.setProperty("--"+name,hex(c[name])?c[name]:defaults.colors[name]);
    }
    stage.style.setProperty("--radius",(Number.isFinite(state.radius)?state.radius:12)+"px");
    stage.classList.toggle("dark",state.mode==="dark");
    stage.classList.toggle("mobile",device==="mobile");
    el("preview-brand").textContent=state.name||"Marca sin nombre";
    el("preview-title").textContent=state.title;
    el("preview-text").textContent=state.description;
    const fontFamily=state.font.startsWith("asset:")?'"BrandUploaded",Georgia,serif':
      state.font==="system:Arial"?'Arial,sans-serif':
      state.font==="system:Palatino"?'Palatino,Georgia,serif':
      state.font==="system:Garamond"?'Garamond,serif':'Georgia,serif';
    stage.style.setProperty("--font",fontFamily);
    const mark=el("preview-logo");mark.textContent="";
    if(state.logo.startsWith("asset:")){
      const src=imageUrl(state.logo.slice(6));
      if(src){const img=document.createElement("img");img.src=src;img.alt="";mark.appendChild(img);}
      else mark.textContent="M";
    }else{
      const i=Number(state.logo.split(":")[1]??0);
      mark.textContent=catalog[i]?.[1]||"M";
    }
    const kind=device==="mobile"?"cover_mobile":"cover_desktop";
    const coverId=state.media?.[kind];
    const cover=coverId?imageUrl(coverId):"";
    stage.querySelector(".preview-hero").style.setProperty("--hero-image",
      cover?'url("'+cover+'")':"none");
    el("logo-catalog").querySelectorAll("button").forEach(b=>
      b.setAttribute("aria-pressed",String(state.logo===b.dataset.value)));
  }
  function option(select,value,label){
    if([...select.options].some(o=>o.value===value))return;
    const o=document.createElement("option");o.value=value;o.textContent=label;
    select.add(o);
  }
  function renderCatalog(){
    const box=el("logo-catalog");box.replaceChildren();
    for(let i=0;i<10;i++){
      const b=document.createElement("button");
      b.type="button";b.dataset.value="catalog:"+i;
      const symbol=document.createElement("strong");symbol.textContent=catalog[i][1];symbol.style.fontSize="35px";
      const caption=document.createElement("small");caption.textContent=catalog[i][0];
      b.append(symbol,caption);
      b.addEventListener("click",()=>{el("logo-select").value=b.dataset.value;updateFromInputs();});
      box.appendChild(b);
    }
  }
  async function rest(table, {method="GET",body,query=""}={}){
    return request("/rest/v1/"+table+query,{
      method,body,headers:{Prefer:"return=representation"}
    });
  }
  async function loadCatalogs(){
    [palettes,savedDrafts,assets]=await Promise.all([
      rest("brand_palettes",{query:"?select=*&order=created_at.desc&limit=100"}),
      rest("brand_design_drafts",{query:"?select=*&order=updated_at.desc&limit=100"}),
      rest("brand_assets",{query:"?select=*&order=created_at.desc&limit=100"})
    ]);
    const paletteSelect=el("palette-select");
    paletteSelect.replaceChildren(new Option("Crear nueva paleta",""));
    for(const p of palettes)option(paletteSelect,p.id,p.name);
    const draftSelect=el("draft-select");
    draftSelect.replaceChildren(new Option("Seleccionar borrador",""));
    for(const d of savedDrafts)option(draftSelect,d.id,d.title+" · v"+d.revision);
    const font=el("font-select"),logo=el("logo-select");
    // Uploaded objects are private, fetched with the current AAL2 token.
    for(const a of assets){
      if(a.asset_kind==="font")option(font,"asset:"+a.id,"Fuente cargada · "+a.name);
      if(a.asset_kind==="logo")option(logo,"asset:"+a.id,"Logo cargado · "+a.name);
    }
    renderAssets();
  }
  async function fetchAsset(a) {
    if(urls.has(a.id))return urls.get(a.id);
    const response=await fetch(
      base+"/storage/v1/object/authenticated/mfd-brand-drafts/"+encodeURI(a.storage_path),
      {headers:authHeaders(),credentials:"omit"}
    );
    if(!response.ok)throw Error("No fue posible abrir el recurso privado.");
    const blob=await response.blob();
    const url=URL.createObjectURL(blob);
    urls.set(a.id,url);
    return url;
  }
  function renderAssets(){
    const list=el("asset-list");list.replaceChildren();
    for(const a of assets){
      const b=document.createElement("button");b.type="button";b.className="asset";
      if(a.mime_type.startsWith("image/")){
        const image=document.createElement("img");image.alt="";
        if(urls.has(a.id))image.src=urls.get(a.id);
        else fetchAsset(a).then(url=>{if(b.isConnected)image.src=url;}).catch(()=>{});
        b.append(image);
      }
      const box=document.createElement("span");
      const main=document.createElement("strong");main.textContent=a.name;
      const meta=document.createElement("small");meta.textContent=a.asset_kind+" · "+Math.ceil(a.bytes/1024)+" KB";
      box.append(main,meta);b.append(box);
      b.title="Usar este recurso en la vista previa";
      b.addEventListener("click",async()=>{
        try{
          const url=await fetchAsset(a);
          if(a.asset_kind==="font"){
            const f=new FontFace("BrandUploaded",'url("'+url+'") format("woff2")');
            await f.load();document.fonts.add(f);
            option(el("font-select"),"asset:"+a.id,a.name);
            el("font-select").value="asset:"+a.id;
          }else if(a.asset_kind==="logo"){
            option(el("logo-select"),"asset:"+a.id,a.name);
            el("logo-select").value="asset:"+a.id;
          }else state.media[a.asset_kind]=a.id;
          updateFromInputs();
        }catch(error){fail(error.message);}
      });
      list.appendChild(b);
    }
  }
  async function savePalette(){
    try{
      updateFromInputs();
      const name=state.paletteName.trim();
      if(name.length<2)throw Error("Escribe un nombre de paleta válido.");
      await rest("brand_palettes",{method:"POST",body:{name,colors:state.colors,created_by:currentAdmin.id}});
      await loadCatalogs();message("Paleta añadida al catálogo administrativo.");
    }catch(error){fail(error.message);}
  }
  async function validateFile(file,kind){
    if(!file)throw Error("Selecciona un archivo.");
    const isFont=kind==="font";
    if(file.size<1||file.size>(isFont?2097152:8388608))throw Error("El archivo excede el tamaño autorizado.");
    const name=file.name.toLowerCase();
    const suffix=name.split(".").pop();
    const allowed=isFont?["woff2"]:(kind==="logo"?["png","webp"]:["jpg","jpeg","png","webp"]);
    if(!allowed.includes(suffix))throw Error("Formato no autorizado.");
    const header=new Uint8Array(await file.slice(0,16).arrayBuffer());
    const png=header[0]===137&&header[1]===80&&header[2]===78&&header[3]===71;
    const jpg=header[0]===255&&header[1]===216&&header[2]===255;
    const webp=String.fromCharCode(...header.slice(0,4))==="RIFF"&&String.fromCharCode(...header.slice(8,12))==="WEBP";
    const woff=String.fromCharCode(...header.slice(0,4))==="wOF2";
    if(!((suffix==="png"&&png)||(suffix==="webp"&&webp)||
      ((suffix==="jpg"||suffix==="jpeg")&&jpg)||(suffix==="woff2"&&woff)))
      throw Error("El formato real del archivo no corresponde a su extensión.");
    if(kind==="logo"&&!(png||webp))throw Error("Los logos externos deben ser PNG o WebP.");
    const mime=isFont?"font/woff2":png?"image/png":webp?"image/webp":"image/jpeg";
    return {suffix,mime};
  }
  async function upload(kind,fieldId){
    try{
      if(!currentAdmin)throw Error("Se requiere identidad administrativa.");
      const file=el(fieldId).files?.[0];
      const {suffix,mime}=await validateFile(file,kind);
      if(kind==="font"&&!el("font-license").value)
        throw Error("Selecciona una declaración de licencia válida antes de subir una fuente.");
      const path=currentAdmin.id+"/"+kind+"/"+crypto.randomUUID()+"."+suffix;
      const response=await fetch(base+"/storage/v1/object/mfd-brand-drafts/"+path,{
        method:"POST",credentials:"omit",headers:authHeaders({
          "Content-Type":mime,"x-upsert":"false","cache-control":"no-store"
        }),body:file
      });
      if(!response.ok)throw Error("Storage rechazó la carga. Verifica MFA y políticas RLS.");
      await rest("brand_assets",{method:"POST",body:{
        asset_kind:kind,name:file.name.slice(0,100),
        storage_path:path,mime_type:mime,bytes:file.size,
        license_basis:kind==="font"?el("font-license").value:"not_applicable",
        created_by:currentAdmin.id
      }});
      await loadCatalogs();
      const record=assets.find(x=>x.storage_path===path);
      if(record){
        urls.set(record.id,URL.createObjectURL(file));
        if(kind==="logo") {
          state.logo="asset:"+record.id;
          option(el("logo-select"),state.logo,file.name);
          el("logo-select").value=state.logo;
        }else if(kind==="font"){
          const face=new FontFace("BrandUploaded",'url("'+urls.get(record.id)+'") format("woff2")');
          await face.load();document.fonts.add(face);
          state.font="asset:"+record.id;
          option(el("font-select"),state.font,file.name);
          el("font-select").value=state.font;
        }else state.media[kind]=record.id;
      }
      renderAssets();render();
      el(fieldId).value="";
      message("Recurso guardado en biblioteca administrativa privada; no publicado.");
    }catch(error){fail(error.message);}
  }
  async function saveDraft(){
    try{
      updateFromInputs();
      const title=el("draft-title").value.trim();
      if(title.length<2)throw Error("El borrador necesita un título.");
      const settings=dataPayload();
      if(currentDraft){
        const revision=currentDraft.revision+1;
        const result=await rest("brand_design_drafts",{
          method:"PATCH",query:"?id=eq."+encodeURIComponent(currentDraft.id)+
            "&revision=eq."+currentDraft.revision,
          body:{title,settings,revision,updated_by:currentAdmin.id,updated_at:new Date().toISOString()}
        });
        if(result.length!==1)throw Error("Otro administrador modificó este borrador. Actualiza antes de continuar.");
        currentDraft=result[0];
      }else{
        const result=await rest("brand_design_drafts",{method:"POST",body:{
          title,settings,created_by:currentAdmin.id,updated_by:currentAdmin.id
        }});
        currentDraft=result[0];
      }
      await loadCatalogs();
      el("draft-select").value=currentDraft.id;
      el("request-release").disabled=false;
      message("Borrador administrativo guardado como revisión "+currentDraft.revision+".");
    }catch(error){fail(error.message);}
  }
  function loadDraft(){
    const selected=savedDrafts.find(x=>x.id===el("draft-select").value);
    if(!selected){fail("Selecciona un borrador guardado.");return;}
    const d=selected.settings;
    if(!d||typeof d!=="object"||!d.colors || !Object.values(d.colors).every(hex)){
      fail("Este borrador contiene datos de color inválidos.");return;
    }
    state={...structuredClone(defaults),...d,colors:{...d.colors},media:{...defaults.media,...d.media}};
    currentDraft=selected;
    el("draft-title").value=selected.title;
    syncInputs();render();
    el("request-release").disabled=false;
    message("Revisión "+selected.revision+" cargada para edición.");
    // Rehydrate selected private assets asynchronously.
    for(const a of assets.filter(x=>["font","logo","cover_desktop","cover_mobile"].includes(x.asset_kind))){
      if((state.font==="asset:"+a.id)||(state.logo==="asset:"+a.id)||
        Object.values(state.media).includes(a.id))
          fetchAsset(a).then(async url=>{
            if(state.font==="asset:"+a.id){
              const face=new FontFace("BrandUploaded",'url("'+url+'") format("woff2")');
              await face.load();document.fonts.add(face);
            }
            render();
          }).catch(()=>{});
    }
  }
  async function requestRelease(){
    try{
      if(!currentDraft)throw Error("Guarda primero un borrador.");
      await rest("brand_release_requests",{method:"POST",body:{
        draft_id:currentDraft.id,revision:currentDraft.revision,
        requested_by:currentAdmin.id,status:"pending_review"
      }});
      message("Solicitud de revisión registrada. No se publicó ningún cambio.");
    }catch(error){fail(error.message);}
  }
  renderCatalog();
  el("login-form").addEventListener("submit",signIn);
  el("mfa-form").addEventListener("submit",verifyMfa);
  el("cancel-mfa").addEventListener("click",identityReset);
  el("signout").addEventListener("click",()=>{
    if(accessToken)request("/auth/v1/logout",{method:"POST",body:{}}).catch(()=>{});
    identityReset();message("Sesión administrativa cerrada.");
  });
  for(const id of ["brand-name","brand-tagline","hero-title","hero-text",
    "color-primary","color-accent","color-background","palette-name","font-select",
    "logo-select","radius","appearance","layout"])
      el(id).addEventListener("input",updateFromInputs);
  el("palette-select").addEventListener("change",()=>{
    const p=palettes.find(x=>x.id===el("palette-select").value);
    if(!p)return;
    state.colors={...p.colors};state.paletteName=p.name;syncInputs();render();
  });
  el("save-palette").addEventListener("click",savePalette);
  el("upload-logo").addEventListener("click",()=>upload("logo","logo-upload"));
  el("upload-font").addEventListener("click",()=>upload("font","font-upload"));
  el("upload-image").addEventListener("click",()=>upload(el("image-kind").value,"image-upload"));
  el("save-draft").addEventListener("click",saveDraft);
  el("new-draft").addEventListener("click",()=>{
    currentDraft=null;el("draft-title").value="Nueva propuesta de marca";
    el("request-release").disabled=true;
    message("Nuevo borrador; guarda cuando esté listo.");
  });
  el("load-draft").addEventListener("click",loadDraft);
  el("request-release").addEventListener("click",requestRelease);
  document.querySelectorAll("[data-device]").forEach(b=>b.addEventListener("click",()=>{
    device=b.dataset.device;render();
    document.querySelectorAll("[data-device]").forEach(e=>
      e.setAttribute("aria-pressed",String(device===e.dataset.device)));
  }));
  render();
  show("login-screen");
})();
