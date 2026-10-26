# Seguridad y privacidad

Este repositorio contiene un prototipo con datos ficticios. La lógica cliente Gym Shield es exclusivamente demostrativa: no se debe utilizar para proteger privacidad en producción.

Antes de una beta con usuarios:
- Control de acceso en servidor; los gimnasios y horarios deben permanecer en tablas privadas.
- Validación de edad, consentimiento explícito en FitDating, denuncia y bloqueo.
- Restricción y rate limits sobre descubrimiento para evitar inferencia de gimnasio/horarios.
- Registros mínimos, cifrado en tránsito, políticas de retención, borrado, control de abuso.
- No almacenar secretos en el repositorio ni incluir datos reales en pruebas o fixtures.
- Revisión de vulnerabilidades y políticas de las plataformas de distribución.

Para reportar vulnerabilidades, utiliza un canal privado con los administradores del repositorio, no una issue pública que exponga información sensible.
