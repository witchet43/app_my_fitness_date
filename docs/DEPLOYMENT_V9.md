# my_fitness_date — Despliegue DEV, iteración 9

**Fecha:** 2026-10-27  
**Proyecto:** my_fitness_date_dev (jtrdvnwbxpfdnbzasvcj), us-east-1  
**Rama:** feat/privileged-account-erasure-v9, PR #13

## Componentes desplegados

- Migración operator_erasure_preflight_v9, versión 20261027152140.
- Migración erasure_claim_session_guard_v9, versión 20261027152626.
- Supabase Edge Function operator-finalize-erasure, versión 2, ACTIVE, verify_jwt=true.
- El endpoint solo admite la credencial protegida service_role. No se invoca desde Expo ni se almacena su secreto en GitHub.

## Procedimiento de baja

1. El titular presenta su solicitud desde Cuenta. Se desactiva Dating y se oculta su perfil.
2. Una persona administradora revisa identidad, antigüedad mínima de 7 días, procedencia legal, reportes pendientes, auditoría y datos de Storage.
3. Registra manualmente un ticket de aprobación en app_private.erasure_approvals.
4. El sistema administrativo llama a operator-finalize-erasure con el UUID, ticket y confirmación irreversible.
5. La función ejecuta operator_erasure_claim para comprobar condiciones y adquirir el reclamo, que bloquea cancelaciones simultáneas.
6. Solo con un reclamo favorable, la función invoca Auth Admin API para eliminar al usuario.
7. La función verifica que el usuario ya no esté en Auth. Si falla o hay duda, solicita verificación humana; jamás finge completar.

## Bloqueos de seguridad comprobados

- Sin solicitud vigente; período menor a siete días; falta de ticket; aprobación obsoleta.
- Privilegios de moderación u organización todavía vigentes.
- Reportes, apelaciones y referencias de auditoría que exigen revisar conservación/anonimización.
- Eventos futuros con personas inscritas.
- Objetos Storage cuyo propietario es la cuenta solicitante.
- Reclamo de eliminación ya activo.

Si el proceso falla después del reclamo, NO se libera automáticamente. Solo se puede restablecer desde SQL administrativo tras verificar que Auth no mantiene una operación en curso, y que el usuario sigue existiendo.

## Verificaciones

- CI: TypeScript, Node, bundle Android, SQL PostgreSQL desechable: aprobado en ejecución 40530799992.
- Se probó la aceptación de una cuenta ficticia limpia, rechazo de cuentas con historial y rechazo de ticket antiguo.
- El test V9b simula una eliminación de Auth sobre una tabla falsa en CI y verifica que el JWT antiguo no pueda leer Comunidad ni Actividades. **Nunca se ejecutó este borrado de Auth simulado sobre Supabase real.**
- En Supabase DEV: dos migraciones registradas; API de reclamo exclusiva de service_role.
- Después del despliegue: 0 usuarios Auth, 0 aprobaciones, 0 solicitudes de baja.
- Security Advisor: ninguna alerta crítica; 14 observaciones INFO en tablas privadas deliberadamente sin políticas de acceso directo.
- Edge Function activa versión 2 con validación JWT; no se han ejecutado eliminaciones de usuarios reales.

## Límites antes de beta

- Falta prueba de extremo a extremo con cuenta Auth de desarrollo real creada por operador y credencial privilegiada (sin compartir secretos con el chat).
- Falta política jurídica de conservación y tratamiento de evidencias; las cuentas implicadas en moderación deben permanecer bloqueadas para revisión.
- Eliminar la cuenta en Auth no borra inmediatamente los JWT ya emitidos de cualquier servicio. Los endpoints sensibles deben verificar existencia de sesión. RLS social ya comprueba que la identidad continúe en auth.users.
- No se gestionaron fotos u objetos Storage reales; requeriría API Storage.
- No hay ensayo en teléfono físico de una sesión real ni equipo de atención/moderación operativo.
- El repositorio sigue público y los PR #1, #6–#13 están encadenados, sin fusionar en main.
- No autorizar registro público o beta con estos controles incompletos.

## Referencias

- [PR #13](https://github.com/witchet43/app_my_fitness_date/pull/13)
- [Guía funcional V9](./ITERATION_9.md)
- [Supabase DEV](https://supabase.com/dashboard/project/jtrdvnwbxpfdnbzasvcj)
- [Auth User Management](https://supabase.com/docs/guides/auth/managing-user-data)
