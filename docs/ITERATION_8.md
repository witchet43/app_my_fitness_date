# Iteración 8 — Privacidad y baja de cuenta

## Alcance implementado

- Pantalla **Cuenta** para usuarios de desarrollo con estado y exportación personal.
- Exportación JSON como **instantánea técnica parcial**, con datos propios (Auth básico, perfil social, Dating, horarios, posts, eventos, RSVPs, bloqueos, notificaciones, reportes enviados y apelaciones propias).
- Solicitud de baja: contraseña comprobada en la app por Supabase Auth, confirmación textual `SOLICITAR` y RPC autenticada que registra el estado.
- Al solicitar baja: se desactivan las citas, se oculta la cuenta a otros usuarios en Community y Events y se impiden nuevos perfiles, posts, RSVPs y ediciones principales.
- La app lleva a Cuenta cuando existe solicitud pendiente; el usuario puede cancelar voluntariamente. **Las citas no se reactivan automáticamente.**
- Los datos todavía **NO se eliminan** de Auth ni PostgreSQL. La eliminación final permanece condicionada a revisión de dependencias, retención y proceso administrativo probado.
- La respuesta de `my_account_export()` no permite indicar otro usuario; el servidor obtiene `auth.uid()`. La exportación se muestra en la hoja de compartir del dispositivo sin guardarse en la app.

## Controles y límites
- Todas las funciones privadas son SECURITY DEFINER dentro de `app_private`, con `auth.uid()` y `search_path=''`. Las funciones expuestas son SECURITY INVOKER y concedidas exclusivamente a `authenticated`.
- La verificación reciente de contraseña se hace en la interfaz; **no es garantía de reautenticación reforzada validada por el servidor**. Es admisible solo para esta solicitud reversible DEV, no para el borrado irreversible.
- Mantener un proceso manual con confirmación humana en Dev, **no ejecutar un job automático** por transcurso de siete días. Esa fecha es un inicio de revisión, no una promesa de eliminación.
- El export JSON incluye PII: compartir solo con un destino elegido por el propietario.
- Hay datos legales/de moderación con referencias cruzadas y restricciones, almacenamiento Auth y backups. Todavía falta diseñar y verificar su retención/desidentificación antes del borrado definitivo.
- No aceptar usuarios reales ni publicar beta; pendiente revisión legal, privacidad, procedimientos de soporte y verificación de edad.

## Tests
- `anon` no tiene permiso de ejecutar RPC de privacidad ni acceso a esquema privado.
- `authenticated` solo exporta su cuenta y contenido propio.
- Solicitud de baja impide creación de posts y descubrimiento Dating, oculta perfiles de otras cuentas.
- Cancelar restaura visibilidad social manteniendo desactivado Dating.
- CI compila TypeScript, pruebas Node, bundle Android y PostgreSQL.

## Deuda técnica
- Borrado irreversible por flujo privilegiado con trazabilidad y eliminación completa/retención conforme política.
- E2E con dos cuentas Auth reales en dispositivo/simulador; en CI se utilizan roles simulados y pruebas SQL.
- Protección contra reingreso de sesión y contenido residual en pantallas, tokens y cachés; limpieza remota de sesiones.
