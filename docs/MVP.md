# MVP · my_fitness_date

## Visión
Red social deportiva para adultos con tres experiencias independientes: **Community**, **Together** y **Dating**. Nadie necesita habilitar citas para usar la comunidad (integración social real pendiente).

## Estado por área

| Área | Implementado | Pendiente para beta |
| --- | --- | --- |
| Comunidad | UI y publicaciones ficticias | Perfiles, posts, moderación, bases de datos |
| Actividades | UI con eventos ficticios | Eventos, grupos, permisos y reportes |
| Auth | Registro y sesión Supabase en módulo Dating (si se configura) | Verificación sólida de edad/identidad |
| Dating | Activación voluntaria y filtros en base de datos | Preferencias románticas completas, likes, matches y chat |
| Gym Shield | Dos modos recíprocos, horarios semanales y 30 min de buffer en servidor | Antiinferencia, edición de múltiples rangos, historial de cambios |
| Seguridad | Esquema privado, sin SELECT directo, bloqueo en descubrimiento | Moderación, limitadores, auditoría, políticas/consentimientos completos |

## Reglas implementadas
- **MFD-05:** modo `other_gyms` excluye el mismo gimnasio.
- **MFD-06:** `same_gym_other_time` exige consentimiento de ambas cuentas, intervalos válidos, sin cruces en mismo día y margen de 30 min.
- **MFD-07:** bloqueo recíproco para el descubrimiento; perfiles inactivos se excluyen, horarios faltantes no se aprueban para mismo gimnasio.
- Gimnasios mediante ID canónico desde catálogo, no texto libre.
- Excepciones de privacidad, bloqueo y horario se evalúan **antes** de responder.
- La función de descubrimiento solo devuelve tarjetas permitidas, nunca nombre de gimnasio ni horario.

## En desarrollo
- **MFD-01:** autenticar con Supabase (implementado condicionalmente); verificación verdadera de edad aún pendiente.
- **MFD-04:** preferencias privadas y consentimiento Dating (backend implementado; requiere desplegar migración).
- **MFD-08:** match mutuo, chat autorizado y denuncias no implementados.
- **MFD-09:** borrado total, moderación, retención y auditoría no implementados.

## Puertas de salida antes de beta
1. Conectar un proyecto Supabase **de desarrollo** y aplicar migración. No se ha aplicado de forma remota desde esta conversación.
2. Hacer pruebas manuales end-to-end de identidad, configuración y descubrimiento.
3. Seguridad ofensiva: no inferencia por consultas repetidas, IDOR, limitadores y protección de registros.
4. Moderación, denuncia, bloqueo integral, eliminación de cuenta, aviso de privacidad y verificación de edad.
5. Reemplazar gimnasios **Demo** por catálogo real gobernado con nombres y sucursales canónicas.
6. Evaluar compliance de políticas de tiendas y legislación mexicana.

## Criterios de aceptación de este incremento
- CI: tipos, pruebas unitarias y PostgreSQL efímero en verde.
- Consulta RPC solo ejecutable por `authenticated`; datos sensibles fuera de schemas expuestos.
- Al cambiar de modo las recomendaciones se recalculan en servidor.
- No se revela el motivo de exclusión a terceros.
