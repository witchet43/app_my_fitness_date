# Fitted — consentimiento global de IA por cuenta (v1)

## Contrato de producto

- Después de aceptar Términos y Privacidad y antes del primer perfil de miembro, la cuenta elige **Activar IA** o **Continuar sin IA**. No se asume consentimiento por crear una cuenta, aceptar términos, activar citas, subir información o responder cuestionarios.
- Una sola preferencia auditada de cuenta `fitted_ai_account_preferences_v1` gobierna cualquier procesamiento mediante modelos externos: Fit-IA (tres pilares), comentarios y resúmenes privados, y futuras integraciones de IA. El ajuste se muestra en **Cuenta → Configuración → Inteligencia artificial**.
- Toda integración actual o futura **DEBE** consultar del lado servidor `public.fitted_ai_account_preference_v1()` usando el JWT verificado del propietario **antes de cada nueva llamada externa de IA**. Si `configured != true` o `enabled != true`, no se envían datos al modelo y se devuelve modo guiado/manual o `consent_required`. No basta con ocultar la UI.
- Los RPC heredados de Fit-IA y de resumen ahora delegan la decisión a `fitted_set_ai_account_preference_v1`. No se crean interruptores IA por cada pilar o pantalla. Un rechazo inicial se registra del mismo modo que una aceptación.
- El usuario puede revocar en cualquier momento. La revocación impide **nuevas** solicitudes externas, sin afirmar que puede cancelar llamadas ya iniciadas. Respuestas, borradores y textos manuales no se eliminan; la eliminación de conversaciones se maneja por una acción separada.
- Activar IA no activa ni supone autorización para publicar perfil, compartir resúmenes, mostrar actividad de Strava, emparejamientos, compartir fotos, revelar ubicaciones, verificar edad, procesar documentos o habilitar citas. Estos controles son independientes y no deben cambiar al activar o desactivar IA.
- No se envían ubicaciones precisas, nombres de gimnasios, horarios exactos, documentos de identidad, fotos privadas ni contactos a proveedores de IA. Sólo datos seleccionados del perfil y respuestas que cada función permite y minimiza. La persona es informada del uso de OpenAI.
- Fallos de consulta de preferencia deben **fallar cerrados**: no usar un modelo como fallback. No almacenar claves de proveedores en clientes.
- El cambio de preferencia queda registrado sin conservar datos de solicitudes ni el texto de las conversaciones en el historial de consentimiento.

## Pruebas de regresión obligatorias

1. Usuario nuevo sin preferencia: ve la decisión una vez, IA desactivada hasta seleccionar.
2. Activar: Fit-IA y resumen verifican preferencia habilitada; nada se publica.
3. Desactivar: ni conversación ni resumen envían nueva solicitud de modelo; modo guiado/manual continúa.
4. Cambiar en Configuración y sincronizar en otra sesión sin duplicar consentimiento.
5. Administrador mantiene una experiencia separada, sin pantalla de consentimiento de miembro.
6. Cambiar IA no altera `share_consented`, `dating` o preferencias de privacidad, ni borra respuestas.
7. Otro miembro no puede leer/escribir la preferencia ajena; intentos anónimos se rechazan.

## Evolución

Toda nueva función que incorpore IA, incluidos resúmenes derivados de aplicaciones deportivas conectadas, debe implementar el mismo gate del servidor antes de enviarse al proveedor. La conexión OAuth a aplicaciones deportivas y la publicación de datos requieren consentimientos separados, incluso si IA está encendida.
