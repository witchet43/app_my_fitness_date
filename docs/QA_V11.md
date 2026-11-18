# Iteración 11 — Integración del MVP con dos identidades QA sintéticas

## Alcance validado automáticamente

La prueba `supabase/tests/mvp_e2e_v11.sql` ejecuta un recorrido conectado, de principio a fin, contra PostgreSQL con todas las migraciones anteriores:

1. Dos identidades sintéticas independientes activan perfiles sociales; las citas siguen opt-in.
2. A publica, B consulta el feed sin recibir atributos íntimos de A.
3. A organiza una actividad por autorización explícita; B confirma asistencia; A **no** ve el RSVP privado de B.
4. Ambos activan Gym Shield: mismo gimnasio con **29 minutos de diferencia se excluye**; con **30 minutos se permite**.
5. B retira el consentimiento para matches del mismo gym: A ya no lo ve.
6. B selecciona un gimnasio diferente: vuelve a ser elegible pese a horarios coincidentes.
7. B solicita baja: su perfil no aparece en el feed ni en citas y no puede publicar.
8. Toda la prueba queda dentro de `BEGIN/ROLLBACK`, sin usuarios Auth ni datos persistidos.

Estas pruebas simulan roles Auth a través del contexto JWT de PostgreSQL. **No** constituyen un inicio de sesión real contra GoTrue/Auth ni una prueba de Android.

## Navegación móvil

Se cambió la barra horizontal para que las seis secciones de una cuenta (Comunidad, Actividades, Citas, Buzón, Moderación cuando corresponda y Cuenta) sean accesibles mediante desplazamiento horizontal. El área de moderación sigue dependiendo del rol del backend.

## QA alojado y dispositivos: pendientes

Supabase `my_fitness_date_dev` está vacío de usuarios Auth: no se han generado contraseñas QA ni realizado test de inicio de sesión en teléfono. El archivo `scripts/smoke-dev.mts` de la iteración 10 puede verificar dos cuentas existentes y confirmadas, **sin cambiarlas**:

```sh
MFD_QA_RUN=CONFIRM_READ_ONLY_DEV \
MFD_DEV_URL=https://jtrdvnwbxpfdnbzasvcj.supabase.co \
MFD_DEV_PUBLISHABLE_KEY=<CLAVE_PUBLICABLE_DEV> \
MFD_QA_A_EMAIL=<EMAIL_QA_A> MFD_QA_A_PASSWORD=<PASSWORD_QA_A> \
MFD_QA_B_EMAIL=<EMAIL_QA_B> MFD_QA_B_PASSWORD=<PASSWORD_QA_B> \
npm run smoke:dev
```

No proporcionar contraseñas en el chat ni en GitHub. Crear cuentas QA únicamente en un entorno controlado usando métodos oficiales de Supabase Auth (por ejemplo registro/confirmación con correo controlado), o ejecutando Supabase local con Mailpit para no enviar correos reales. La autenticación hospedada puede restringir el correo a miembros de la organización.

Para validar UX, se requieren Android e iOS con sesiones reales, alternando cuentas y comprobando que no se filtran horarios, credenciales o datos privados entre sesiones. La prueba SQL y la exportación del bundle Android no equivalen a validar una interfaz real.

## Bloqueos para beta

Verificación de edad, moderación operativa, tratamiento legal de datos y registros de Gym Shield, protección contra cuentas múltiples e inferencia, borrado integral, pruebas reales en dispositivo y revisión de seguridad independiente. Ningún cambio se fusionó a `main`.
