# my_fitness_date

**Red social deportiva con comunidad, actividades y citas opcionales para adultos.**

**Estado (27 oct 2026): candidato de integración V19 exclusivamente de desarrollo. No se ha lanzado una beta, ni se han fusionado los cambios en la rama principal.**

La experiencia de citas se llama **FitDating** y protege el gimnasio y los horarios privados mediante **Gym Shield**. La comunidad deportiva no exige activar las citas.

## Funciones implementadas en las ramas de desarrollo

| Área | Capacidad técnica | Restricciones |
| --- | --- | --- |
| Comunidad | Perfiles sociales, publicaciones y reportes | No hay base de usuarios real |
| Actividades | Eventos deportivos y confirmación privada de asistencia | Solo organizadores autorizados |
| FitDating / Gym Shield | Preferencias privadas, descubrimiento protegido, bloques recíprocos, consentimiento para mismo gym y margen de 30 minutos | Requiere revisión de mayoría de edad por operador; **no se ha verificado a ninguna persona real** |
| Auth | Registro/correo confirmado/recuperación usando GoTrue y Mailpit en stack **local** | Registro hospedado cerrado en UI; configuración Auth hospedada no verificada |
| Buzón | Notificaciones de moderación y apelaciones | No hay actividad real |
| Moderación | Reportes, decisiones auditadas, revisión independiente y cola priorizada de incidentes | Sin moderadores humanos designados |
| Cuenta | Exportación técnica, baja reversible y revisión privilegiada para eliminación Auth | No se ha probado una baja completa con cuenta real; Storage/backups requieren atención separada |
| Privacidad | Inventario de conservación y depuración manual auditada de contadores vencidos | No se borran expedientes; pendiente política legal |

**No hay chat privado, likes ni emparejamiento romántico mutuo operativos.** Descubrimiento de perfiles no equivale a citas realizadas.

## Cómo probar el código

Se requiere Node.js 22+, npm y, para pruebas de autenticación local, Docker con la CLI de Supabase.

\`\`\`bash
npm ci
npm run typecheck
npm test
npm run candidate:audit
npm start
\`\`\`

Sin las variables de Supabase la aplicación muestra exclusivamente datos de demostración. Para pruebas de Auth local usa los procedimientos de \`docs/ITERATION_13.md\`. Nunca publiques una credencial privilegiada en las variables \`EXPO_PUBLIC_*\`.

Las verificaciones automatizadas de GitHub incluyen exportación de bundles JavaScript Android e iOS, PostgreSQL con las migraciones acumuladas, Auth local con JWT reales y Mailpit. **Los bundles no son builds nativos ni pruebas físicas.**

## Proyecto y entrega

- **Repositorio:** \`witchet43/app_my_fitness_date\`.
- **Desarrollo hospedado:** Supabase \`my_fitness_date_dev\`, ref \`jtrdvnwbxpfdnbzasvcj\`. 12 migraciones de negocio/seguridad aplicadas hasta V18.
- **Integración V19:** [PR #23](https://github.com/witchet43/app_my_fitness_date/pull/23), borrador dirigido a \`main\`; no está fusionado.
- **Estado beta:** evaluado mediante \`release/readiness.json\` y \`npm run candidate:audit\`. Una CI verde no autoriza a invitar usuarios.
- **Informe de integración:** [docs/INTEGRATION_V19.md](docs/INTEGRATION_V19.md).
- **Seguridad y reporte de vulnerabilidades:** [SECURITY.md](SECURITY.md).

## Puertas obligatorias para beta

Antes de admitir personas reales faltan la configuración y prueba de email en Auth hospedado, un mecanismo externo y operativo de verificación de edad, personas moderadoras y soporte, política legal de privacidad y conservación, pruebas de eliminación definitiva con cuentas QA autorizadas, pruebas en Android e iOS nativos y revisión de seguridad independiente.

**No fusionar ni desplegar a producción hasta obtener autorización expresa.**
