# my_fitness_date

**Red social fitness con comunidades, actividades y citas opcionales.** Proyecto en desarrollo: esta versión es una demostración local, **no un servicio operativo ni apto para datos reales**.

## Primer alcance

- **Community:** publicaciones y logros de muestra.
- **Together:** actividades deportivas de muestra.
- **Dating:** descubre perfiles simulados con la opción de activar una de las dos reglas Gym Shield:
  1. **Otros gimnasios:** no recomendar personas del gimnasio habitual.
  2. **Mismo gimnasio, otro horario:** permitir personas de otros gimnasios o del mismo gimnasio si sus bloques semanales de entrenamiento no se superponen.
- **Privacidad recíproca:** los dos perfiles deben permitir una coincidencia. Se incluyen pruebas de casos límite, falta de horarios y un margen de 30 minutos.

El gimnasio y los horarios son **datos privados**: nunca deben mostrarse en el perfil público. La app de demostración únicamente manipula datos ficticios; el filtrado en cliente **NO** constituye una medida de seguridad de producción.

## Desarrollo local

Requisitos: Node.js 22+ y npm.

```bash
npm install
npm run typecheck
npm test
npm start
```

Abre el código QR con una versión de Expo Go compatible con la versión de Expo utilizada o con un simulador Android/iOS configurado. Si tu Expo Go no admite la versión del proyecto, utiliza una build de desarrollo o ajusta la versión de SDK según la guía oficial.

## Estructura

```text
App.tsx                      Demo móvil: Community / Together / Dating
src/domain/gymShield.ts      Reglas puras de elegibilidad privada
src/domain/gymShield.test.ts Pruebas automáticas
src/demo/fixtures.ts         Perfiles y eventos estrictamente ficticios
docs/MVP.md                  Alcance, criterios y siguientes hitos
.github/workflows/ci.yml     Comprobación de TypeScript y pruebas en PR
```

## Antes de cualquier beta con personas reales

Faltan autenticación, verificación de mayoría de edad, consentimiento, base de datos, ejecución **exclusivamente en servidor** del matching, reglas de acceso, bloqueo, reportes, moderación, eliminación de cuenta, política de privacidad y auditoría de seguridad. **No subir datos privados, tokens ni secretos a GitHub.**

Código sujeto a revisión por pull request. Nombre público del producto: **my_fitness_date**.
