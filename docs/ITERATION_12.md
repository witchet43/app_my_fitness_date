# Iteración 12 — E2E con Auth real en infraestructura local aislada

## Objetivo

Cerrar la brecha del SQL sintético usado hasta V11. Esta iteración incorpora una segunda CI con un **Supabase real local** (GoTrue + PostgREST + PostgreSQL) para verificar identidad y autorización de extremo a extremo. No usa credenciales ni datos de Supabase hospedado.

## Nuevos componentes

- `supabase/config.toml`: configuración local sin secretos; Auth email confirmation desactivada **exclusivamente en local** para no enviar correos reales; migraciones reales aplicadas por CLI.
- `.github/workflows/local-auth.yml`: job independiente en pull requests, crea entorno aislado con Docker, Auth + REST y destruye los volúmenes al terminar.
- `scripts/local-auth-e2e.mts`: prueba con dos cuentas de tipo `@example.test` creadas por GoTrue y tokens JWT emitidos de verdad. No simula `auth.uid()` por SQL.

## Contratos comprobados por el script

- Usuario anónimo no puede exportar datos ni consultar Community.
- Registro real de dos usuarios, login, rechazo de contraseña errónea, verificación remota de JWT.
- Una cuenta no puede falsificar la autoría ni eliminar publicaciones ajenas.
- Perfil social independiente de Dating.
- Gym Shield desde RPC de servidor: 29 minutos mismo gym denegados, 30 permitidos, consentimiento recíproco y gyms diferentes. La proyección jamás incluye gym, fecha de nacimiento o horarios.
- Baja pendiente: oculta perfil, bloquea publicaciones y descubrimiento Dating; cancelación no reactiva consentimiento.
- Cierre de sesión e ingreso posterior conservan aislamiento de la identidad.

## Límites

- Auth local es **real**, pero no equivale a una prueba de GoTrue **hospedado** ni a una prueba de Android/iOS.
- Confirmación por correo se deshabilita solamente en el Auth local por conveniencia; para validar email de confirmación usar Mailpit y `enable_confirmations = true`.
- El paquete de CLI instalado mediante `npx supabase@latest` puede variar; una vez verde conviene fijar su versión exacta para reproducibilidad y revisar actualizaciones periódicas.
- No habilitar beta pública. Siguen pendientes edad verificada, pruebas físicas, moderación humana, protección contra cuentas múltiples y retención.
- No conectar este proyecto local a un proyecto remoto ni ejecutar `supabase db reset --linked`.

## Desarrollo manual

```bash
npm install
npx supabase@latest start --exclude studio,realtime,storage,functions,analytics,pooler,mail
set -a
eval "$(npx supabase@latest status -o env)"
set +a
MFD_LOCAL_AUTH_E2E=LOCAL_ONLY npm run test:auth:local
npx supabase@latest stop --no-backup
```

**Precaución:** el comando `status -o env` incluye credenciales del stack local; no imprimirlo ni copiarlo en registros públicos. El código rechaza URLs diferentes a `localhost:54321` y las variables de DEV remoto.

Este incremento **no modifica la base hospedada** `my_fitness_date_dev`, que sigue sin usuarios de pruebas.
