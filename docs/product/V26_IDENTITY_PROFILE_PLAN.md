# My Fitness Date V26 — Plataforma privada + portada pública

## Qué existe realmente
- Diseño funcional de una portada comercial/registro en Flutter bajo bandera `MFD_REQUIRE_MEMBER_AUTH`.
- Con la bandera activada se muestra **solo** la portada. No hay acceso ni acciones habilitadas de registro o Google sin proveedor PROD.
- V25 sigue publicado; esta rama es un incremento **DRAFT** hasta que se configure identidad PROD, no publicarla en `main` con la aplicación bloqueada.
- El botón Google está correctamente **deshabilitado**; no se simula OAuth.
- QA password local V23 se conserva solo en desarrollo, nunca habilita membresías PROD.

## Acciones que hace el asistente
1. Registro/Google OIDC Authorization Code + PKCE, validación backend y sesiones seguras.
2. Onboarding, diseño y persistencia de perfil personal + deportivo, galería y actividad.
3. Datos privados (gimnasios/studios, zonas y horarios), RLS, privacidad configurable y seguridad.
4. CI verde, revisión de cumplimiento, integración a `main`, despliegue Cloudflare y smoke de commit.

## Acciones que requieren intervención del propietario
- Proyecto Supabase PROD **separado** de MUV/DEV, con costo verificado/aprobado si no hay alternativa gratuita.
- Consent screen y credencial OAuth Google para el dominio público, configurados desde Google Auth Platform; secretos **nunca** compartidos en ChatGPT ni escritos en el cliente.
- Documentos legales de términos/privacidad y mecanismos de consentimiento/seguridad antes de abrir el registro.
- Verificación de edad externa y moderación para FitDating (NO-GO mientras estén pendientes).

## Módulo de perfil V26
Entidad de dueño `member_profile_details`, subentidades `sports`, `interests`, `profile_prompts`, `fitness_goals`, `achievements`, `profile_media`, `private_venues`, `consents`, `visibility`. No modificar `public.social_profiles` para añadir campos sensibles. Nunca mostrar localización exacta, gimnasios habituales ni horarios sin autorización explícita y verificación backend. Mantener separadas las proyecciones propias/comunidad/citas.

## Criterio de entrega
No declarar OAuth operativo hasta completar prueba real de Google+Supabase y confirmar cuenta autenticada con sesión persistida y logout. No activar usuarios reales en Supabase DEV. El sitio público no debe quedar con un registro ficticio.
