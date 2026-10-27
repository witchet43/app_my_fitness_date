# Iteración 3 — Flujo móvil Gym Shield

## Entregables
- App Expo con registro, inicio/cierre de sesión, formulario Dating y descubrimiento remoto al configurar Supabase.
- Edad autodeclarada en registro y edición (verificación documental pendiente).
- Obtención de DOB de la propia cuenta mediante `my_dating_birthdate()` autenticada; nunca en resultados de candidatos.
- Editor de hasta 14 bloques de entrenamiento, con días y horas independientes.
- Validaciones de datos, bloques duplicados, solapados y duración inválida.
- Limpieza de información privada del formulario al cerrar sesión o cambiar de cuenta.
- Tests de horarios, autenticación DB y privacidad; CI incluye bundle Android.

## Backend de desarrollo
- Proyecto: `my_fitness_date_dev` / `jtrdvnwbxpfdnbzasvcj`.
- Migraciones V1 Gym Shield y V2 DOB aplicada.
- Validación de ambas en PostgreSQL real con identidades ficticias y `BEGIN...ROLLBACK` (sin dejar usuarios).
- Solo el entorno de **desarrollo**, no producción.

## Cómo probar en un teléfono de desarrollo
1. Preparar el archivo `.env` local con URL y clave **publishable** de Supabase (ver `docs/SUPABASE.md`).
2. Ejecutar `npm install`, `npm test`, `npm start`.
3. Abrir en Expo Go compatible o desarrollo nativo.
4. Crear cuentas **exclusivamente de prueba** con correos controlados y fecha declarada de adulto; seguir confirmación de email si Supabase la solicita.
5. Crear dos cuentas en gimnasios distintos y comprobar descubrimiento.
6. Cambiar a gimnasio igual y horarios con 29 vs 30 minutos de separación; comprobar exclusión/aparición recíproca.
7. Editar horarios de dos días distintos, cerrar sesión e iniciar de nuevo; los dos intervalos deben persistir.
8. Bloquear candidato, desactivar Dating y verificar que no aparezca en descubrimiento.

## Aún no validado
- UX en dispositivo físico y llamadas RPC con tokens de una cuenta creada por la aplicación.
- Verificación de identidad/edad, anti-inferencia, moderación y reportes.
- Comunidad y actividades con datos reales.

**No abrir el registro a público general.** `main` tampoco incluye aún todas las ramas encadenadas.
