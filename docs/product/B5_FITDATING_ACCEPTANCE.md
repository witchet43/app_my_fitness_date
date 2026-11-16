# B5 · FitDating privado y Gym Shield · entrega condicionada

**Estado:** código en rama; no E2E navegador aprobado, **NO-GO para descubrir personas**.
**Rama:** `feature/b5-private-fitdating-readiness-20261112`
**Regla de presupuesto:** B1=1, B2=1, B3=2, B4=1; B5 utiliza a lo sumo 1 job remoto como **6/10**, no repeticiones. B9 gastado, B10 reserva única. La API PROD y la página principal no se sustituyen.

## Valor de B5
- Una persona adulta autorizada prepara de forma **privada** sus preferencias: relación seria/compañía/conocer con calma, frecuencia deportiva, hasta ocho intereses permitidos y modo de protección de gimnasio. Se recuperan al volver y se pueden modificar.
- Consentimiento FitDating **separado** del consentimiento comunidad, guardado en el servidor. Puede guardarse una solicitud de participación, pero **NO** habilita descubrimiento, contacto, chat, match o visibilidad romántica.
- Desactivación inmediata desde cliente y RPC privado: solicitud=false y `dating_enabled=false` en perfil legacy; sólo el propio usuario puede hacerlo. Datos privados de gimnasios y horarios nunca entran en lista pública.
- Interfaz comprensible con checklist: estado de edad revisada, proveedor **externo aún no conectado**, consentimiento, autorización de piloto y revisión operacional. No se piden documentos de identidad en chat/correo.
- Gym Shield conserva sus reglas existentes: otros gimnasios; mismo gimnasio sólo si ambos consienten y sesiones separadas 30 min; bloqueo bilateral. Candidatos reales se obtendrían mediante RPC restringida, no comparación calculada en Flutter.
- Ante cero personas verificadas, mostrar estado vacío honesto, no inventar candidatos.

## Diseño de seguridad
- `app_private.fitdating_gate_b5` nace en **5 flags FALSE**. Ningún rol de usuario dispone de INSERT/UPDATE/DELETE. La app no puede cambiar estos flags. Habilitar requiere una migración revisada y evidencia de proveedor real, personal de moderación, evaluación privacidad, edad independiente y autorización de liberación.
- `public.discover_dating_candidates` fue **redefinido para fallar cerrado** ANTES de invocar la lógica antigua si el gate está cerrado. Cuando en futuro exista GO, también exige consentimiento, petición expresa, acceso piloto, exclusión de suspendidos/baja y bloques B4; la función privada Gym Shield ejecuta la regla de horario.
- `app_private.fitdating_preferences_b5` con RLS y **sin grants directos** a cliente; RPC owner-scoped por `auth.uid()`. No acepta IDs de usuario, DOB, gimnasio ni horarios.
- No se filtra el motivo de exclusión, identidad de otros participantes, gimnasio/horarios, metadatos de identidad ni códigos MFA.
- `dating_status` del gateway se resuelve en B5 por un **RPC autoritativo**; ya no considera `age_verified && consent` como activación automática de citas.
- El Gateway B5 usa JWT de usuario; no cuenta con service-role.
- B4 comunidad permanece **cerrada** y no se interpreta como disponibilidad de citas.

## Criterios B5
| ID | Aceptación | Evidencia |
|---|---|---|
| B5-01 | Pantalla muestra preferencias, consentimiento y estados en una sola experiencia | Widget B5 + navegador QA pendientes |
| B5-02 | Cuenta no autenticada, anónima, administrador, menor o suspendida no puede cambiar preferencias | SQL/RPC adversarial pendiente |
| B5-03 | El guardado persiste y se lee tras sesión nueva; ninguna ubicación exacta sale en respuesta | SQL/Flutter E2E pendiente |
| B5-04 | Consentimiento separado y revocable; solicitado ≠ enabled | Tests unitarios y SQL pendiente |
| B5-05 | Desactivación bloquea descubrimiento inmediatamente y es idempotente | SQL/E2E pendiente |
| B5-06 | Con los 5 flags FALSE, cualquier llamada a candidatos devuelve 0, incluso REST directo o Gym Shield | SQL/HTTP QA pendiente |
| B5-07 | Distintos gimnasios, mismo gimnasio + 30 minutos, bloqueo bilateral y cambios de horario: sin filtración | Unit Gym Shield existentes + SQL adversarial |
| B5-08 | B4 corregido: todos los widget tests pasan y acceso piloto sigue NO-GO | Flutter QA pendiente |
| B5-09 | B1–B3 sin regresión, QA móvil/desktop, login y marca global | Flutter/HTTP + navegador pendientes |
| B5-10 | Compilación única web y preview de B5 sin modificar PROD | Pipeline consolidado pendiente |

**No afirmar beta ni citas reales** hasta proveedor independiente, staff, privacidad y gates #28. El simple build verde no constituye autorización de apertura.

## Carryover B4
- La única ejecución B4 [43329300434](https://github.com/witchet43/app_my_fitness_date/actions/runs/43329300434) consumió 5/10 y falló en seis widgets por controladores de diálogos liberados durante animación.
- Corrección ya escrita al final de B4, **sin rerun**. B5 debe ejecutar todos los tests de B4 con los suyos; no se crea un job B4 adicional.
- En producción alojada se aplicaron migraciones aditivas B4, función QA B4 paralela; no hubo preview Flutter B4.
- Un error remanente B4 impide publicar B5, NO se ignora.
