# Iteración 20 — Última iteración del MVP / Preparación de despliegue

**Candidato:** \`v20-deployment-dev\`  
**Rama:** \`release/deployment-ready-v20\`  
**Base:** V19, candidata consolidada de PR #23  
**Destino autorizado para prueba:** demostración local / APK de **QA sintético**. **NO** beta real ni producción.

## Decisión de lanzamiento

Esta iteración prepara una entrega técnica controlada, **sin activar usuarios reales**. Existen 2 operaciones diferentes:

1. **QA demo (permitido tras CI):** aplicación offline con datos completamente ficticios; no inicializa Supabase, incluso aunque alguien introduzca accidentalmente una URL o clave pública en el entorno de compilación. No hay registro ni datos reales.
2. **QA hospedado / beta cerrada (aún BLOQUEADO):** exige verificación efectiva de Auth hospedado, correo, edad, moderación, privacidad, baja real, dispositivos y revisión de seguridad. Los 9 requisitos permanecen pendientes en \`release/readiness.json\`.

El resultado de \`npm run release:preflight:beta\` debe ser **error** hasta contar con evidencia independiente, autorización y estrategia de aprovisionamiento adecuada.

## Entrega técnica añadida

- \`eas.json\` define exclusivamente \`qa-demo-android\` (APK interno) y \`qa-demo-ios-simulator\` (simulador). **No** define ningún perfil de publicación en tiendas.
- \`src/domain/deploymentMode.ts\` y \`src/lib/supabase.ts\` fuerzan aislamiento real de la demo: si \`EXPO_PUBLIC_MFD_DEMO_BUILD=YES\`, no existe cliente Supabase, aunque aparezcan otras variables.
- \`scripts/release-preflight.mts\` verifica perfiles, ID DEV, estado del manifiesto, integridad básica de lockfile y variables. No llama servicios externos ni imprime llaves.
- \`android-demo-qa.yml\` compila un **APK Android debug temporal** en CI para la rama V20; exige preflight de demo, no usa secretos y conserva el artefacto durante 7 días. Este APK es instalable pero no se firma con credenciales de Play Store.
- El código React Native conserva los \`testID\` y el flujo Maestro \`maestro/demo-navigation.yaml\` para probar una instalación en Android/iOS.

## Verificación reproducible

Para auditar el proyecto y una compilación demo local, sin backend:

\`\`\`bash
npm ci
npm run typecheck
npm test
npm run candidate:audit
EXPO_PUBLIC_MFD_DEMO_BUILD=YES npm run release:preflight:demo
EXPO_PUBLIC_MFD_DEMO_BUILD=YES npx expo export --platform android
EXPO_PUBLIC_MFD_DEMO_BUILD=YES npx expo export --platform ios
\`\`\`

Instalar en Android: descargar el artefacto APK asociado a GitHub Actions **Android DEMO QA APK**, validar su SHA-256, instalarlo en un dispositivo de pruebas y ejecutar \`maestro test maestro/demo-navigation.yaml\` con Maestro configurado. No es una instalación efectuada por este informe y no confirma que la UI haya aprobado QA físico.

### Alternativa de EAS (requiere vinculación y credenciales de Expo)

Según [Expo: EAS internal distribution](https://docs.expo.dev/build/internal-distribution/), EAS puede producir APKs internos y builds para iOS Simulator. Tras iniciar sesión con el propietario del proyecto, vincular la app a EAS y revisar posibles costos:

\`\`\`bash
EXPO_PUBLIC_MFD_DEMO_BUILD=YES npm run release:preflight:demo
npx eas-cli build --platform android --profile qa-demo-android
npx eas-cli build --platform ios --profile qa-demo-ios-simulator
\`\`\`

**No asumir que la cuenta de Expo/EAS está vinculada o que el build no tiene costo.** Las URLs de distribución interna pueden compartirse; restringir acceso a enlaces internos y nunca distribuir una demo como si fuera beta con cuentas reales. El perfil iOS es **para simulador**, no IPA para un iPhone físico. Para distribución a dispositivos iOS se necesitarán credenciales Apple y provisioning.

## Despliegue hospedado real — bloqueado

El entorno existente \`my_fitness_date_dev\` contiene las 12 migraciones funcionales V1–V18; la V20 no altera su esquema. Antes de usar Auth hospedado:
1. Confirmar mediante Management API que el registro público de GoTrue está cerrado y las plantillas OTP están correctamente instaladas. El cliente que oculta el botón **no** garantiza que GoTrue bloquee el registro.
2. Comprobar que SMTP o el proveedor de correo solo envía a casillas QA controladas y que las redirecciones son correctas.
3. Designar un proceso real de verificación de edad sin guardar documentos en el código, y personas moderadoras y de respuesta a incidentes.
4. Revisar política jurídica, Storage, backups, eliminación Auth y retención de evidencias.
5. Probar en Android e iOS nativos, mantener el registro cerrado durante QA y pasar auditoría de seguridad.

## Plan de reversión

- **QA demo:** retirar el APK de distribución, revocar enlaces EAS si se hubiera creado uno, desinstalarlo de los dispositivos QA y volver a usar la rama V19 / último APK local verificado. No hay datos hospedados que revertir porque el binario es offline.
- **Si falla CI o QA:** mantener el PR V20 en borrador, reparar y repetir; **no** promover a usuarios reales.
- **Supabase DEV:** no se introducen cambios nuevos en V20, por lo que no hay migración que deshacer. Nunca aplicar automáticamente rollback de migraciones históricas con evidencias de usuarios.
- **Producción:** no existe ni se habilita en V20.

## Límites pendientes

Una demo funcional no es beta. No se han hecho pruebas nativas físicas, verificación real de edad, pruebas Auth hospedado ni pruebas irreversibles de borrado de usuarios. **La decisión formal es NO-GO para beta y GO condicionado para construir la demo offline**.
