(() => {
  "use strict";

  const authBase = "https://jtrdvnwbxpfdnbzasvcj.supabase.co";
  const publishableKey = "sb_publishable_IAPJ1C1EdLg155iMOgRNfg_i6OWuJkk";
  const callbackPath = "/admin/branding/reset-password/";
  const el = id => document.getElementById(id);
  const feedback = el("reset-feedback");
  const formRequest = el("request-form");
  const formPassword = el("password-form");

  // Only for one password-recovery transaction; never persisted in the browser.
  let temporaryToken = "";
  let busy = false;

  function notify(message, error = false) {
    feedback.textContent = message;
    feedback.style.color = error ? "#923d36" : "#3b6750";
  }

  async function authRequest(path, {method = "GET", bearer = "", body} = {}) {
    const response = await fetch(authBase + path, {
      method,
      credentials: "omit",
      cache: "no-store",
      headers: {
        apikey: publishableKey,
        "Content-Type": "application/json",
        ...(bearer ? {Authorization: "Bearer " + bearer} : {})
      },
      ...(body === undefined ? {} : {body: JSON.stringify(body)})
    });
    if (!response.ok) {
      if (response.status === 429) throw new Error("Demasiados intentos. Intenta nuevamente más tarde.");
      if (response.status === 403) throw new Error("No hay autorización para esta operación.");
      if (response.status === 422) throw new Error("La contraseña no cumple los requisitos de seguridad.");
      throw new Error("No se pudo completar la operación de forma segura.");
    }
    return response.status === 204 ? null : response.json();
  }

  function clearRecoveryUrl() {
    // OAuth-style recovery session fragments must never survive in the address
    // bar, browser history or exported links.
    window.history.replaceState(null, "", window.location.pathname);
  }

  async function consumeRecoveryLink() {
    const hash = window.location.hash.slice(1);
    const query = window.location.search.slice(1);
    if (!hash && !query) return;
    const params = new URLSearchParams(hash || query);
    // Scrub before any async work, including verifying credentials.
    clearRecoveryUrl();
    const type = params.get("type");
    const token = params.get("access_token");
    if (!["recovery", "invite"].includes(type) || !token) {
      notify("El enlace de acceso no es válido o ha caducado. Solicita uno nuevo.", true);
      return;
    }
    try {
      const [user, isAdmin] = await Promise.all([
        authRequest("/auth/v1/user", {bearer:token}),
        authRequest("/rest/v1/rpc/brand_admin_status", {
          method: "POST", bearer:token, body:{}
        })
      ]);
      if (!user?.id || isAdmin !== true)
        throw new Error("El enlace no corresponde a una cuenta administrativa autorizada.");
      temporaryToken = token;
      formRequest.hidden = true;
      formPassword.hidden = false;
      el("new-password").focus();
      notify("Acceso verificado. Ya puedes establecer tu contraseña.");
    } catch (error) {
      temporaryToken = "";
      notify(error.message, true);
    }
  }

  async function sendRecovery(event) {
    event.preventDefault();
    if (busy) return;
    const email = el("recovery-email").value.trim();
    if (!email || email.length > 254) return;
    busy = true;
    const button = formRequest.querySelector("button");
    button.disabled = true;
    try {
      const redirectTo = window.location.origin + callbackPath;
      await authRequest("/auth/v1/recover?redirect_to=" +
        encodeURIComponent(redirectTo), {method:"POST", body:{email}});
      // Do not reveal whether a particular email exists.
      notify("Si la dirección corresponde a una cuenta, llegará un enlace para crear la contraseña. Revisa tu bandeja y correo no deseado.");
    } catch (error) {
      notify(error.message, true);
    } finally {
      busy = false;
      button.disabled = false;
    }
  }

  async function setPassword(event) {
    event.preventDefault();
    if (busy || !temporaryToken) {
      notify("Solicita un enlace de recuperación válido.", true);
      return;
    }
    const password = el("new-password").value;
    const confirmation = el("confirm-password").value;
    if (password.length < 12 || password.length > 128) {
      notify("Utiliza una contraseña de 12 a 128 caracteres.", true);
      return;
    }
    if (password !== confirmation) {
      notify("Las contraseñas no coinciden.", true);
      return;
    }
    busy = true;
    const button = formPassword.querySelector("button");
    button.disabled = true;
    try {
      await authRequest("/auth/v1/user", {
        method:"PUT", bearer:temporaryToken, body:{password}
      });
      // Revocation is best effort; do not expose or retain the recovery token.
      const token = temporaryToken;
      temporaryToken = "";
      el("new-password").value = "";
      el("confirm-password").value = "";
      try {
        await authRequest("/auth/v1/logout", {method:"POST", bearer:token});
      } catch (_) {}
      formPassword.hidden = true;
      notify("Contraseña establecida. Regresa al inicio de sesión y continúa con el segundo factor MFA.");
    } catch (error) {
      notify(error.message, true);
    } finally {
      busy = false;
      button.disabled = false;
    }
  }

  formRequest.addEventListener("submit", sendRecovery);
  formPassword.addEventListener("submit", setPassword);
  window.addEventListener("pagehide", () => {temporaryToken = "";});
  consumeRecoveryLink();
})();
