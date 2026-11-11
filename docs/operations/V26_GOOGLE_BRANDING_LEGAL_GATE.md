# V26 Google OAuth + legal — gate de liberación única

## Confirmado por capturas y propietario (10 nov 2026)
- Google Cloud: cliente OAuth web My Fitness Date PROD, origen https://my-fitness-date.pages.dev, callback exacto https://jtrdvnwbxpfdnbzasvcj.supabase.co/auth/v1/callback.
- Google Auth Platform Audience: externos, Testing, una cuenta de prueba registrada.
- Supabase Auth: Google habilitado con Client ID y Client Secret ingresados; se indicó que fueron guardados.
- Google Branding: nombre My Fitness Date y homepage correcta; el propietario indicó que eliminó chatgpt.com de los dominios y guardó.
- Proyecto Supabase existente: my_fitness_date_prod, ref jtrdvnwbxpfdnbzasvcj. Se conserva base de datos y migraciones.

## Pendiente
- Google Branding tenía vacías las URL Privacy Policy y Terms of Service.
- Se redactaron documentos para revisión: docs/legal/PRIVACY_V26_DRAFT.md y TERMS_V26_DRAFT.md. **No son aún términos aprobados ni válidos para publicar.**
- Faltan identidad y domicilio del responsable legal, contacto ARCO, finalidades definitivas, retención, verificación de contratos/transferencias, procedimientos y revisión jurídica.
- Publicar páginas estáticas HTML accesibles por robots y personas en /privacy/ y /terms/ de Cloudflare EN LA MISMA LIBERACIÓN V26. Añadir enlaces visibles desde la portada, verificar HTTP 200, contenido/versiones y que las URLs coincidan en Google Branding.
- OAuth Google debe probarse con navegador real y callback/PKCE + sesión, logout y reentrada.
- La API propia necesita hosting PROD y configuración de URL, CORS/seguridad y RLS real de V26, con pruebas de dos usuarios.
- Actualizar release manifest de la V25 anonima y CI/CD, que aún construyen MFD_V26_ENABLED=false. Sin esta actualización el deploy NO activará la aplicación de miembros.
- FitDating sigue no habilitado por verificación externa de edad, consentimiento independiente y moderación.

## Política de despliegue
No se hacen publicaciones parciales: PR #37 continúa en borrador. No se deben introducir URLs 404 en Google ni secretos en el repositorio.
