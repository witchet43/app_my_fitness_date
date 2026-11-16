# FITTED — Pulse & Presence + Pulso Real B12 (2026-11-16)

## La marca es real; la confianza también debe serlo

La experiencia visual sustituye el aspecto plano por geometría inspirada en el
movimiento: curvas de Bézier, ondas de ritmo, anillos superpuestos, acentos menta,
albaricoque e iris y superficies de cristal. Mantiene la tipografía editorial
sobria, el diseño responsivo, el login real y los colores/imágenes configurados
por la administración donde ya existe el ajuste correspondiente.

## Concepto propio: Pulso Real

No consiste en que un exmatch marque unilateralmente a alguien como **mentiroso**.
Una cita es una experiencia y no puede comprobar, por sí sola, que alguien
"siempre" practica una actividad. Se registran tres dimensiones de vida:
How I Move, How I Live y How I Relate, con tres observaciones:
- Coincidió con lo que me dijo.
- No pude comprobarlo.
- No coincidió con mi experiencia.

### Reglas de seguridad
1. Solo un match activo, adulto, sin bloqueos, sujeto a todos los gates B5/B11.
2. Dos confirmaciones independientes del encuentro.
3. Consentimiento B12 de ambos, específico y revocable. Retirarlo elimina
   registros relacionados y confirmaciones, sin borrar denuncias de seguridad.
4. Máximo una evaluación por dimensión, por persona y por match; sin texto
   difamatorio libre, sin gimnasio, rutas, horarios o domicilio.
5. Las observaciones se guardan en `app_private`, sin acceso directo de
   usuarios ni anónimos; jamás aparece una acusación automáticamente.
6. Toda señal queda `pending`; cualquier presentación pública agregada requiere
   proceso de moderación humana, apelación y privacidad aprobados.
7. Actualmente no hay mecanismo acreditado de verificación independiente de
   que la cita ocurrió: confirmar ambas partes reduce abuso pero no es prueba.
8. No activar esta recogida de feedback ni migrar la base de producción sin
   verificaciones de edad, moderación, políticas de privacidad y pruebas E2E.

## Despliegue

El sitio principal puede adoptar la identidad visual Flutter sin habilitar
descubrimiento ni evaluaciones pendientes. El backend B12 se entrega como
migración y API **sin ejecutarlas en producción**, porque la base hospedada
sigue sin esquema B11 y no existe moderación operativa acreditada.
QA aislada en GitHub PostgreSQL/Flutter/TypeScript, sin Google Cloud Build.

## Qué significa producción

**Sitio y autenticación existentes**: despliegue Cloudflare con el frontend nuevo.
**FitDating y Pulso Real a personas reales**: no liberados hasta evidenciar gates
de seguridad, legalidad, moderación, consentimiento y QA de dispositivos.
No asumir que "CI en verde" equivale a una beta lista.
