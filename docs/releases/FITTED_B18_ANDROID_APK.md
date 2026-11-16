# Fitted B18 · APK Android instalable

Este flujo compila el cliente Flutter **real** de Fitted desde `main`, con
el backend Supabase productivo, onboarding, perfil, tres pilares, resumen IA
consentido, verificación de mayoría de edad, Gym Shield y panel de fits.

## Archivos en GitHub Actions

En **Fitted B18 - Android installable APK from production source**, descargar
el artefacto `fitted-b18-android-installable-apk` (ZIP):
- `Fitted-B18-Android.apk`: instalador Android universal (ARM32/ARM64/x64)
- `SHA256SUMS.txt`: hash criptográfico del instalador
- `build-info.json`: SHA exacto y banderas de privacidad/autenticación

No es una captura, un wrapper web ni la demo sintética Expo V20. El código
Flutter compila contra Supabase y la API productiva.

## Autenticación de Google y enlaces de email

El APK registra un callback PKCE **`fitted://auth/callback`**. Para que
Google regrese al APK, **debe estar incluido exactamente** en:

Supabase Dashboard → Authentication → URL Configuration →
**Redirect URLs** (Additional Redirect URLs) → añadir
`fitted://auth/callback`.

Esto es una configuración de Auth separada de la compilación; el hecho de que
Google funcione en la web no prueba que funcione en Android hasta verificar
la URL permitida y hacer una prueba física de autenticación.

El inicio de sesión mediante correo y contraseña usa el backend real.
Confirmaciones por email y recuperación de contraseña también deben probarse
en un dispositivo, pues el email puede incluir redirecciones.

## Firma y distribución

Hasta configurar una clave de firma Android protegida y persistente (Keystore
de distribución), Flutter compila este APK de tipo release con **certificado
de desarrollo**. Se puede instalar manualmente, pero **no es un artefacto
firmado para Google Play**. No usar como binario de tienda ni prometer
actualizaciones in-place entre compilaciones con keystores distintas.

Para instalar: extraer el ZIP, enviar `Fitted-B18-Android.apk` al teléfono,
abrirlo y permitir la instalación desde esta fuente cuando Android lo solicite.
Solo descargar desde el workflow oficial de `witchet43/app_my_fitness_date`.

## Regla de seguridad

Ni el APK ni el despliegue Android desactivan la revisión humana de edad,
el consentimiento explícito, moderación, RLS, Gym Shield o el control de apertura
del matching. Las cuentas aún no elegibles deben ver el checklist, no perfiles
simulados. El APK contiene únicamente la clave pública de Supabase, nunca
la clave de servicio ni claves privadas de IA.
