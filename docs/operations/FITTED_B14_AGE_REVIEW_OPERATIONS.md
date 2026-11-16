# FITTED B14 — Operación segura de verificación de adultos (producción)

**Propósito:** permitir que personas mayores de 18 años usen el matching real, con documentación privada, revisión humana, moderación y revocación. No se permite que la sola declaración de fecha de nacimiento apruebe edad.

## Rutas integradas
- Miembro autenticado → Perfil → FitDating → **Verifica tu mayoría de edad**.
- Administrador con sesión **AAL2 / MFA** → Panel administrativo → **Verificación de edad y operación de citas**.
- Mismo administrador → **Pulso Real · confianza y revisión** (apelaciones subjetivas).
- Mismo administrador → **Moderación y privacidad** (reportes comunitarios e incidentes).

## Evidencia requerida
1. El miembro completa su perfil y acepta expresamente el tratamiento específico de documento.
2. Sube imagen JPG/PNG (máximo 5 MB) de identificación oficial vigente con fecha de nacimiento, y una foto actual del rostro.
3. Ambos archivos se almacenan en **bucket privado** `mfd-age-proof`, ruta `<uid>/<requestId>/document` / `selfie`, con RLS. Nunca crear enlace público ni guardar el número de documento.
4. La solicitud queda **pending**. **Ningún archivo ni fecha autodeclarada aprueba la edad**.
5. El administrador con MFA abre ambos archivos, revisa autenticidad visible, coincidencia de imagen y fecha de nacimiento con el perfil, documenta motivo y aprueba/rechaza. La base verifica ≥18 años y coincidencia exacta; ante duda se rechaza. El comprobante expira máximo a 90 días.
6. Tras la decisión el administrador **elimina los archivos con Supabase Storage API** y verifica la confirmación; si falla, aparece en **Eliminación de evidencias pendientes** para reintento. No modificar `storage.objects` directamente (dejaría archivos huérfanos).
7. El miembro puede revocar su verificación; cesa su elegibilidad de inmediato. Atiende solicitudes ARCO al contacto publicado.

## Apertura del matching
- La operación nace **desactivada** y el administrador debe firmar tres compromisos operativos (revisión de edades y moderación, gestión de privacidad, atención de incidentes), identificando la cobertura responsable. No marcar afirmaciones falsas.
- La activación solo cambia el **gate global**. Cada usuario sigue requiriendo sesión válida, verificación manual no vencida, consentimiento explícito de citas, perfil completo y ritmo; no se muestran gimnasios u horarios ajenos.
- El administrador puede suspender el matching con un clic. Esto no sustituye una operación humana real ni una certificación jurídica externa.
- Pulso Real exige consentimiento doble y encuentro confirmado; sus evaluaciones nunca se publican automáticamente y están sujetas a apelación.

## Seguridad y respuesta
- Revisar cada cola con frecuencia y atender reclamaciones; si no hay personal disponible, suspender la operación.
- No almacenar copias de identificaciones en Gmail, mensajería, notas, hojas de cálculo ni herramientas de IA externas.
- Ante documento presuntamente fraudulento, rechazar y registrar solo el motivo mínimo; no copiar números de identificación.
- Si se detecta exposición documental, suspender las cargas, analizar logs de Supabase, valorar notificación e incidente bajo el procedimiento de privacidad vigente.
- La aprobación manual **no es equivalente a un servicio de verificación gubernamental o biométrica con prueba de vida**; el riesgo residual debe comunicarse en los textos legales y revisarse.

## Validación de ingeniería
- 33 migraciones canónicas, negativas B14 de RLS/anon y prueba local completa de aprobación/negación/revocación.
- Flutter analyze + widgets + web release en GitHub Actions, sin Google Cloud Build.
- E2E real con documentos consentidos y personal de revisión no puede automatizarse sin personas que participen. No subir documentos de prueba falsamente atribuidos a un usuario real.
