# Iteración 7 — notificaciones internas y apelaciones

## Funciones nuevas
- Buzón privado de la cuenta con notificaciones cuando se oculta/restaura una publicación y al decidir una apelación.
- Lectura y marcado de notificaciones solo por el propietario; **no** hay email ni push.
- Posibilidad de apelar **una sola vez por publicación** cuando está oculta mediante una decisión registrada. Explicación del autor de 20–500 caracteres.
- El contenido reportado y los datos del denunciante permanecen privados. La notificación no expone identidad del reportante ni comentario del moderador.
- La apelación se resuelve por un **moderador distinto del que ocultó el contenido**: mantener u overturn la decisión con nota de 10–300 caracteres.
- Cuando se acepta una apelación, el post se restaura **solo si no existen otras decisiones vigentes de ocultamiento** relativas al mismo post.
- Estado final, actor y justificación guardados en un registro privado, sin posibilidad de decisión doble para una misma apelación.
- Nueva pestaña «Buzón» para usuarios autenticados y sección «Apelaciones» dentro de Moderación para usuarios autorizados.

## Seguridad y límites
- Todas las tablas en `app_private` con RLS y sin acceso directo `anon/authenticated`.
- La API pública utiliza wrappers SECURITY INVOKER; las funciones de `app_private` comprueban `auth.uid()`/rol de moderador en cada acción.
- Los identificadores de reporter y los reportes de otros usuarios no aparecen en el buzón.
- No se designaron moderadores ni se registraron cuentas reales con este incremento.
- No hay notificadores externos, SLA, personal de moderación, retención, eliminación integral ni verificación de edad. **No abrir beta pública**.
- Rama apilada sobre PR #10; no fusionar a `main` hasta completar revisión de permisos y UX.

## Pruebas
- Anónimo sin ejecutar ninguna RPC de apelaciones/avisos.
- Usuario denunciante sin acceso al buzón ni a apelaciones del autor.
- Propietario: lectura y marcado de aviso, una apelación válida, segundo intento rechazado.
- Moderador inicial no puede decidir la apelación de su propia acción.
- Segundo moderador resuelve apelación y queda auditado; reintento de resolución rechazado.
- Restauración comprobada cuando no hay otra acción activa de ocultamiento.
- Identidades y datos sintéticos usados en transacciones con `ROLLBACK`.
