# Seguridad de my_fitness_date

**Estado:** desarrollo y candidato de integración V19. Repositorio público. **Prohibido almacenar secretos, tokens o datos personales reales en GitHub.** La beta está bloqueada.

## Medidas implementadas

- \`app_private\` no expuesto por Data API; funciones de negocio con \`auth.uid()\`, validación de roles, permisos explícitos y \`search_path\` restringido. RLS en tablas relevantes.
- Gym Shield con consentimiento recíproco, ocultamiento de gimnasio y horario, margen de 30 minutos, bloqueos y límites de consultas.
- Edad: puerta técnica por aprobación externa y revocación; ninguna persona fue realmente verificada.
- Reportes, apelaciones, auditorías, conflictos de interés, prioridades y segunda revisión. Sin atención humana operativa.
- Exportación personal, solicitud de baja reversible y operador protegido para revisar eliminación Auth. Tokens antiguos y datos de Storage/backups requieren evaluación aparte.
- Inventario y limpieza manual de cuotas antiguas: no afecta a las evidencias de denuncias, apelaciones o incidentes.
- Tests PostgreSQL, GoTrue/Mailpit local y bundles JavaScript Android/iOS en GitHub Actions.

## No resuelto / riesgo de lanzamiento

- Configuración efectiva de correos y control de altas en Auth hospedado (la ocultación de botones no sustituye el bloqueo del servidor).
- Integración externa y jurídica de verificación de mayoría de edad.
- Atención a incidentes, revisión de abuso, antispam y operadores autorizados.
- Verificación de la baja real y tratamiento de fotografías, archivos, respaldos y registros del proveedor.
- QA con sesiones reales en Android/iOS, pruebas ofensivas de privacidad/IDOR/múltiples cuentas y seguridad independiente.
- Revisión del contrato de retención y solicitudes de derechos sobre datos personales.
- Sin mensajes/chat románticos ni matching mutuo; no anunciar capacidades inexistentes.

El manifiesto \`release/readiness.json\` requiere evidencia fechada para cada puerta. \`npm run candidate:audit\` revisa la preparación sin habilitar usuarios. \`npm run candidate:require-beta\` falla mientras persistan pendientes.

**Reportes de seguridad:** contactar al propietario por un canal privado, sin incluir credenciales o PII en issues públicos.
