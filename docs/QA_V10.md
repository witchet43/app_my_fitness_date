# Iteración 10 — QA integral y bloqueo de sesión

## Corrección funcional de seguridad

La app antes empezaba con estado de baja `false` mientras esperaba la RPC `my_account_status()`. Ahora todas las pantallas privadas permanecen bloqueadas **hasta que el servidor confirme** `pending: false` para el UUID de la sesión actual.

- Si la solicitud de estado falla, no se muestra comunidad ni dating ni datos privados. Hay controles **Reintentar** y **Cerrar sesión**.
- No se reutiliza el resultado del usuario anterior en otro inicio de sesión.
- Cuando la cuenta tiene una baja pendiente, **solo** se habilita Cuenta para revisar/cancelar.
- Al volver a primer plano se renueva el chequeo; el backend sigue siendo autoridad final sobre permisos.
- Se prueba el estado `idle / checking / allowed / error`, cambio de usuario, rechazo de payload inválido y baja pendiente.

## Smoke con dos cuentas reales de QA (solo lectura)

`scripts/smoke-dev.mts` prepara y verifica, contra **el proyecto Supabase DEV explícito**, dos sesiones de cuentas QA *ya existentes y confirmadas*, sin crearlas, sin cambiar perfiles, sin publicar posts ni solicitar bajas.

Antes de ejecutarlo en un equipo administrado, configura las variables en entorno local o un almacén seguro, **nunca las pongas en código, capturas o issues públicas**:

```sh
export MFD_QA_RUN=CONFIRM_READ_ONLY_DEV
export MFD_DEV_URL=https://jtrdvnwbxpfdnbzasvcj.supabase.co
export MFD_DEV_PUBLISHABLE_KEY=sb_publishable_COPIAR_DESDE_DEV
export MFD_QA_A_EMAIL=qa-a@dominio-controlado.example
export MFD_QA_A_PASSWORD='VALOR_SEGURO_LOCAL'
export MFD_QA_B_EMAIL=qa-b@dominio-controlado.example
export MFD_QA_B_PASSWORD='VALOR_SEGURO_LOCAL'
npm run smoke:dev
```

Las cuentas deben ser controladas por el operador, autenticadas y sin solicitudes de eliminación en curso.

**Opcional y desactivado por defecto:** establecer `MFD_QA_PROBE_DATING=YES_CONSUME_QUOTA` prueba que la respuesta de descubrimiento no divulgue gimnasio/horarios/fecha de nacimiento. Esa llamada consume una cuota de rate limit. Este smoke **no valida si dos horarios se emparejan**, porque requiere preparar dos perfiles de prueba con consentimientos y horarios conocidos.

### Comprobaciones automatizadas
- No autenticado: no puede exportar ni consultar catálogo autenticado.
- Dos usuarios: inicio de sesión por contraseña, identidad de Auth validada por servidor, consulta de estado y exportación solamente propia.
- Sin escrituras: lista de gimnasios, publicaciones, eventos, datos propios de Dating y buzón; no se muestran detalles personales en logs.
- Al terminar: cierre de sesiones locales en el ejecutor.

### Revisión móvil manual indispensable
1. Abrir Expo con URL y clave **publishable** de DEV; nunca service_role.
2. Iniciar sesión como cuenta QA A y entrar a Comunidad, Actividades, Citas y Buzón.
3. Cerrar sesión e ingresar con QA B; asegurar que ningún campo del perfil de QA A reaparezca.
4. Desconectar internet antes del chequeo y reabrir la app. Debe mostrar únicamente **Validando acceso / error**, sin contenido. Recuperar red y Reintentar.
5. Solicitar baja en una cuenta QA: únicamente Cuenta debe permanecer navegable. Cancelar; confirmar que Dating sigue apagado.
6. Probar Gym Shield con perfiles QA preparados y consentimientos recíprocos: gimnasio distinto; gimnasio igual sin consentimiento; separación de 29 minutos frente a 30 minutos.
7. Registrar hallazgos sin correos, contraseñas, nombres reales ni horarios individuales.
8. Antes de aceptar beta: repetir en Android e iOS, con verificación de edad, moderación operativa, políticas y seguridad legal.

## Qué se ha ejecutado realmente

CI: pruebas unitarias, validación TypeScript, bundle Android y PostgreSQL con roles ficticios. Sin credenciales QA, el smoke de Auth alojada es una **herramienta implementada y pendiente de ejecución**, no debe contarse como aprobado.

El proyecto DEV conserva cero cuentas reales tras las iteraciones anteriores. No crear cuentas de personas reales sin verificación de edad ni invitar a beta.
