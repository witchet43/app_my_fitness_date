#!/usr/bin/env node
"use strict";
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const vm = require("node:vm");

const src = fs.readFileSync(path.join(__dirname,
  "../apps/flutter_client/cloudflare/brand-lab/brand-lab.js"), "utf8");

class StubElement {
  constructor(id = "") {
    this.id = id;
    this.children = [];
    this.dataset = {};
    this.handlers = {};
    this.attributes = {};
    this.className = "";
    this.textContent = "";
    this.innerHTML = "";
    this.value = "";
    this.hidden = false;
    this.download = "";
    this.style = { values: {}, setProperty: (key, value) => { this.style.values[key] = value; } };
    this.classList = { values: new Set(), toggle: (name, on) => {
      if (on) this.classList.values.add(name); else this.classList.values.delete(name);
    }};
  }
  addEventListener(name, handler) { this.handlers[name] = handler; }
  setAttribute(name, value) { this.attributes[name] = value; }
  append(...nodes) { this.children.push(...nodes); }
  appendChild(node) { this.children.push(node); return node; }
  remove() {}
  click() { this.clicked = true; }
  closest() { return this; }
  querySelector(selector) {
    return this.children.find(node => "." + node.className === selector) || null;
  }
}
const all = new Map();
const elem = id => {
  if (!all.has(id)) all.set(id, new StubElement(id));
  return all.get(id);
};
const groups = {
  name: ["My Fitness Date","FITTED","Cadence","Pace","Sync","MFD","Ritmo","Concordia"],
  palette: ["forest","night","earth","slate","sage"],
  font: ["editorial","heritage","formal","modern"],
  mode: ["light","dark"],
  device: ["desktop","mobile"],
  view: ["landing","app","onboarding"],
  tone: ["serene","editorial","direct"],
  shape: ["soft","sharp"]
};
const selectorButtons = Object.fromEntries(
  Object.entries(groups).map(([k, vals]) => [k, vals.map(v => {
    const e = new StubElement();
    e.dataset[k] = v;
    return e;
  })])
);
const screens = ["landing","app","onboarding"].map(screen => {
  const e = new StubElement();
  e.dataset.screen = screen;
  return e;
});
const brandNames = [new StubElement(), new StubElement()];
const marks = [new StubElement(), new StubElement()];
const storage = new Map();
const blobParts = [];
const document = {
  body: {appendChild() {}},
  getElementById: elem,
  createElement: tag => new StubElement(tag),
  querySelectorAll: selector => {
    const found = selector.match(/^\[data-(\w+)\]$/);
    if (found) return selectorButtons[found[1]] || [];
    if (selector === "[data-screen]") return screens;
    if (selector === ".current-name") return brandNames;
    if (selector === ".current-logo") return marks;
    return [];
  }
};
const window = {
  localStorage: {
    getItem: key => storage.get(key) || null,
    setItem: (key, val) => storage.set(key, val),
    removeItem: key => storage.delete(key)
  },
  addEventListener() {},
  confirm: () => true
};
const sandbox = {
  document, window,
  URL: {createObjectURL:()=> "blob:mock", revokeObjectURL() {}},
  Blob: class {constructor(parts, opts){blobParts.push({parts, opts});}},
  setTimeout: callback => callback(),
};
vm.runInNewContext(src, sandbox, {timeout: 1000});

function press(group, value) {
  const element = new StubElement();
  element.dataset[group] = String(value);
  const container = group === "name" ? "name-presets" :
    group === "palette" ? "palette-grid" :
    group === "font" ? "font-grid" :
    group === "tone" ? "tone-switch" :
    group === "shape" ? "shape-switch" :
    group === "mode" ? "theme-switch" :
    group === "device" ? "device-switch" :
    group === "view" ? "view-switch" : "logo-grid";
  elem(container).handlers.click({target:{closest:()=>element}});
}
assert.equal(elem("logo-grid").children.length, 10, "Exactly ten rendered logo buttons");
assert.match(marks[0].innerHTML, /<svg/);
assert.equal(elem("hero-title").textContent,
  "Conoce personas afines a tu forma de vivir.");
press("name", "Cadence");
assert.equal(brandNames[0].textContent, "Cadence");
assert.equal(brandNames[1].textContent, "Cadence");
press("palette", "night");
assert.equal(elem("preview-canvas").style.values["--brand-primary"], "#152D3D");
press("font", "heritage");
assert.match(elem("preview-summary").textContent, /Palatino/);
press("mode", "dark");
assert.ok(elem("preview-canvas").classList.values.has("mode-dark"));
press("device", "mobile");
assert.ok(elem("preview-canvas").classList.values.has("device-mobile"));
press("view", "onboarding");
assert.equal(screens.filter(x=>x.hidden===false).length, 1);
assert.equal(screens[2].hidden, false);
press("tone", "editorial");
assert.match(elem("hero-title").textContent, /afinidad empieza/);
press("shape", "sharp");
assert.ok(elem("preview-canvas").classList.values.has("shape-sharp"));
press("logo", 9);
assert.equal(elem("logo-grid").children[9].attributes["aria-pressed"], "true");
assert.equal(elem("logo-grid").children[0].attributes["aria-pressed"], "false");

elem("brand-name").handlers.input({target:{value:'Nuevo <Nombre> & "Valor"'}});
assert.equal(brandNames[0].textContent, 'Nuevo <Nombre> & "Valor"');
elem("brand-tagline").handlers.input({target:{value:"Estilo propio, vida compartida."}});
assert.equal(elem("phone-tagline").textContent, "Estilo propio, vida compartida.");
elem("save-draft").handlers.click();
const record = JSON.parse(storage.get("mfd.brand-lab.draft.v1"));
assert.equal(record.name, 'Nuevo <Nombre> & "Valor"');
assert.equal(record.logo, 9);
assert.equal(record.palette, "night");

elem("download-logo").handlers.click();
const exportedSvg = blobParts.at(-1).parts.join("");
assert.match(exportedSvg, /&lt;Nombre&gt;/, "SVG export escapes user input");
assert.doesNotMatch(exportedSvg, /Nuevo <Nombre>/);
elem("export-config").handlers.click();
const exportedJson = JSON.parse(blobParts.at(-1).parts.join(""));
assert.equal(exportedJson.owner_approval_required, true);
assert.equal(exportedJson.kind, "visual_experiment_not_production_brand");

elem("reset-draft").handlers.click();
assert.equal(storage.has("mfd.brand-lab.draft.v1"), false);
assert.equal(brandNames[0].textContent, "My Fitness Date");
assert.equal(elem("logo-grid").children[0].attributes["aria-pressed"], "true");
console.log("PASS: Brand Lab live selection, ten logos, local saving, export and reset");
