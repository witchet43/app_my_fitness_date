# Despliegue de moderación V17 — my_fitness_date

**Fecha:** 27 de octubre de 2026  
**Supabase DEV:** `my_fitness_date_dev` (`jtrdvnwbxpfdnbzasvcj`, us-east-1)  
**Migración:** `moderation_incident_escalation_v17`, versión `20261027223000`  
**PR:** [#21](https://github.com/witchet43/app_my_fitness_date/pull/21)

## Componentes instalados
- Cola priorizada por motivo, antigüedad y escalamiento: `public.moderator_incident_queue()`.
- Escalamiento autenticado por moderadores y seguimiento por un segundo moderador diferente:
  `public.moderator_escalate_report()` y `public.moderator_review_escalation()`.
- Registro privado de escalaciones `app_private.incident_escalations` y auditoría
  `app_private.incident_audit`, ambos con RLS y sin acceso directo al usuario.
- Decisión `moderator_decide` reforzada: previene decisiones de moderadores sobre
  denuncias que presentaron o en las que son sujetos; bloquea descartar, resolver o
  restaurar antes de segunda revisión cuando existe escalación abierta.
- `app_private.erasure_preflight` reforzado: un usuario que aparece como actor en
  una auditoría o escalación de incidente no pasa el prechequeo de baja sin revisión
  de conservación.
- Interfaz `AdminIncidents` integrada al centro de moderación.

## Evidencia
- [CI general #40595051817](https://github.com/witchet43/app_my_fitness_date/actions/runs/40595051817)
  **SUCCESS**: TypeScript, pruebas unitarias, bundles Android+iOS, integración PostgreSQL
  con denuncia urgente, escalación, conflicto de intereses, segundo revisor y borrado protegido.
- Preflight SQL de migración y suite transaccional V17 ejecutada en Supabase DEV y revertida: aprobada.
- Migración aplicada a Supabase DEV; suite V17 repetida contra el esquema ya instalado,
  ejecutada en `BEGIN/ROLLBACK`: **aprobada**.
- Después de las pruebas: **0** cuentas Auth, **0** moderadores, **0** denuncias,
  **0** escalaciones, **0** acciones de incidentes y **0** auditorías de moderación.
- Anónimo no puede ejecutar la cola. Usuario autenticado puede invocar su wrapper
  pero el servidor **niega acceso** si no es moderador. No puede consultar
  directamente las tablas privadas de incidentes.
- Security Advisor: **0 alertas críticas o warning**. 17 observaciones INFO de RLS
  sin políticas en tablas `app_private` cerradas deliberadamente.

## Límites operativos
La herramienta prepara una cola de trabajo, no la administra automáticamente. Los
plazos 1h/4h/24h/48h son objetivos orientativos internos, **no un SLA cumplido**.
Ningún operador real fue designado ni se han atendido usuarios reales. No hay
alertas automáticas, detección avanzada de comportamiento, escalamiento externo
ni sanciones a cuentas por simple denuncia. El cierre de una escalación tampoco
resuelve automáticamente la denuncia principal. Antes de beta faltan personal
responsable, protocolo de emergencias, política de preservación, verificación
de edad real y pruebas en dispositivos físicos.

`main` y producción no se modificaron. El PR #21 permanece en borrador.
