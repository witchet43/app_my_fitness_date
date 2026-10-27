# Iteración 14 — QA móvil Android/iOS

## Entregables reales

- Navegación por pestañas definida y probada en `src/domain/mobileNavigation.ts`.
- Estado no autenticado: demo pública. Estado de Auth pendiente: sin secciones privadas. Cuenta con solicitud de baja: exclusivamente Cuenta. Moderación visible solo con permiso.
- Pantalla principal contenida en `KeyboardAvoidingView` para iOS; scroll principal con cierre del teclado al arrastrar y soporte para tocar botones mientras se muestra el teclado.
- Controles accesibles con etiquetas, estados de selección y objetivos táctiles de 44 puntos en navegación, salida y reintento.
- Identificadores `testID` para navegación, acceso y formularios principales que permiten automatizar recorridos con Maestro.
- CI genera bundles JavaScript de Android **e iOS** y ejecuta pruebas unitarias de las reglas de navegación.
- Identificadores de aplicación para builds **solo de desarrollo**: `com.myfitnessdate.dev`.

## Prueba de navegación con Maestro (sin cuenta ni claves reales)

Archivo: `maestro/demo-navigation.yaml`. Está diseñada para un build nativo instalado, compilado sin `EXPO_PUBLIC_SUPABASE_URL`, de modo que muestre **solo contenido de demostración sintético**.

Desde Android Studio/Xcode o un entorno que tenga el SDK, construir y abrir el proyecto. Ejemplos:

```sh
npm install
npx expo prebuild --platform android
npx expo run:android
maestro test maestro/demo-navigation.yaml
```

En iOS, desde un equipo macOS con Xcode y simulador:

```sh
npx expo prebuild --platform ios
npx expo run:ios
maestro test maestro/demo-navigation.yaml
```

La prueba recorre Comunidad → Actividades → Citas → Comunidad, comprueba textos y navegación, **pero no verifica el diseño visual ni un flujo de Auth real**. La nueva CI solo exporta bundles JS; no instala una app ni ejecuta Maestro automáticamente. Registrar como `pendiente` toda ejecución no observada.

## Matriz de QA física pendiente

| Caso | Android físico | iPhone físico | Criterio |
|---|---|---|---|
| Navegación seis pestañas | Pendiente | Pendiente | Se desplazan horizontalmente y cada sección abre |
| Teclado y formulario de registro | Pendiente | Pendiente | Teclado no oculta botón y scroll funciona |
| Cuenta QA A → cerrar → B | Pendiente | Pendiente | Sin campos, horarios o publicaciones privadas residuales |
| Login sin red | Pendiente | Pendiente | Acceso privado denegado, reintento visible |
| Baja pendiente | Pendiente | Pendiente | Solo Cuenta, no reactivación automática de Dating |
| Confirmar correo y recuperar contraseña | Pendiente | Pendiente | OTP, rechazo de reuso, login posterior |
| Gym Shield con consentimientos QA | Pendiente | Pendiente | Mismo gym 29/30 minutos, gimnasio diferente |
| Lector de pantalla / zoom | Pendiente | Pendiente | Etiquetas informativas, controles visibles y accionables |

## Preparación y seguridad

Usar exclusivamente cuentas QA controladas, URL DEV y clave `EXPO_PUBLIC_SUPABASE_PUBLISHABLE_KEY` en un archivo local no versionado. Nunca publicar `service_role`/tokens, códigos OTP, ubicación del gimnasio, DOB o horarios reales. **No** habilitar cuentas públicas hasta verificación de edad e identidad, moderación operativa y análisis de seguridad.

## Interpretación de CI

`npx expo export --platform ios` y Android comprueban que Metro puede generar bundles para ambas plataformas. **NO** prueban la compilación nativa, la firma, la instalación ni el funcionamiento en teléfonos físicos. No afirmar que la matriz física esté aprobada sin evidencias.
