# Threat model preliminar — My Fitness Date
**Estado:** revisión inicial de diseño, no pentest ni auditoría independiente.

| Activo / frontera | Amenaza | Defensa requerida | Estado |
| --- | --- | --- | --- |
| Flutter → Gateway | Robo de JWT, replay, abuso de API | HTTPS, PKCE, sesiones revocables, rate limits, Keychain/Keystore | PARCIAL |
| Gateway → Gym Shield | Ingreso directo a servicio interno | IAM privado de Cloud Run, service identity, pruebas negativas | NO_DESPLEGADO |
| Gateway → Supabase Auth | Token expirado/manipulado | Verificación en Auth y control de permisos por recurso, no confiar en cliente | PARCIAL |
| Gym Shield → RPC | BOLA / filtración de gym/horario/preferencias | JWT de usuario, límites por campo, RLS, pruebas de aislamiento | PARCIAL |
| Contenido comunitario | Acoso, abuso, grooming, suplantación | Mayoría de edad verificada, bloqueo, reporte, moderación humana | BLOQUEADO |
| Fotos y ubicación | Doxxing, inferencia de rutina | Consentimiento, visibilidad mínima, no geodatos finos en telemetría | NO_EVALUADO |
| Borrado de datos | Restos en storage, logs y respaldos | Política de retención, E2E, reconciliación e informe de excepciones legales | PARCIAL |
| Agentes e integraciones | Prompt injection / exfiltración | Acciones bajo aprobación y policy enforcement independiente | NO_APLICA_HASTA_INTEGRACION |
| Cadena de software | Dependencias comprometidas / secretos | Lockfiles, escaneo, review, CI, firma y SBOM | PARCIAL |
| Uptime y costos | Fallas silenciosas, cron costoso | heartbeat DB, monitor externo, alertas, tope de consumo | PARCIAL |

Regla de no divulgación: nunca retornar el gimnasio, horarios privados, bloqueos ni motivo exacto de descarte FitDating. Ningún resultado de modelo o configuración cliente concede autorización. Usar pruebas sintéticas y registrar evidencia por threat/PR.
