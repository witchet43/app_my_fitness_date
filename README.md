# my_fitness_date

**Red social fitness para personas adultas con comunidades, entrenamientos y citas opcionales.**

**Estado:** MVP técnico en construcción. El entorno principal aún usa datos ficticios y **no está aprobado para usuarios reales**.

## Funcionalidades

- **Fitness Community:** publicaciones deportivas de demostración.
- **Fitness Together:** eventos y grupos de demostración.
- **Fitness Dating / Gym Shield:** dos modos para recomendaciones románticas:
  1. **Solo otros gimnasios:** personas del mismo gimnasio excluidas.
  2. **Mismo gimnasio, horario distinto:** requiere que ambas personas acepten este modo, tengan horario recurrente completo y no compartan horarios, con un margen de 30 minutos.
- **Autenticación Supabase (opcional):** cuando se configura un proyecto de desarrollo, el módulo de citas pasa a usar registro, configuración privada, descubrimiento en servidor, desactivación y bloqueo.
- **Privacidad:** los horarios y gimnasio de terceros no aparecen en los resultados de descubrimiento.

## Inicio rápido

Requisitos: Node.js 22+, npm, dispositivo/simulador compatible con Expo.

```bash
npm install
npm run typecheck
npm test
npm start
```

Sin variables de Supabase, el modo de citas muestra únicamente datos simulados. **No equivale a tener cuentas o matching real.**

Para preparar una **instancia aislada de desarrollo Supabase**, consulta [docs/SUPABASE.md](docs/SUPABASE.md). Nunca conectes un entorno con personas reales sin completar la evaluación de seguridad y privacidad.

## Código relevante

```text
App.tsx                               App móvil: Community / Together / Dating
src/features/LiveDating.tsx          Registro y configuración en Supabase
src/lib/supabase.ts                  Cliente Supabase (publishable key)
src/domain/gymShield.ts              Motor local *solo para la demo*
src/domain/gymShield.test.ts         Pruebas unitarias
supabase/migrations/                 Esquema privado y RPC seguras
supabase/tests/                      Tests reales PostgreSQL (CI desechable)
docs/SUPABASE.md                     Instrucciones de despliegue manual
.github/workflows/ci.yml             TypeScript + Node tests + PostgreSQL
```

## Seguridad y límites actuales

- El filtrado local no protege la privacidad; **solo** el backend migrado utiliza reglas Gym Shield como criterio de descubrimiento.
- La validación de fecha de nacimiento es **autodeclarada**: todavía no hay verificación real de identidad y edad.
- La app no tiene chat, reportes, moderación ni prevención exhaustiva contra inferencia de horarios. **No habilitar registros abiertos a usuarios externos.**
- No guardar credenciales de privilegios elevados, llaves `service_role` ni datos personales en GitHub.

Se trabaja con ramas y pull requests en borrador. Consulta [docs/MVP.md](docs/MVP.md) para el alcance y decisiones.
