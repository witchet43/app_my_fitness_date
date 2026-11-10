# Contrato de primer valor y métricas — propuesta no instrumentada
**Estado:** SIN_DATOS. Las métricas no constituyen resultados de usuarios.

## Evento de primer valor candidato
`first_value_completed`: persona adulta autorizada completa participación verificable en una actividad deportiva o interacción comunitaria consentida. Requiere validación con participantes y revisión de seguridad. No se contabilizan logins, swipes, visualizaciones de perfiles ni simples aperturas de la app.

## Taxonomía propuesta, pendiente de DPIA/evaluación de privacidad
| Evento | Cuándo | Propiedades permitidas tentativas |
| --- | --- | --- |
| onboarding_started | flujo comienza | app_version, platform, consent_version |
| onboarding_completed | onboarding finaliza | platform, role |
| first_value_completed | operación confirmada servidor | flow_type, platform, event_schema_version |
| critical_task_failed | fallo en tarea esencial | error_code_general, platform, app_version |
| safety_report_submitted | servidor acepta reporte | categoria no identificatoria, channel |
| support_case_opened | caso aceptado | severity, channel |
| account_deletion_requested | solicitud confirmada | flow, channel |

**Excluido explícitamente de eventos:** nombre, email, ubicación, gimnasio, horarios de entrenamiento, edad exacta, chats, perfiles de terceros, preferencias privadas, JWT, contraseñas, reportes libres y archivos.

## Definiciones base
- Activación: completaron primer valor / nuevas cuentas elegibles por cohorte, rol y canal.
- TTFV: tiempo de alta a primer valor confirmado; mostrar mediana y abandono.
- Éxito de tarea: completadas sin ayuda crítica / intentos válidos.
- Retención: actividad significativa posterior en ventana elegida por frecuencia real.
- Fiabilidad del flujo crítico: intentos confirmados / intentos válidos.
- Seguridad: incidentes severos y tiempo de respuesta real, sin usar un cero sin datos.

Versionado: todo evento debe incluir versión de esquema, propósito, consentimiento/base aplicable, retención y pruebas de emisión/duplicación. Ninguna herramienta analítica puede activarse sin aprobación y costo verificado.

**Dashboard actual:** SIN_DATOS (instrumentación no implementada). **Objetivos numéricos:** PENDIENTE de línea base.
