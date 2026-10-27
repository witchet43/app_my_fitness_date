# Supabase integration — my_fitness_date

## Estado de desarrollo (27 oct 2026)

**Desplegado y probado en** `my_fitness_date_dev`, proyecto `jtrdvnwbxpfdnbzasvcj`, región `us-east-1`.

- Migración `private_dating_gym_shield_v1`: tablas privadas, bloqueos, dos modalidades Gym Shield.
- Migración `dating_birthdate_owner_only`: fecha de nacimiento consultable solo por su propietario.
- Pruebas SQL contra el Supabase real superadas usando usuarios ficticios en una transacción con `ROLLBACK`.
- **No hay cuentas reales** y el servicio no está listo para el público.
- El proyecto React Native/Expo se ha integrado a nivel de código, **pero no se ha probado en un dispositivo físico**.

## Conexión local (desarrollo)

Crea el archivo `.env` en la raíz del repositorio (ya ignorado por Git):

```ini
EXPO_PUBLIC_SUPABASE_URL=https://jtrdvnwbxpfdnbzasvcj.supabase.co
EXPO_PUBLIC_SUPABASE_PUBLISHABLE_KEY=sb_publishable_REEMPLAZAR_POR_LA_CLAVE_PUBLICABLE
```

Consulta la clave **publishable** en [API Keys del proyecto](https://supabase.com/dashboard/project/jtrdvnwbxpfdnbzasvcj/settings/api-keys). No uses ninguna clave `service_role` o `sb_secret_`.

Ejecuta:

```bash
npm install
npm run typecheck
npm test
npm start
```

La pestaña Dating se conectará a Supabase **solo si existen las dos variables**. Sin ellas se mantiene el modo de demostración con datos ficticios. Los gimnasios activos en este entorno son sucursales sintéticas "Gym Demo".

## API y reglas

- `public.gyms`: catálogo RLS, solo lectura para `authenticated`.
- `app_private.dating_profiles`, `training_slots`, `user_blocks`: sin acceso directo de usuarios.
- `public.save_dating_setup(...)`: configuraciones propias, consentimiento y DOB autodeclarado.
- `public.my_dating_setup()`: solo propias preferencias.
- `public.my_dating_birthdate()`: solo propia fecha; jamás la devuelve un perfil candidato.
- `public.discover_dating_candidates(p_limit)`: solo tarjetas que pasan filtro privado y recíproco, nunca gimnasio u horarios.
- `public.disable_dating()` y `public.block_user(...)`: ocultan al usuario y restringen descubrimiento.

### Restricciones

1. Gym Shield exige gimnasio distinto o, si es el mismo, consentimiento recíproco y cero cruces entre todos los intervalos semanales, con margen de 30 minutos.
2. La autenticación y el DOB declarado **no equivalen a verificación de mayoría de edad**.
3. El backend todavía permite inferencia por modificaciones repetidas y descubrimientos. **No permitir beta externa** sin rate limits, auditoría y diseño de anti-inferencia.
4. Antes de beta faltan aceptación de Términos/Privacidad, verificación de edad, denuncias, moderación, eliminación completa y protocolos de seguridad.

## Validación

Las GitHub Actions incluyen pruebas TypeScript, Node, bundle de Android Metro y pruebas PostgreSQL en contenedor desechable. El despliegue real se verificó aparte con una transacción revertida (sin cuentas guardadas).

Documentación adicional: [Iteración 3](ITERATION_3.md) y [Despliegue inicial](DEPLOYMENT_DEV.md).
