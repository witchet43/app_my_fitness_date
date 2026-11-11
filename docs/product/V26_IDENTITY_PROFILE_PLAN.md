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
- **COMPLETADO 10-nov-2026:** el propietario renombró el proyecto Supabase existente `jtrdvnwbxpfdnbzasvcj` a `my_fitness_date_prod` en Project Settings → General. El nombre fue confirmado nuevamente mediante `get_project`; identificador, URL y proyecto existentes se conservan. No crear, pausar, borrar ni transferir proyectos.
- Consent screen y credencial OAuth Google para el dominio público, configurados desde Google Auth Platform; secretos **nunca** compartidos en ChatGPT ni escritos en el cliente.
- Documentos legales de términos/privacidad y mecanismos de consentimiento/seguridad antes de abrir el registro.
- Verificación de edad externa y moderación para FitDating (NO-GO mientras estén pendientes).

## Módulo de perfil V26
Entidad de dueño `member_profile_details`, subentidades `sports`, `interests`, `profile_prompts`, `fitness_goals`, `achievements`, `profile_media`, `private_venues`, `consents`, `visibility`. No modificar `public.social_profiles` para añadir campos sensibles. Nunca mostrar localización exacta, gimnasios habituales ni horarios sin autorización explícita y verificación backend. Mantener separadas las proyecciones propias/comunidad/citas.

## Criterio de entrega
No declarar OAuth operativo hasta completar prueba real de Google+Supabase y confirmar cuenta autenticada con sesión persistida y logout. No activar usuarios reales hasta completar OAuth/consentimiento/backend sobre el mismo proyecto MFD designado PROD. El sitio público no debe quedar con un registro ficticio.


## Decisión confirmada: un solo proyecto Supabase hospedado para My Fitness Date (10 nov 2026)
- Referencia canónica: `jtrdvnwbxpfdnbzasvcj`, URL: `https://jtrdvnwbxpfdnbzasvcj.supabase.co`; **no se cambia el ref**.
- Nombre visible **confirmado por Supabase**: `my_fitness_date_prod` (equivalente a **My Fitness Date PROD**). Cambio de etiqueta completado por el propietario el 10-nov-2026; ref, URL y recursos conservados.
- Estado observado: `ACTIVE_HEALTHY`, 13 migraciones y 0 usuarios en `auth.users`.
- Flutter y API Gateway aceptan este ref **exclusivamente** cuando la configuración de producción y las banderas explícitas están activas; MUV sigue rechazado.
- Ningún flujo QA local puede activarse en `MFD_APP_ENV=prod`. No copiar usuarios sintéticos ni credenciales locales al entorno hospedado.
- El nombre visible no acredita la aptitud de producción: faltan Google OAuth validado, términos/privacidad, seguridad de fotos/edad/moderación, hosting Gateway y pruebas E2E.
- Mantener PR en borrador y V25 en Cloudflare hasta todas las condiciones de V26; sin merge ni despliegue parcial.

## Comprobación del renombrado (10 nov 2026)
- Proyecto `jtrdvnwbxpfdnbzasvcj`, nombre devuelto por `Supabase.get_project`: `my_fitness_date_prod`.
- Estado: `ACTIVE_HEALTHY`, región `us-east-1`.
- La nueva etiqueta no habilita automáticamente OAuth Google, ni habilita API y registro público; la V26 sigue requiriendo comprobaciones E2E, protección de datos y un solo despliegue.
