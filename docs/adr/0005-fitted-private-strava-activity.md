# ADR-0005 — Strava y evidencia deportiva privada (fase 1)

- **Estado:** implementación de prueba en rama; **NO-GO** para publicación de conexión OAuth/IA vía Strava.
- **Fecha:** 2026-11-16.
- **Solicitud:** [#116](https://github.com/witchet43/app_my_fitness_date/issues/116).
- **Ubicación:** Fitted > Cómo me muevo > Lo que mis aplicaciones dicen de mí.

## Decisión

Se implementa un experimento **exclusivamente privado** para el propietario autenticado, con importación local voluntaria del archivo `activities.csv` exportado desde su cuenta Strava. No es una conexión automática con Strava, no existe token OAuth, no se invoca su API ni MCP, no se suben archivos o registros de entrenamiento y no se envían a Fit-IA/LLM.

El analizador determinista inspecciona únicamente identificador, fecha y tipo de actividad en los últimos 90 días. El resultado genera una frase ejecutiva ES/EN sobre frecuencia aproximada, distribución semanal y deporte predominante. No infiere salud, personalidad, compatibilidad romántica ni autenticidad. Un resumen obtenido de un CSV voluntario **no se etiqueta como verificación de Strava**.

El cliente almacena **solo el texto derivado y contadores mínimos** en preferencias locales, con clave aislada por UUID de cuenta. Ofrece borrado. Se marca con fecha de importación; no es sincronización. La persistencia local no es un almacén cifrado y debe revisarse antes de publicar en una versión con datos personales reales.

## Fundamento contractual

[Strava API Policy (vigente 1-jun-2026)](https://www.strava.com/legal/api_policy), secciones 5.3 y 5.4, restringe IA y análisis sobre datos adquiridos con su API, incluso derivados y agregados. La excepción MCP de la sección 3.5 aplica a uso personal del desarrollador y no autoriza automáticamente acceso comercial o de terceros. Por tanto, **no** se activa OAuth/API de Strava ni la generación generativa sobre esos datos. Un archivo exportado voluntariamente por el propio usuario se trata como un archivo aportado por el titular, separado de cualquier autorización de API; cualquier ampliación requiere revisión legal.

[Instrucciones de exportación personal](https://support.strava.com/es/articles/15401919-como-puedo-exportar-mis-datos-de-strava).

## Límites y privacidad

- Solo disponible detrás de validación de identidad en `MemberProfileHomeV26` y la conversación privada `Cómo me muevo`.
- Sin publicación de perfil, matching, analítica de producto, telemetría de actividades, ni usuarios externos.
- Sin rutas, coordenadas, mapas, métricas de salud o bytes CSV en base de datos.
- `SharedPreferences` local **no equivale a cifrado**; riesgo residual en dispositivos compartidos y copias de navegador.
- El resultado no demuestra autenticidad de actividades; incluye la advertencia correspondiente.

## Puertas de aceptación antes de liberar

1. Ejecutar `flutter analyze` y `flutter test test/private_activity_evidence_test.dart`.
2. Prueba manual en móvil/web con la exportación real del propietario autorizado.
3. Revisión de privacidad, almacenamiento local y solicitud de borrado.
4. Verificar que nunca se renderiza en perfiles de terceros ni se envía a Fit-IA.
5. Revisión legal de exportaciones y de las condiciones Strava aplicables.
6. Revisar `release/readiness.json` y puertas de liberación; **no** fusionar/desplegar solo por PR o CI verde.
7. Para OAuth y análisis automático comercial: autorización contractual expresa de Strava para lectura, análisis, IA y publicación de derivados; no inferir autorización a partir del consentimiento del usuario.

## Evolución propuesta

`Fitted Connect` gestionará proveedores mediante configuración de permisos por capacidad, inicialmente con Strava en estado `blocked_contract` para OAuth/IA. Para experiencias de análisis personal de Strava mediante IA, utilizar únicamente el MCP oficial en un cliente/entorno personal permitido, independiente de Fitted comercial.
