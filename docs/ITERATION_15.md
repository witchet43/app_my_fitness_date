# Iteración 15 — Preparación segura de Auth hospedado

**Proyecto único:** `my_fitness_date_dev` (`jtrdvnwbxpfdnbzasvcj`).

## Qué se implementó
- Plantillas OTP españolas para confirmación y recuperación en `supabase/templates/hosted-*.html` usando `{{ .Token }}`, alineadas con el flujo móvil de V13.
- Política auditada de GoTrue: `disable_signup=true`, `mailer_autoconfirm=false`, email provider habilitado y plantillas exactas.
- `scripts/hosted-auth-config.mts`: comandos para auditar (GET) y aplicar (PATCH) la configuración mediante la **Management API oficial**; solo funciona para la referencia exacta de desarrollo y verifica el resultado.
- Por defecto, la app **no muestra ni ejecuta registro**: solo permite login, confirmación y recuperación de cuentas previamente autorizadas. La prueba de registro en interfaz solo se habilita con `EXPO_PUBLIC_QA_SIGNUP_FLAG=LOCAL_QA_ONLY` y URL local `http://localhost:54321` (o `127.0.0.1`).
- Tests de reglas de host, seguridad y plantillas ejecutados en CI.

## Estado del despliegue hospedado

El conector Supabase de la sesión puede leer base/asesores, pero **no expone lectura ni modificación de Auth Management Config**. Por tanto no se puede afirmar que estas plantillas o flags ya estén instalados en la instancia hospedada. El operador deberá ejecutar el siguiente procedimiento con su token de alcance `auth_config_read` / `auth_config_write`. No compartirlo con ChatGPT ni subirlo al repositorio.

1. Crear un token personal adecuado o de alcance restringido en Supabase Dashboard, guardado solo en el gestor de secretos del operador.
2. Desde el repositorio, en un equipo bajo control del operador:
   ```bash
   npm install
   export SUPABASE_ACCESS_TOKEN='<TOKEN_DE_OPERADOR_SOLO_LOCAL>'
   npm run auth:hosted:audit
   ```
   El comando **solo lee** la configuración, imprime exclusivamente resultados booleanos y puede terminar con código 2 si faltan ajustes.
3. Revisar que se desea **cerrar las altas públicas**. Solo en DEV, con autorización explícita y el token disponible:
   ```bash
   export MFD_HOSTED_AUTH_APPROVAL=LOCK_jtrdvnwbxpfdnbzasvcj
   npm run auth:hosted:lock
   ```
   Hace PATCH del conjunto mínimo de claves y GET de verificación. **No** activa el registro; lo desactiva. No modifica SMTP ni OAuth.
4. Repetir `npm run auth:hosted:audit` y comprobar `ready:true`.

Alternativa sin script: ir a [Authentication de DEV](https://supabase.com/dashboard/project/jtrdvnwbxpfdnbzasvcj/auth/providers) y mantener **Allow new users to sign up = OFF** y **Confirm Email = ON**. Después ir a [Email Templates](https://supabase.com/dashboard/project/jtrdvnwbxpfdnbzasvcj/auth/templates), seleccionar Confirm sign up y Reset password, y copiar los HTML de `supabase/templates/hosted-confirmation.html` y `hosted-recovery.html`.

## Prueba de correo real: NO ejecutada
El SMTP integrado de Supabase hospedado solo envía a direcciones autorizadas del equipo y tiene cuotas muy reducidas. No es Mailpit: se necesita una casilla QA autorizada de la organización y respetar límites; no habilitar el signup público ni enviar mensajes de prueba sin control del operador. Para una beta, SMTP propio verificado o Send Email hook, protección anti-abuso, URL/site/redirect, captcha y límites.

**No crear ni verificar nuevas cuentas reales hasta contar con identidad de QA controlada.** Las pruebas V13 de GoTrue+Mailpit en local siguen siendo el nivel de certificación alcanzado.

## Evaluación de seguridad
- No se usan metadatos modificables de usuario para permisos.
- Credenciales de Management API jamás en `EXPO_PUBLIC_*` ni GitHub.
- El flag UI de registro es conveniencia, **no reemplaza** el cierre del registro en el servidor.
- Una política marcada como ready no garantiza entrega real del correo, SPF/DKIM/DMARC, ni uso en iOS/Android.
- La beta pública sigue bloqueada por edad verificada, moderación operativa y pruebas físicas.
