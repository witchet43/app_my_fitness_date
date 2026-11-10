# MVP — Estado de integración V19

**Candidato de revisión del código, no versión publicable.** Las 18 iteraciones anteriores están apiladas en PR en borrador. El PR #23 integra su historial para revisión contra \`main\`; no se ha fusionado.

## Capacidades técnicas actuales

| Dominio | Implementado | Pendiente antes de beta |
| --- | --- | --- |
| Comunidad | Perfiles, feed, publicaciones y reportes con RLS | QA real, antispam operativo |
| Actividades | Eventos, organizadores autorizados, RSVPs privados | Calendario público/crecimiento, QA real |
| Dating | Descubrimiento opcional Gym Shield con dos modos | Verificación externa real de edad, evaluación antiinferencia |
| Auth | Sign-up OTP y recuperación verificados con GoTrue+Mailpit **local** | Configuración hospedada, correo real controlado y móvil |
| Moderación | Bloqueo, ocultamiento, apelaciones, cola y segunda firma | Nombramiento de moderadores, protocolo de emergencias |
| Cuenta/privacidad | Exportación técnica, baja en espera, preflight/claim Auth Admin, inventario y retención | Baja end-to-end real, retención legal, Storage/backups |
| QA móvil | Bundles Metro de Android/iOS, selectores Maestro y navegación accesible | Instalar y probar builds nativos en dispositivos |
| Mensajería romántica | No implementada | Likes, matching mutuo y chat si se incorporan al alcance |

## Requisitos Gym Shield conservados

- Otros gimnasios: no se devuelven miembros del mismo gimnasio.
- Mismo gimnasio, otro horario: consentimiento recíproco, horarios semanales válidos, sin solapamiento y separación mínima de 30 minutos.
- No se exponen gimnasios, horarios privados, DOB ni razones de exclusión.
- Bloqueos y solicitudes de baja retiran perfiles del descubrimiento.
- Las aprobaciones administrativas de edad caducan y se pueden revocar; autodeclaración de nacimiento no activa Dating.
- Máximo 10 candidatos por llamada y 10 consultas de descubrimiento por hora. Es una limitación de sondeo, no prueba de resistencia frente a múltiples cuentas.

## Condiciones de aceptación y seguridad

Se audita el manifiesto \`release/readiness.json\` que **debe seguir bloqueado** hasta acumular evidencia independiente para autenticación hospedada, verificación de edad, moderación real, bases legales, eliminación Auth, QA nativo, seguridad y soporte. No cambiar a \`verified\` solo porque las pruebas unitarias sean verdes.

Supabase DEV dispone de las migraciones V1–V18 según el historial. **Cero usuarios** no equivale a un flujo probado con clientes hospedados ni a preparación de beta.

Los requisitos de protección de datos en México requieren revisión jurídica; los 30 días de contadores son un umbral técnico, no una política legal aprobada.
