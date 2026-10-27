# Iteración 9 — Baja definitiva supervisada en DEV

Se implementa un mecanismo administrativo para completar bajas aprobadas, pero no se eliminan cuentas automáticamente.

## Reglas del prechequeo
El backend exige solicitud de baja con al menos siete días de antigüedad, ticket administrativo aprobado, ausencia de roles privilegiados, objetos propios de Storage, eventos futuros con participantes y referencias pendientes en expedientes o auditorías de moderación.

La función operator_erasure_preflight está limitada al rol de servicio. El endpoint operator-finalize-erasure exige credencial privilegiada del servidor y confirmación explícita. Nunca es invocado por la aplicación Expo.

## Cómo funciona
1. El usuario solicita la baja desde la aplicación.
2. Un administrador verifica identidad, plazos y fundamentos de conservación.
3. El administrador registra un ticket en la tabla privada erasure_approvals mediante SQL privilegiado.
4. El operador invoca la función Edge desde un sistema administrativo que mantiene secreta la credencial de servicio.
5. La función consulta la base de datos. Si hay cualquier bloqueo, no elimina nada.
6. Si todo pasa, elimina la identidad mediante Supabase Auth Admin API y verifica que ya no exista.

La eliminación de cuentas con reportes, apelaciones o auditorías se BLOQUEA hasta contar con reglas verificadas de retención y anonimización. No se borran expedientes para forzar el proceso.

## Validación
Las pruebas PostgreSQL verifican rechazo de roles anónimos, solicitudes recientes, falta de aprobación, cuentas con historial de moderación y una identidad sintética sin impedimentos. Se ejecutan sin borrar cuentas reales y sin dejar datos de prueba persistidos.

## Limitaciones
- No existe todavía un operador humano ni plataforma de doble control.
- La función solo puede probarse de extremo a extremo con una cuenta Auth real controlada, ticket de DEV y credencial del servicio; ninguna cuenta real será eliminada durante este incremento.
- Los objetos Storage deben tratarse con su API, no mediante SQL.
- Tras la baja de Auth, los access tokens existentes pueden seguir válidos hasta su expiración.
- Hay copias de seguridad, logs y servicios externos fuera del alcance de este borrado.
- No lanzar beta pública hasta tener políticas de retención, verificación de edad, moderación operativa y validación de sesiones reales en móvil.

## Procedimiento de operación
La designación de tickets solo es posible mediante una sesión SQL administrativa privilegiada, nunca a través de un endpoint para usuarios. No almacenar claves de servicio en repositorios o clientes. La API operativa permanecerá reservada a personal autorizado.

Proyecto DEV: jtrdvnwbxpfdnbzasvcj. Esta rama depende de la iteración 8.
