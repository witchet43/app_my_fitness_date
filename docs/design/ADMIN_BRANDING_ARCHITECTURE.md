# My Fitness Date — Administración independiente de Branding

**Estado:** primera implementación de plataforma administrativa (requiere cuenta dedicada y validación E2E).  
**Actor:** `Brand Administrator` (roles `owner` o `designer`) **separado de FitDating, usuario miembro, moderador y soporte**.  
**UI:** `/admin/branding/`, protegida por login, TOTP MFA y autorización RLS server-side.  
**Issue:** [#53](https://github.com/witchet43/app_my_fitness_date/issues/53).  
**Objetivo:** configuración integral del nombre, identidad, tipografía, paletas, imágenes y logotipos; publicación sujeta a revisión.

## Separación de seguridad

1. **Identidad propia:** una cuenta de Auth creada específicamente para administración; nunca convertir por correo o por metadatos `witchet43@gmail.com` u otra cuenta de miembro en administrador. No existe formulario público de alta de admins.
2. **No comparte sesión:** la consola usa una sesión en memoria propia (sin `localStorage` ni autenticación de las pantallas de usuarios). Recargar exige iniciar sesión de nuevo.
3. **Autorización real en PostgreSQL:** `app_private.brand_administrators`, sin privilegios a `anon` ni `authenticated` para asignar roles; sólo operador privilegiado puede conceder acceso y nunca al identificador que ya posea `member_profiles_v26`.
4. **MFA obligatorio:** TOTP `aal2`, verificado tanto por RLS como por `public.brand_admin_session()` antes de mostrar contenido. AAL1 sólo permite verificar que la cuenta fue previamente nombrada administradora e inscribir MFA; no permite editar.
5. **Medios privados:** bucket `mfd-brand-drafts` con restricciones MIME/tamaño, rutas por usuario y RLS MFA. No se publican URLs firmadas ni medios automáticamente.
6. **Sin credenciales privilegiadas de frontend:** sólo `sb_publishable` documentada para cliente público; el `service_role` jamás se entrega al navegador.
7. **Seguridad extra:** no se aceptan SVG externos activos, HTML, JS, fuentes remotas ni archivos ejecutables. PNG, JPG, WebP hasta 8 MiB; WOFF2 hasta 2 MiB por la interfaz, con licencia declarada. Las imágenes y fuentes deben analizarse/normalizarse antes de publicación global.
8. **Separación física pendiente:** las cuentas administrativas usan una identidad distinta en **el mismo proyecto Supabase Auth** para evitar un segundo proyecto/costo. El aislamiento está en BD/RLS y sesión; **no constituye un proveedor de identidad separado**. Si el requisito «totalmente independiente» exige también Auth en proyecto propio, debe planificarse migración y costos antes del lanzamiento definitivo.

## Capacidades del portal

| Capacidad | Primera implementación | Pendiente para identidad global |
| --- | --- | --- |
| Nombre / lema | Formulario persistente | Propagación a Flutter, legal, correos y tiendas |
| Color | Crear paletas con nombre y 3 tonos, catálogo privado | Tokens extendidos para todos los estados y accesibilidad |
| Fuentes | Catálogo local y subir WOFF2 con licencia | Validación de licencia, publicación en CDN y registro de `font-face` para clientes |
| Logotipos | Diez propuestas del catálogo y subir PNG/WebP | Iconos Android/iOS, favicons, exportaciones y sanitización |
| Imágenes | Cargar portada escritorio/móvil, acceso, onboarding, imágenes interiores | Propagación a todos los slots, recorte/densidad/resolución y optimización |
| Presentación | Radio de borde, modo y composición, vista previa desktop/móvil | Biblioteca de componentes completa y design tokens Flutter |
| Persistencia | Paletas, activos y diseños en Supabase | Sincronización en apps cliente tras release |
| Historial | Revisión inmutable por cada guardado | UI de diff visual, restauración y auditoría de publicación |
| Publicación | Solicitud de revisión sólo por owner | Release pipeline de assets, QA, aprobación, rollout y rollback |

**Honestidad de implementación:** el portal permite configurar y guardar borradores de **sus campos actualmente modelados**. La aplicación pública **no lee ni aplica** esos borradores automáticamente. «100% configurable» es el objetivo arquitectónico, **no una certificación de cobertura ya lograda**.

## Datos

- `app_private.brand_administrators`: cuentas con rol `owner/designer` activas (sin seed).
- `public.brand_palettes`: catálogo de paletas versionables, acceso admin AAL2.
- `public.brand_design_drafts`: diseños y ajustes JSON versionados, control de revisión.
- `public.brand_design_revisions`: instantáneas inmutables por revisión, sólo lectura administrativa.
- `public.brand_assets`: tipos, rutas privadas, nombre, MIME, tamaño, declaración de licencia de fuentes.
- `public.brand_release_requests`: peticiones con estado `pending_review`; sin API pública de publicación.
- `storage.buckets` y `storage.objects`: bucket privado y políticas explícitas sólo para admin con segundo factor.

## Provisión segura del primer administrador

**No se creó ninguna cuenta administradora automáticamente.** La base actual tiene un usuario miembro; reutilizarlo violaría la separación.

Procedimiento de arranque (operador con permisos Supabase, fuera del navegador público):

1. Crear o invitar una **nueva cuenta de correo administrativo** en Supabase Auth, distinta de cuentas de miembros y moderación; confirmar la dirección por su titular.
2. Inscribirla de forma controlada mediante SQL de operador, **usando el UUID exacto** recibido de Auth. Nunca otorgar privilegios sólo porque un correo coincida con una cadena:
   ```sql
   -- Reemplazar UUID después de revisar la identidad, NO ejecutar con placeholders.
   insert into app_private.brand_administrators(user_id,role)
   select u.id, 'owner' from auth.users u
   where u.id = '<UUID-EXACTO-VERIFICADO>'::uuid
     and u.email_confirmed_at is not null
     and not exists(select 1 from public.member_profiles_v26 p where p.user_id=u.id)
   on conflict (user_id) do nothing;
   ```
3. Iniciar sesión desde `/admin/branding/` con email/contraseña propios; inscribir/validar TOTP. El backend no concede lecturas ni escrituras mientras el JWT no sea `aal2`.
4. Verificar: invitado normal 403/denegado; miembro existente rechazado; admin AAL1 sin acceso a tablas; admin AAL2 con acceso a diseños; Storage privado sin permisos anónimos.
5. Registrar el acta y evidencia de bootstrap; asegurar mecanismo de recuperación de acceso y segundo administrador de respaldo.

**Nunca** insertar contraseñas directamente en `auth.users`, ni usar `user_metadata`, ni compartir en ChatGPT secretos TOTP.

## Pendientes antes de habilitar publicación de identidad global

- Motor de design tokens para Flutter + webs y catálogo completo de slots (landing, registro, perfil, FitDating, correos, splash, icono).
- Verificación de contraste WCAG 2.2 AA, licencias y derechos de imagen, copyright de tipografías, avisos legales y seguridad de assets.
- Proceso de publicación **atómico con versionado, rollback y confirmación del propietario**; no exponer recursos en el bucket privado ni permitir URLs de usuario sin validación.
- Revisión de seguridad ofensiva (BOLA/RLS, phishing, XSS, polyglot de imágenes, WOFF2 malformado, revocación MFA), UX con público 40+, controles de pagos/costos.
- Definir dominio/subdominio admin aislado y, si se exige, proveedor de identidad separado del que usan miembros.

## Referencias

- [Brand Lab actual](BRAND_LAB_IMPLEMENTATION.md) — experimento público, sólo estado local.
- [Estándar de diseño 40+](SERIOUS_RELATIONSHIPS_40PLUS_BRAND_STANDARD.md) — PR #47 aún pendiente a fecha de este cambio.
- [SaaS Factory v1.9](https://docs.google.com/document/d/11hytKADuIUpmWzHEmAfZwcYNJ04M7n1ev4A1fbeZy9Q/edit) — seguridad, arquitectura, DevSecOps, accesibilidad, costos y release.
