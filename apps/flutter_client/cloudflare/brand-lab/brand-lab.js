(() => {
  "use strict";

  // This lab never writes to an application backend. A preview is not a
  // production brand change; only explicit user action saves in localStorage.
  const STORE = "mfd.brand-lab.draft.v1";
  const defaults = Object.freeze({
    name: "My Fitness Date",
    tagline: "Conexiones con intención.",
    palette: "forest",
    font: "editorial",
    logo: 0,
    mode: "light",
    device: "desktop",
    view: "landing",
    tone: "serene",
    shape: "soft",
    custom: {primary: "#28463D", accent: "#B49A6A", background: "#F7F5F0"}
  });
  const palettes = Object.freeze({
    forest: {label: "Bosque", primary: "#28463D", accent: "#B49A6A", background: "#F7F5F0"},
    night: {label: "Azul noche", primary: "#152D3D", accent: "#859EA3", background: "#F4F5F2"},
    earth: {label: "Tierra", primary: "#5A4838", accent: "#B2936A", background: "#FAF5EB"},
    slate: {label: "Pizarra", primary: "#36434A", accent: "#8D9A9D", background: "#F4F5F4"},
    sage: {label: "Salvia", primary: "#455D4B", accent: "#9AA57D", background: "#F8F7F1"}
  });
  const fonts = Object.freeze({
    editorial: {label: "Georgia", heading: 'Georgia, "Times New Roman", serif', body: 'Arial, Helvetica, sans-serif'},
    heritage: {label: "Palatino", heading: '"Palatino Linotype", Palatino, Georgia, serif', body: 'Helvetica, Arial, sans-serif'},
    formal: {label: "Garamond", heading: 'Garamond, "Times New Roman", serif', body: 'Arial, Helvetica, sans-serif'},
    modern: {label: "Sans", heading: 'Arial, Helvetica, sans-serif', body: 'Arial, Helvetica, sans-serif'}
  });
  const logos = Object.freeze([
    "Monograma", "Cadencia", "Cumbres", "Vínculo", "Pulso",
    "Brújula", "Trayectoria", "Horizonte", "Geometría", "Movimiento"
  ]);
  const copy = Object.freeze({
    serene: {
      hero: "Conoce personas afines a tu forma de vivir.",
      description: "Un espacio para personas maduras que valoran las relaciones estables, la vida activa y las conversaciones con intención.",
      phone: "Personas afines. Conexiones auténticas."
    },
    editorial: {
      hero: "La afinidad empieza en la forma de vivir.",
      description: "La convivencia, las prioridades y las buenas conversaciones importan más que compartir exactamente el mismo deporte.",
      phone: "La vida se disfruta mejor con afinidad."
    },
    direct: {
      hero: "Relaciones serias para una vida activa.",
      description: "Conoce personas con valores compatibles, intereses reales y la intención de construir una relación estable.",
      phone: "Encuentra conexiones con intención."
    }
  });
  const hex = value => typeof value === "string" && /^#[0-9a-fA-F]{6}$/.test(value);
  const allowed = (value, all, fallback) => all.includes(value) ? value : fallback;
  const el = id => document.getElementById(id);
  const css = (name, value, node) => node.style.setProperty(name, value);
  let state = {
    ...defaults, custom: {...defaults.custom}
  };
  let changed = false;

  function validate(input) {
    if (!input || typeof input !== "object" || Array.isArray(input)) return null;
    const c = input.custom || {};
    return {
      name: typeof input.name === "string" ? input.name.slice(0, 35) : defaults.name,
      tagline: typeof input.tagline === "string" ? input.tagline.slice(0, 95) : defaults.tagline,
      palette: allowed(input.palette, [...Object.keys(palettes), "custom"], defaults.palette),
      font: allowed(input.font, Object.keys(fonts), defaults.font),
      logo: Number.isInteger(input.logo) && input.logo >= 0 && input.logo < 10 ? input.logo : 0,
      mode: allowed(input.mode, ["light", "dark"], defaults.mode),
      device: allowed(input.device, ["desktop", "mobile"], defaults.device),
      view: allowed(input.view, ["landing", "app", "onboarding"], defaults.view),
      tone: allowed(input.tone, ["serene", "editorial", "direct"], defaults.tone),
      shape: allowed(input.shape, ["soft", "sharp"], defaults.shape),
      custom: {
        primary: hex(c.primary) ? c.primary : defaults.custom.primary,
        accent: hex(c.accent) ? c.accent : defaults.custom.accent,
        background: hex(c.background) ? c.background : defaults.custom.background
      }
    };
  }

  function restore() {
    try {
      const raw = window.localStorage.getItem(STORE);
      if (!raw) return;
      const parsed = validate(JSON.parse(raw));
      if (!parsed) return;
      state = parsed;
      el("save-status").textContent = "Borrador recuperado de este navegador";
    } catch (_) {
      el("save-status").textContent = "Almacenamiento local no disponible";
    }
  }

  function setDirty() {
    changed = true;
    el("save-status").textContent = "Cambios sin guardar · solo vista previa";
  }

  function rgb(hexColor) {
    return [1, 3, 5].map(i => parseInt(hexColor.slice(i, i + 2), 16));
  }
  function contrastInk(hexColor) {
    const parts = rgb(hexColor).map(v => {
      const x = v / 255;
      return x <= .04045 ? x / 12.92 : ((x + .055) / 1.055) ** 2.4;
    });
    const l = .2126 * parts[0] + .7152 * parts[1] + .0722 * parts[2];
    return l > .28 ? "#14211F" : "#FFFFFF";
  }

  function palette() {
    return state.palette === "custom" ? state.custom : palettes[state.palette];
  }

  // Every piece of SVG geometry below is a static, original abstract icon.
  // The only interpolated values are validated #RRGGBB colors.
  function paths(index, p, a) {
    const common = 'fill="none" stroke-linecap="round" stroke-linejoin="round"';
    const geometry = [
      '<path d="M23 58 V17 L43 43 60 20 77 43 97 17 V58" stroke="' + p + '" stroke-width="4.2" ' + common + '/><path d="M26 66 Q60 53 94 66" stroke="' + a + '" stroke-width="2.6" ' + common + '/>',
      '<path d="M15 45 Q34 22 56 36 T103 35" stroke="' + p + '" stroke-width="4.4" ' + common + '/><path d="M18 56 Q39 38 58 48 T100 46" stroke="' + a + '" stroke-width="3.3" ' + common + '/><path d="M26 29 Q48 14 70 29 T99 23" stroke="' + p + '" stroke-width="2" opacity=".65" ' + common + '/>',
      '<path d="M15 60 L45 23 66 46 82 28 106 59" stroke="' + p + '" stroke-width="4.1" ' + common + '/><path d="M35 60 L49 45 58 53" stroke="' + a + '" stroke-width="3.1" ' + common + '/>',
      '<circle cx="47" cy="38" r="21" stroke="' + p + '" stroke-width="3.3" ' + common + '/><circle cx="74" cy="38" r="21" stroke="' + a + '" stroke-width="3.3" ' + common + '/><path d="M57 29 Q64 38 57 47" stroke="' + p + '" stroke-width="2.2" ' + common + '/>',
      '<path d="M25 47 V33 M40 56 V23 M55 63 V16 M70 55 V25 M85 44 V35 M99 49 V30" stroke="' + p + '" stroke-width="4.8" ' + common + '/><path d="M20 69 H103" stroke="' + a + '" stroke-width="2.1" ' + common + '/>',
      '<circle cx="60" cy="39" r="26" stroke="' + p + '" stroke-width="2.5" ' + common + '/><path d="M60 8 L67 33 90 39 66 46 60 71 53 46 29 39 53 33Z" stroke="' + a + '" fill="none" stroke-width="2.1" stroke-linejoin="round"/><circle cx="60" cy="39" r="5" fill="' + p + '"/>',
      '<path d="M43 64 V16 H66 Q94 16 90 35 Q88 53 60 53 H43" stroke="' + p + '" stroke-width="4.4" ' + common + '/><path d="M21 66 H80" stroke="' + a + '" stroke-width="2.5" ' + common + '/>',
      '<path d="M22 44 A38 38 0 0 1 98 44" stroke="' + p + '" stroke-width="3.2" ' + common + '/><path d="M13 47 H106" stroke="' + a + '" stroke-width="2.8" ' + common + '/><path d="M62 69 Q48 54 66 45 Q80 38 73 30" stroke="' + p + '" stroke-width="4" ' + common + '/>',
      '<path d="M15 61 L40 21 L59 49 78 21 105 61" stroke="' + p + '" stroke-width="4.4" ' + common + '/><path d="M40 65 H81 M29 65 H34 M87 65 H92" stroke="' + a + '" stroke-width="2.6" ' + common + '/>',
      '<path d="M18 56 Q44 17 94 35" stroke="' + p + '" stroke-width="3.6" ' + common + '/><path d="M30 62 Q62 43 94 58" stroke="' + a + '" stroke-width="3.2" ' + common + '/><circle cx="71" cy="18" r="6" fill="' + p + '"/>'
    ];
    return geometry[index];
  }

  function mark(index, p, a) {
    return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 120 80" width="120" height="80" aria-hidden="true">' + paths(index, p, a) + '</svg>';
  }

  function renderLogos() {
    const grid = el("logo-grid");
    if (!grid.children.length) {
      for (let i = 0; i < logos.length; i++) {
        const button = document.createElement("button");
        button.type = "button";
        button.className = "logo-option";
        button.dataset.logo = String(i);
        button.setAttribute("aria-label", "Elegir logotipo " + String(i + 1).padStart(2, "0") + ": " + logos[i]);
        const id = document.createElement("span");
        id.className = "logo-id";
        id.textContent = String(i + 1).padStart(2, "0");
        const visual = document.createElement("span");
        visual.className = "logo-art";
        const word = document.createElement("span");
        word.className = "logo-wordmark";
        const sub = document.createElement("span");
        sub.className = "logo-caption";
        sub.textContent = logos[i];
        button.append(id, visual, word, sub);
        grid.appendChild(button);
      }
    }
    const p = palette();
    for (const button of grid.children) {
      const i = Number(button.dataset.logo);
      button.setAttribute("aria-pressed", String(state.logo === i));
      button.querySelector(".logo-art").innerHTML = mark(i, p.primary, p.accent);
      button.querySelector(".logo-wordmark").textContent = state.name.trim() || "Mi marca";
      button.querySelector(".logo-wordmark").style.fontFamily = fonts[state.font].heading;
    }
  }

  function render() {
    const p = palette();
    const canvas = el("preview-canvas");
    const theme = state.mode === "dark";
    canvas.classList.toggle("mode-dark", theme);
    canvas.classList.toggle("device-mobile", state.device === "mobile");
    canvas.classList.toggle("shape-sharp", state.shape === "sharp");
    css("--brand-primary", p.primary, canvas);
    css("--brand-accent", p.accent, canvas);
    css("--brand-bg", theme ? "#101C1A" : p.background, canvas);
    css("--brand-paper", theme ? "#21302C" : "#FFFEFB", canvas);
    css("--brand-ink", theme ? "#F3F4EE" : "#14211F", canvas);
    css("--brand-muted", theme ? "#C4CFC7" : "#52625B", canvas);
    css("--brand-line", theme ? "#405A4F" : "#DEDAD0", canvas);
    css("--brand-heading", fonts[state.font].heading, canvas);
    css("--brand-body", fonts[state.font].body, canvas);
    css("--brand-accent-ink", contrastInk(p.accent), canvas);
    css("--brand-link", theme ? p.accent : p.primary, canvas);

    el("brand-name").value = state.name;
    el("brand-tagline").value = state.tagline;
    el("custom-primary").value = p.primary;
    el("custom-accent").value = p.accent;
    el("custom-background").value = p.background;

    document.querySelectorAll("[data-name]").forEach(node => {
      node.setAttribute("aria-pressed", String(node.dataset.name === state.name));
    });
    document.querySelectorAll("[data-palette]").forEach(node => {
      node.setAttribute("aria-pressed", String(node.dataset.palette === state.palette));
    });
    for (const attribute of ["font", "tone", "shape", "mode", "device", "view"]) {
      document.querySelectorAll("[data-" + attribute + "]").forEach(node => {
        node.setAttribute("aria-pressed", String(node.dataset[attribute] === state[attribute]));
      });
    }

    document.querySelectorAll(".current-name").forEach(node => {
      node.textContent = state.name.trim() || "Mi marca";
    });
    document.querySelectorAll(".current-logo").forEach(node => {
      node.innerHTML = mark(state.logo, p.accent, theme ? "#F1F0E9" : p.primary);
    });
    const content = copy[state.tone];
    el("hero-title").textContent = content.hero;
    el("hero-description").textContent = content.description;
    el("phone-title").textContent = {
      landing: content.phone, app: "Una comunidad para coincidir en lo importante.",
      onboarding: "Tus valores hacen única tu historia."
    }[state.view];
    el("phone-tagline").textContent = state.tagline.trim() || "Conexiones con intención.";
    document.querySelectorAll("[data-screen]").forEach(node => {
      node.hidden = node.dataset.screen !== state.view;
    });
    el("preview-summary").textContent =
      (state.palette === "custom" ? "Personalizada" : palettes[state.palette].label) +
      " · " + fonts[state.font].label + " · Logo " + String(state.logo + 1).padStart(2, "0");
    renderLogos();
  }

  function update(key, value) {
    if (state[key] === value) return;
    state[key] = value;
    setDirty();
    render();
  }

  function installGroup(container, key) {
    el(container).addEventListener("click", event => {
      const button = event.target.closest("button[data-" + key + "]");
      if (button) update(key, button.dataset[key]);
    });
  }

  function download(filename, mime, data) {
    const blob = new Blob([data], {type: mime});
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = filename;
    document.body.appendChild(a);
    a.click();
    a.remove();
    setTimeout(() => URL.revokeObjectURL(url), 1000);
  }

  function xmlEscape(input) {
    return String(input).replace(/[&<>"']/g, c => ({
      "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&apos;"
    }[c]));
  }

  function exportLogo() {
    const p = palette();
    const font = state.font === "modern" ? "Arial" : "Georgia";
    const title = xmlEscape(state.name.trim() || "Mi marca");
    const strap = xmlEscape(state.tagline.trim());
    const svg = '<svg xmlns="http://www.w3.org/2000/svg" width="900" height="330" viewBox="0 0 900 330" role="img" aria-label="' + title + '">' +
      '<rect width="900" height="330" fill="' + (state.mode === "dark" ? "#101C1A" : p.background) + '"/>' +
      '<g transform="translate(350 18) scale(1.65)">' + paths(state.logo, p.primary, p.accent) + '</g>' +
      '<text x="450" y="208" fill="' + (state.mode === "dark" ? "#F3F4EE" : "#14211F") + '" text-anchor="middle" font-family="' + font + '" font-size="57">' + title + '</text>' +
      '<text x="450" y="250" fill="' + (state.mode === "dark" ? "#C4CFC7" : "#52625B") + '" text-anchor="middle" font-family="Arial" font-size="19" letter-spacing="2">' + strap + '</text></svg>';
    download("mfd-brand-lab-logo-" + String(state.logo + 1).padStart(2, "0") + ".svg", "image/svg+xml;charset=utf-8", svg);
    el("save-status").textContent = "Logotipo SVG exportado · no aplicado a producción";
  }

  function saveDraft() {
    try {
      window.localStorage.setItem(STORE, JSON.stringify({version: 1, ...state}));
      changed = false;
      el("save-status").textContent = "Borrador guardado en este navegador";
    } catch (_) {
      el("save-status").textContent = "No se pudo guardar en este navegador; puedes exportar JSON";
    }
  }

  function exportConfig() {
    const output = {
      schema_version: 1,
      kind: "visual_experiment_not_production_brand",
      owner_approval_required: true,
      identity: {...state, colors: {...palette()}},
      note: "Archivo de exploración visual. No configura producción, OAuth, nombre legal, logotipos de tienda ni perfil de clientes."
    };
    download("my-fitness-date-brand-proposal.json", "application/json;charset=utf-8", JSON.stringify(output, null, 2) + "\n");
    el("save-status").textContent = "Propuesta JSON exportada · sin modificar producción";
  }

  restore();
  installGroup("name-presets", "name");
  installGroup("palette-grid", "palette");
  installGroup("font-grid", "font");
  installGroup("tone-switch", "tone");
  installGroup("shape-switch", "shape");
  installGroup("theme-switch", "mode");
  installGroup("device-switch", "device");
  installGroup("view-switch", "view");
  installGroup("logo-grid", "logo");

  // Logo attribute is an integer; the generic update receives a string.
  // Rebind it to preserve the selected index and correct pressed state.
  el("logo-grid").replaceWith(el("logo-grid").cloneNode(true));
  el("logo-grid").addEventListener("click", event => {
    const b = event.target.closest("button[data-logo]");
    if (b) update("logo", Number(b.dataset.logo));
  });

  el("brand-name").addEventListener("input", event => {
    state.name = event.target.value.slice(0, 35);
    setDirty();
    // Avoid resetting cursor selection while the user is typing.
    render();
  });
  el("brand-tagline").addEventListener("input", event => {
    state.tagline = event.target.value.slice(0, 95);
    setDirty();
    render();
  });
  for (const entry of [["custom-primary", "primary"], ["custom-accent", "accent"], ["custom-background", "background"]]) {
    el(entry[0]).addEventListener("input", event => {
      if (!hex(event.target.value)) return;
      const old = palette();
      state.custom = state.palette === "custom" ? {...state.custom} : {
        primary: old.primary, accent: old.accent, background: old.background
      };
      state.custom[entry[1]] = event.target.value;
      state.palette = "custom";
      setDirty();
      render();
    });
  }
  el("save-draft").addEventListener("click", saveDraft);
  el("export-config").addEventListener("click", exportConfig);
  el("download-logo").addEventListener("click", exportLogo);
  el("reset-draft").addEventListener("click", () => {
    if (!window.confirm("¿Restablecer la propuesta en este navegador? No modifica la aplicación pública.")) return;
    state = {...defaults, custom: {...defaults.custom}};
    try { window.localStorage.removeItem(STORE); } catch (_) {}
    changed = false;
    render();
    el("save-status").textContent = "Propuesta restablecida · sin cambios en producción";
  });
  window.addEventListener("beforeunload", event => {
    if (!changed) return;
    event.preventDefault();
    event.returnValue = "";
  });
  render();
})();
