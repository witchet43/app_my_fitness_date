#!/usr/bin/env node
'use strict';
const assert=require('node:assert/strict');
const fs=require('node:fs');
const vm=require('node:vm');

const source=fs.readFileSync('apps/flutter_client/cloudflare/brand-legal.js','utf8')
  .replaceAll('__FITTED_PUBLIC_BRAND_KEY__','sb_publishable_test_nonsecret');
assert(!source.includes('__FITTED_PUBLIC_BRAND_KEY__'));
const palette={primary:'#DDE7EC',accent:'#8196A2',background:'#1A2D38'};
const mark={hidden:true,src:''},vector={
  hidden:false,children:[],
  setAttribute(key,value){this[key]=value},
  replaceChildren(...children){this.children=children},
};
const favicon={href:'/favicon.png'},meta={content:''},theme={content:''};
const brandNodes=[{textContent:'Fitted'},{textContent:'Fitted'}];
const props={};
const root={style:{setProperty:(key,value)=>{props[key]=value}},
  dataset:{},styleColor:'',colorScheme:'dark'};
const document={
  documentElement:root,
  body:{dataset:{legalPage:'privacy'}},
  title:'Aviso de privacidad | Fitted',
  hidden:false,
  querySelectorAll:(selector)=>selector==='[data-brand-name]'?brandNodes:[],
  querySelector:(selector)=>({
    '[data-brand-logo]':mark,'[data-brand-vector]':vector,
    'link[rel="icon"]':favicon,'meta[name="description"]':meta,
    'meta[name="theme-color"]':theme
  })[selector]||null,
  addEventListener:()=>{},
  createElementNS:()=>({
    style:{},attributes:{},
    setAttribute(key,value){this.attributes[key]=value},
  })
};
const settings={name:'Conexión Viva',colors:palette,mode:'dark',logo:'catalog:20'};
const context={
  document,
  fetch:async (endpoint,options)=>{
    assert.match(endpoint,/mfd_brand_live/);
    assert.equal(options.headers.apikey,'sb_publishable_test_nonsecret');
    return {ok:true,json:async()=>[{version:4,settings}]};
  },
  AbortSignal:{timeout:()=>null},
  setInterval:()=>0,
};
vm.runInNewContext(source,context,{timeout:1000});
setImmediate(()=>{
  try {
    assert.equal(document.title,'Aviso de privacidad | Conexión Viva');
    assert.equal(root.dataset.brandVersion,'4');
    assert.equal(brandNodes[0].textContent,'Conexión Viva');
    assert.equal(brandNodes[1].textContent,'Conexión Viva');
    assert.equal(props['--brand-primary'],palette.primary);
    assert.equal(props['--brand-accent'],palette.accent);
    assert.equal(props['--brand-bg'],palette.background);
    assert.equal(theme.content,palette.background);
    assert.equal(mark.hidden,true);
    assert.equal(vector.hidden,false);
    assert.equal(vector.viewBox,'0 0 100 100');
    assert.equal(vector.children.length,2);
    assert.match(vector.children[0].attributes.d,/M 31 50|M 31 29/);
    console.log('PASS legal pages bind name, colors and catalog:20 vector logo from live brand');
  }catch(e){console.error(e);process.exitCode=1}
});
