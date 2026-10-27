# Iteración 3 — Integración móvil Gym Shield

Esta rama mejora el recorrido **de desarrollo** del módulo FitDating ya conectado a `my_fitness_date_dev`.

## Cambios
- El registro requiere fecha de nacimiento declarada y confirmación explícita de mayoría de edad; **no equivale a verificación documental**.
- Al regresar a editar el perfil se recupera la fecha de nacimiento propia mediante la RPC autenticada `my_dating_birthdate`. No se revela a otros usuarios.
- Editor de hasta 14 bloques de entrenamiento con horas independientes por día; ediciones no colapsan horarios distintos.
- Validación previa de horas inválidas, días incorrectos, bloques solapados y registros incompletos.
- CI genera además el bundle Android con Metro y ejecuta pruebas unitarias + SQL.
- La lista de resultados de Dating se actualiza después de guardar, desactivar o bloquear desde el servidor.

## Acceso local a Supabase
El código **no almacena** la clave pública en GitHub. En tu copia local añade `.env` (gitignored):

```ini
EXPO_PUBLIC_SUPABASE_URL=https://jtrdvnwbxpfdnbzasvcj.supabase.co
EXPO_PUBLIC_SUPABASE_PUBLISHABLE_KEY=sb_publishable_TU_CLAVE_EN_SUPABASE
```

La clave **publishable** se encuentra en el panel de API Keys del proyecto. Nunca usar la clave secreta/service_role.
Cuando haya una `.env` válida se habilita el recorrido real de autenticación y preferencias en la pestaña Dating; sin esta configuración continúa la demo ficticia.

## Validación y limitaciones
- Ejecutar `npm install`, `npm run typecheck`, `npm test` y `npx expo export --platform android`.
- Dos cuentas de desarrollo mayores de edad; gimnasios demo, perfiles y horarios.
- Probar actualización de un perfil con dos horarios diferentes: debe conservar ambos en el siguiente ingreso.
- No invitar personas reales. Siguen faltando controles anti-inferencia, limitación de consultas, verificación de edad, bloqueo integral, denuncias y moderación.
- PR #1 y #6 son dependencias aún en revisión.
