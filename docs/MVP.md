# Especificación inicial del MVP · my_fitness_date

## Visión
Red social fitness para personas adultas que quieren comunidad, actividades deportivas y, opcionalmente, citas. Dating separado de la actividad social normal.

## Requisitos funcionales priorizados
- **MFD-01** Registro y verificación de mayoría de edad; no habilitado en esta demo.
- **MFD-02** Perfil deportivo y ciudad; inicialmente datos ficticios.
- **MFD-03** Publicaciones, grupos y eventos deportivos; inicialmente pantallas demo.
- **MFD-04** Consentimiento explícito para activar FitDating; pendiente de backend.
- **MFD-05** Gym Shield modo 1: excluir **siempre** el mismo gimnasio en citas.
- **MFD-06** Gym Shield modo 2: incluir el mismo gimnasio **solo** si ambos habilitaron este modo y sus bloques recurrentes semanales no se cruzan.
- **MFD-07** Excluir candidato bloqueado, desactivado o con horarios incompletos cuando se trate del mismo gimnasio.
- **MFD-08** Match mutuo, mensajería solo por consentimiento, denuncias y bloqueo; pendiente.
- **MFD-09** Borrado de cuenta y datos, moderación, revisión y auditoría; pendiente.

## Reglas Gym Shield
- Identidad de gimnasio basada en ID canónico, no en cadenas ingresadas libremente.
- Por defecto `other_gyms`.
- Los horarios son bloques semanales locales (día, inicio y fin) sin cruce de medianoche en esta versión.
- Modo 2 aplica un buffer configurable que comienza en 30 minutos.
- Compatibilidad **recíproca**: si al menos uno elige excluir el mismo gimnasio, la pareja no se recomienda.
- Datos faltantes o no válidos: fallar cerrado para parejas del mismo gimnasio.
- **Nunca** mostrar motivos de exclusión, horarios ni ID de gimnasio a otros usuarios.
- Cada usuario puede cambiar de modo; recalcular candidatos antes de enviarlos al cliente.
- Al abrir una conversación existente, evaluar bloqueo y consentimiento, no inferir consentimiento eterno de un matching anterior.

## Criterios de aceptación de la primera entrega (demo)
1. La app ejecuta las pantallas de comunidad, actividades y citas con datos ficticios.
2. Cambiar de modo modifica la lista local de perfiles simulados.
3. La lista nunca muestra gimnasio ni horarios ajenos.
4. Existen pruebas de elegibilidad para ambos modos, traslape, buffer, bloqueo y datos incompletos.
5. TypeScript y pruebas corren en GitHub Actions en cada pull request.

## Siguiente incremento: backend antes de beta real
- Definir esquema PostgreSQL, RLS y API de descubrimiento sin acceso a tablas de horarios desde el cliente.
- Autenticación; onboarding 18+, consentimiento y privacidad.
- Permisos de lectura y escritura por usuario y servicio.
- Ejecución de filtros en backend **antes** de devolver perfiles.
- Pruebas de seguridad de acceso horizontal (IDOR), bloqueo y revocación.
- Mensajería, denuncias, moderación, control de cuentas y eliminación.
- Revisión jurídica y de tiendas de aplicaciones en México.

## No incluido en esta entrega
Datos reales, chat real, ubicación, pagos, métricas personales de salud, automatización de entrenamientos, imágenes subidas y despliegue público.
