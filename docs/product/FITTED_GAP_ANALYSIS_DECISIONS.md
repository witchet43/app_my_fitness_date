# FITTED vs. My Fitness Date — análisis de brechas y decisiones abiertas

**Estado:** `PROPUESTA PARA REVISIÓN`; no PRD aprobado ni decisión de rebranding.  
**Origen:** PDF `FITTED_Concepto_Exploratorio_Spanglish.pdf` (8 pp., 2026), incorporado documentalmente en [concepto](FITTED_EXPLORATORY_CONCEPT_2026.md) y [matriz](LIFESTYLE_COMPATIBILITY_REQUIREMENTS.md).  
**Marco:** SaaS Factory v1.9, `AGENTS.md`, `docs/product/DISCOVERY_BRIEF.md`, `docs/MVP.md`, `docs/adr/0001-flutter-microservices-standard.md`, `release/readiness.json`.  
**Fuente de verdad de implementación:** inspeccionar código y producción en cada sprint; las notas históricas V19/V25 pueden estar desactualizadas. **Nunca** identificar existencia de una tabla/UI con funcionalidad desplegada y auditada.

## 1. Reconciliación de visión: una decisión, no un supuesto

| Aspecto | Concepto FITTED (PDF) | My Fitness Date existente | Impacto |
| --- | --- | --- | --- |
| Propuesta de valor | **Dating-first**, compatibilidad profunda de lifestyle activo | **Comunidad deportiva** con actividades y **FitDating opcional** | Elegir arquitectura de producto (core vs. vertical opcional) |
| Marca | FITTED — «Match your rhythm» provisional, alternativas de naming | Marca/logo **My Fitness Date**, FitDating y narrativa «Encuentra tu ritmo. Conecta de verdad.» | No cambiar dominio, imagen, legal, OAuth, repositorio ni tiendas automáticamente |
| Público | Personas solteras con vida activa en segmentos de comportamiento | Personas adultas que buscan comunidad y opcionalmente citas | Validar segmentos, permisos y elección sin forzar dating |
| Perfil | Tres capas How I Move / Live / Relate | Perfil personal/deportivo con deportes, intereses, prompts, ciudad, intención, visibilidad | Nuevas preferencias, formularios, diccionario, controles y migraciones tras decisión |
| Discovery | Foto primero, razones explicables y swipe | Candidatos protegidos por controles de elegibilidad; no hay evidencia de swipe, match y chat público | Requiere nuevo flujo de matching y trust/safety |
| Gym Shield | A excluir gym, B excluir franja, C no importar coincidencias en gym | Reglas estrictas con consentimiento bilateral, buffer 30 min, privacidad, bloqueo, límites de consulta | C **NO** se habilita sin threat model y producto aprobado |
| Active Date | Después de matching mutuo: experiencias sencillas sugeridas por reglas | No afirmado como funcionalidad productiva | Requiere matching, prevención de exposición de ubicaciones y UX |
| Community | Fase 3, no gran social feed en MVP | Community/actividades son parte de visión original | Riesgo real de sustituir core; solo por decisión expresa |
| Monetización | Freemium/premium utility **tras validar valor** | No hay hipótesis de precio validada para FITTED | Seguridad, bloqueo y match significativo nunca paywall |
| Inteligencia | Recomendaciones complejas y wearables **posteriores** | Arquitectura orientada a servicios y estándar IA transversal | No confundir "AI-ready" con requisito de IA en MVP |
| Idiomas | ES/EN desde onboarding, explicación y soporte | Interfaz actual mayormente en español; sin QA bilingüe acreditado | Requiere diseño i18n y localización, no string literals traducidos a posteriori |
| Mercado | Latino, piloto en una ciudad/comunidad | Sin evidencia de estudio de mercado o densidad | Discovery G0 y consentimiento de investigación antes de adquirir usuarios |

## 2. Gap técnico por flujo: evidencia existente vs. nueva intención

| Código / base a revisar | Capacidad reconocible | Brecha antes del nuevo MVP | Evidencia de aceptación requerida |
| --- | --- | --- | --- |
| `apps/flutter_client/lib/src/features/member_profile_v26.dart` | Perfil/edición personal y deportivo, intereses y prompts | Three-layer onboarding, Life Rhythm, Relationship Rhythm y localización bilingüe | E2E perfil completo editable y permisos por dueño |
| `apps/flutter_client/lib/src/features/public_entry_shell.dart` | Landing/login y registro | Mensaje de valor FITTED vs. comunidad sin rebrand, test bilingüe | QA con copy permitido y flujos válidos |
| `services/api_gateway/app/profile_v26.py`, `supabase/functions/member-api-v26` | API de datos personales y perfil | Contratos para nuevas preferencias y explicaciones seguras | OpenAPI/contratos, RLS y anti-BOLA, no PII en logs |
| `services/gym_shield`, SQL `discover_dating_candidates` | Reglas del dominio y filtros Gym Shield, elegibilidad adulta | Modo C, razones de compatibilidad no inferenciales, comprobación de cuotas | Casos A/B/C y pruebas de no divulgación, 29/30 min |
| `docs/MVP.md`, `README.md` | Describen capacidades anteriores de comunidad, Gym Shield y limitaciones | No se debe tratar discovery como **swipe/match/chat** existente | Prototipo, consentimientos, antiabuso, UX accesible |
| `release/readiness.json` | Gates de beta que permanecen pendientes | Investigación y condiciones operativas necesarias | Evidencias firmadas por responsables; NO-GO hasta cumplir |
| `docs/legal/*` y Cloudflare `/privacy/`, `/terms/` | Documentos legales/HTML web existentes | Finalidades, transferencias, edad, retención y consentimiento para nuevos campos | Revisión legal expresa previa a cambio de tratamiento |
| `docs/design/ACTIVE_CHEMISTRY_AUDIT_V25.md` | Tokens, UX y positioning My Fitness Date | Sistema visual bilingüe, jerarquía nueva de ritmo y explicación | Auditoría accesibilidad/entendimiento humano |

### Cobertura de los módulos numerados del MVP PDF

| # del PDF | Estado de interpretación respecto al producto actual |
| --- | --- |
| **1 Onboarding** | Auth existe, pero onboarding lifestyle/intención/radio propuesto no está acreditado end-to-end |
| **2 Training DNA** | Campos base de deportes/frecuencia presentes; modo competitivo/horario preferido/reto actual deben validarse |
| **3 Life Rhythm** | Sueño, semana/finde, alcohol, comida, viajes: **requerimientos nuevos** a decidir |
| **4 Relationship Rhythm** | Intención básica existe; tiempo juntos, entrenar con pareja, apoyo en training block requieren diseño |
| **5 Discovery** | Servicio protegido de candidatos no es descubrimiento photo-first con explicación y swipe |
| **6 Gym Shield** | A/B se apoyan en reglas actuales; C requiere revisión de seguridad |
| **7 Mutual match + chat** | No declarar implementado; necesita relaciones mutuas, bloqueo, retención y moderación |
| **8 Active Date** | No declarar implementado; depende de match y preferencias legítimas |

## 3. Decisiones que debe cerrar producto (sin decisiones implícitas)

| ID | Pregunta a resolver | Opciones / criterios | Estado |
| --- | --- | --- | --- |
| D-01 | ¿FITTED sustituye el nombre My Fitness Date? | Mantener marca / co-branding / estudiar rebranding, previa marca/dominio/tiendas/legal | **ABIERTA**; se mantiene My Fitness Date |
| D-02 | ¿Dating-first o comunidad con citas opcionales? | Enfoque único, vertical opt-in o apps separadas; comparar JTBD y riesgo | **ABIERTA**; conservar comportamiento existente |
| D-03 | ¿MVP según las ocho piezas del PDF o experimento previo? | Producto completo vs. prototipo sin PII; estimar seguridad/costo | **ABIERTA**; discovery recomendado |
| D-04 | ¿Qué significan los pesos de matching? | Investigar variables, explicaciones, incompatibilidades y QA/fairness; sin % ficticio | **ABIERTA** |
| D-05 | ¿Cómo habilitar Gym Shield C sin fugas? | Consentimiento bilateral, antiinferencia, reversibilidad; posible descarte | **ABIERTA**; C deshabilitada |
| D-06 | ¿Qué información del perfil se publica y ante quién? | Modelo de visibilidad por dato, propósito, consentimiento y no inferencia | **ABIERTA**; privado por defecto |
| D-07 | ¿Uso de fotografía y verificación? | Moderación, EXIF, menores, revisión de imágenes, no discriminación | **ABIERTA**; no activar por brief |
| D-08 | ¿Qué relación hay entre mutual match, chat y community? | Árbol de permisos y bloqueo, reporte, retención, abuso, invitación | **ABIERTA** |
| D-09 | ¿Cómo localizar ES/EN en un primer mercado latino? | País/cultura, idioma preferido y locales, legal/copy, accesibilidad | **ABIERTA**; no traducir literal |
| D-10 | ¿Cuál es el alcance comercial? | Valor real, prototipo, precio y percepción de pago; safety nunca de pago | **ABIERTA** |
| D-11 | ¿Con qué reglas usar distancia sin geolocalización exacta? | Radio práctico, ciudad aprox., privacidad de proximidad, anti-stalking | **ABIERTA** |
| D-12 | ¿Cómo diferenciar current challenge de performance pública? | Voluntario, sin ranking/PR obligatorio, sin inferencias de salud | **ABIERTA** |
| D-13 | ¿Qué valida el primer valor de FITTED? | Perfil explicado, primer match, primer mensaje, conversación real; sin confundir con login | **ABIERTA**; medir tras consentimiento |
| D-14 | ¿Cómo decidir la fase posterior de IA/integraciones? | Solo con métricas reales, utilidad, gobernanza IA, costo y privacidad | **ABIERTA** |

**Regla de cambio:** no modificar estas filas a `APROBADA` sin decisor, fecha, argumentos, riesgos, impactos, issue/ADR y evidencia. Ninguna frase del PDF por sí misma puede activar un pago, prueba pública, tracking, entrenamiento de IA con datos personales ni despliegue.

## 4. Propuesta de épicas de backlog (ordenada por dependencias, no compromiso de entrega)

| Épica | Trazabilidad a matriz | Dependencia | Entregable falsable |
| --- | --- | --- | --- |
| EP-00 Validación de insight y marca | F-001..007, E-007, E-010..017 | Ninguna | 15–20 entrevistas, 2–3 prototipos, hipótesis refutada o respaldada |
| EP-01 Consentimiento/identidad segura | N-003..009 | Gates legales/edad/soporte | E2E de edad, consentimiento, revocación y baja |
| EP-02 Perfil tres capas ES/EN | F-010..035, N-010 | EP-00, minimización de datos | Onboarding editable, completo y sin exposición del gym |
| EP-03 Compatibility rules & reasons | F-040..046, N-006, N-011 | EP-02, EP-01 | Explicación útil, sin ranking corporal y sin fuga privada |
| EP-04 Gym Shield A/B y estudio C | F-050..055 | EP-01, threat modeling | Paridad + pruebas negativas + decisión registrada C |
| EP-05 Discovery y foto segura | F-047, F-065..069 | EP-01, EP-03, moderación | Discovery accesible solo a elegibles con fotos autorizadas |
| EP-06 Mutual like / match / chat | F-048..049, F-065 | EP-05, moderación/soporte | Ningún chat sin reciprocidad, bloqueo inmediato |
| EP-07 Active Date rule-based | F-060 | EP-06 | Sugerencia simple tras match, sin localización privada |
| EP-08 Economía y alianzas opt-in | E-001..006 | Evidence of engagement, análisis legal | Experimento de pricing sin paywall de safety |
| EP-09 Investigación y métricas | E-010..017, N-011..014 | Instrumentación aprobada | Dashboard sin PII y métricas `SIN_DATOS` hasta medición real |

## 5. Modelo de datos candidato (diseño, no DDL aprobado)

**Objetivo:** representar los tres ritmos con privacidad estricta y sin añadir campos innecesarios. Antes de migrar, acordar finalidades, retención, nombres en API, cardinalidades, borrado y controles RLS.

- `member_training_preferences`: actividad principal/secundarias, frecuencia, franja general preferida, modo, reto actual, compañía al entrenar, frecuencia de competencias. **Diferente de** horarios semanales privados de Gym Shield.
- `member_life_rhythm`: semana/finde, sleep, alcohol opcional, food opcional, viajes y hobbies; solo datos pertinentes.
- `member_relationship_preferences`: intención, tiempo compartido/independiente, entrenar juntos, importancia de vida activa, prompts de apoyo.
- `member_discovery_settings`: visibilidad, radio aproximado, preferencias Gym Shield y opt-in separados de disponibilidad del perfil deportivo.
- `matching_reason_codes` / evaluación server-side: razones visibles preaprobadas, explicabilidad, tests de no inferencia, sin porcentajes arbitrarios.
- `dating_interests`, `mutual_matches`, `conversations` y `message_reports`: **solo después** de D-08 y protocolo de moderación; no crear tablas sin threat model, retención y QA.
- `activity_date_suggestions`: reglas sin IA, basadas en intereses consentidos; no inferir ubicación exacta.
- Todos los diseños deben evaluar usuarios menores, impersonación, stalking, múltiples cuentas, incidentes de seguridad, retención y ejercicio ARCO.

**No guardar** datos inferidos sensibles, peso, body-fat, rutas precisas, entrenamientos horarios públicamente accesibles o perfiles de terceros en analytics. En entorno de pruebas, utilizar cuentas etiquetadas como sintéticas, no candidatos románticos reales.

## 6. Hipótesis de experimentación y definición de aprendizaje

| ID | Hipótesis falsable | Método propuesto | Estado |
| --- | --- | --- | --- |
| H-FIT-01 | El lifestyle permite decidir un match mejor que deportes coincidentes | 2–3 perfiles contrastados, entrevista exploratoria | SIN_DATOS |
| H-FIT-02 | Gym Shield incrementa percepción de seguridad sin confusión | Variantes A/B y propuesta C mostradas con escenarios | SIN_DATOS |
| H-FIT-03 | Personas con deportes diferentes valoran explicaciones de ritmo | Prototipos de recomendaciones cruzadas | SIN_DATOS |
| H-FIT-04 | Prompts situacionales revelan más que descriptores genéricos | Comparación sin manipulación de datos reales | SIN_DATOS |
| H-FIT-05 | Un piloto concentrado genera conversaciones con continuidad | Plan de piloto antes de habilitar usuarios | SIN_DATOS |
| H-FIT-06 | La experiencia ES/EN es natural para público local | Revisión por hablantes y tareas de comprensión | SIN_DATOS |

**Métricas del PDF:** finalización de perfil por capas, apertura de razones de compatibilidad, match→primer mensaje, continuidad 24–72 h, percepción de utilidad y adopción de Gym Shield; pago solo tras *healthy engagement*. Definir privacidad y bases legales antes de instrumentar. No recopilar mensajes para análisis sin propósito legítimo/consentimiento.

## 7. Fases, riesgo y puertas de liberación

1. **Phase 0 (descubrimiento):** entrevistas, prototypes, bilingual, naming/trademark, segmentos, modelo de primer valor; es la fase **propuesta** para tomar decisiones D-01..14.
2. **Phase 1 (MVP):** tres ritmos, discovery explicable, Gym Shield, match/chat **solo tras** G0–G5 y edad/moderación/privacidad.
3. **Phase 2 (retención):** Active Date, explanations y filtros después de observar uso.
4. **Phase 3 (comunidad):** eventos singles, race weekends y alianzas opt-in; si se conserva el community-first vigente, la secuencia debe aprobarse explícitamente.
5. **Phase 4 (inteligencia):** solo con resultados y trust, no como prerrequisito del MVP.

**Puertas inmutables:** `release/readiness.json` sigue registrando controles no acreditados; no declararlos completados. Calidad de código, CI, existencia de un OAuth funcional o una API desplegada **no** equivale a validación de negocio, edad humana, moderación, revisión legal ni beta comercial. Conservar medidas de prevención de acoso, reidentificación, fraude y exposición de rutinas.

## 8. Registro de fuentes/propietarios y seguimiento

| Documento | Función | ¿Reemplazado? |
| --- | --- | --- |
| PDF FITTED (8 pp., 2026) | Fuente del concepto exploratorio de producto y marca | **No** |
| `FITTED_EXPLORATORY_CONCEPT_2026.md` | Lectura fiel, síntesis y referencias de páginas | Nuevo |
| `LIFESTYLE_COMPATIBILITY_REQUIREMENTS.md` | Matriz con criterios propuestos y controles existentes | Nuevo |
| Este documento | Brechas, riesgos, decisiones, épicas, experimentos | Nuevo |
| `DISCOVERY_BRIEF.md` | Hipótesis anteriores de comunidad/actividades | **No** |
| `docs/MVP.md` | Estado técnico histórico (revisar versión) | **No** |
| `docs/design/ACTIVE_CHEMISTRY_AUDIT_V25.md` | Diseño/My Fitness Date vigente o histórico | **No** |
| `docs/adr/0001-flutter-microservices-standard.md` | Arquitectura multiplataforma | **No** |
| SaaS Factory v1.9 | Marco de ingeniería aprobado y 219 controles | **No** |

**Responsable de decisiones:** por designar/confirmar. **Evidencia de investigación:** SIN_DATOS. **Estado general:** exploración documentada, **sin features desplegadas por este cambio**.
