# Seguridad y privacidad

**Estado:** código en desarrollo, no listo para producción. El repositorio es actualmente **público**, y no debe contener secretos ni información personal real.

## Controles incorporados en este incremento
- RPC públicas SECURITY INVOKER delegan la lógica a funciones SECURITY DEFINER dentro de `app_private` (no expuesto por Data API).
- Funciones privadas usan `auth.uid()`, `search_path = ''` y concesiones explícitas a `authenticated`.
- Tablas sensibles no conceden lectura/escritura directa a `anon` ni `authenticated`.
- Las respuestas de candidatos no contienen ID de gimnasio, fecha de nacimiento, modalidades ni horarios.
- Bloqueos y desactivación se respetan en recomendaciones.
- CI ejecuta casos de elegibilidad contra PostgreSQL descartable.

## Obligatorio antes de personas reales
- Verificación de edad/identidad. La fecha autodeclarada NO verifica la identidad.
- Rate limit de consultas y cambios de configuración para impedir inferir gimnasio u horarios; análisis de ataques de enumeración.
- Denuncias, moderación, antispam, protección de cuentas y procedimientos de seguridad infantil.
- Borrado de cuenta/datos, minimización, política de retención, consentimiento y cumplimiento legal.
- Pruebas en Supabase de desarrollo real, incluida configuración de esquemas expuestos.
- Revisión de logging, secretos, configuración y operación de la infraestructura.

Reporta vulnerabilidades por un canal privado al propietario del repositorio: no publiques datos sensibles en issues públicas.
