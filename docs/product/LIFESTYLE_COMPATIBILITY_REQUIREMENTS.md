# Matriz trazable de requisitos — Lifestyle Compatibility (FITTED → My Fitness Date)

**Estado:** `CANDIDATO / POR PRIORIZAR`. Basado en el concepto de 8 páginas **FITTED / Product Concept** (2026); ver [síntesis fiel](FITTED_EXPLORATORY_CONCEPT_2026.md).  
**Destino:** documentación **My Fitness Date / FitDating**, sin cambio de marca implícito.  
**Regla:** la inclusión en esta matriz **no equivale a aprobación ni implementación**. `M0` / `M1` / `M2` son **propuestas internas de secuenciación**, distintas de los pesos sugeridos para matching o de los P0/P1/P2 de seguridad del estándar SaaS v1.9.

## Convenciones y trazabilidad

- `F-###`: requisito funcional extraído del PDF; `N-###`: seguridad, privacidad, calidad y plataforma; `E-###`: validación/negocio.
- **Fuente:** `p.` del PDF, no resultado de un estudio. Las descripciones y ejemplos incluyen la intención del brief; **criterios de aceptación** son su **operacionalización propuesta** para discusión con producto/QA.
- Estado inicial de cada requisito: `NO_EVALUADO`. No inferir `COMPLETADO` porque haya tablas o pantallas similares en el repositorio.
- `M0`: antes de piloto de concepto; `M1`: MVP candidato, sujeto a seguridad; `M2`: fases posteriores/propuestas opcionales. La prioridad final depende de decisiones abiertas y riesgos.
- Un MVP **dating-first** del PDF y una red social deportiva **community-first con citas opt-in** de My Fitness Date son visiones **potencialmente distintas**; documentar la diferencia sin resolverla automáticamente.
- Validación: cada historia aceptada deberá enlazar **issue → PR → tests → release → evidencias**, según `ENG-02` del Estándar Maestro v1.9.

## A. Visión, audiencia e internacionalización

| ID | Requisito / intención del PDF | Fuente | Propuesta | Criterio de aceptación verificable |
| --- | --- | --- | --- | --- |
| F-001 | Compatibilidad de estilo de vida antes que mismo deporte o atractivo físico | p.1,3 | M0 | Copys y prototipos explican esta promesa sin exigir deporte común |
| F-002 | Dating de adultos con vida activa, sin elitismo fitness | p.1 | M0 | No se exigen PR, peso, rendimiento, disciplina exclusiva ni composición corporal |
| F-003 | Cuatro segmentos de comportamiento: Move for fun, Consistent, Training-focused, Competitive | p.2 | M0 | Entrevistas/prototipos cubren los cuatro segmentos, no los usan como rango de valor humano |
| F-004 | Actividades multiselección de fuerza, running, cycling, HYROX, CrossFit, boxing, yoga, pilates, barre, swimming, hiking, climbing, racket y otras | p.2 | M1 | El modelo acepta múltiples actividades y opción ampliable/otra |
| F-005 | Experiencia bilingüe español/inglés **desde el diseño** | p.2 | M1 | Onboarding, prompts, safety, notificaciones, razones de matching y soporte tienen localización revisada |
| F-006 | Adaptación cultural por país/ciudad; validación de un piloto con densidad | p.2 | M0 | Investigación define una comunidad inicial y verifica vocabulario, expectativas y privacidad locales |
| F-007 | Mensajes sin juicios moralizantes sobre hábitos e intensidad deportiva | pp.2–4 | M1 | Revisión editorial identifica y elimina lenguaje que marque «mejor/peor» por frecuencia o alcohol |

## B. Perfil — How I Move / Training DNA

| ID | Requisito | Fuente | Propuesta | Criterio de aceptación |
| --- | --- | --- | --- | --- |
| F-010 | Actividad principal y actividades secundarias | p.2 | M1 | Una persona modifica varios deportes; se distingue principal de secundarios sin ranking |
| F-011 | Frecuencia de entrenamiento semanal | p.2 | M1 | Selector de frecuencia y persistencia verificables; opción flexible |
| F-012 | Horario **preferido**: early morning, morning, midday, evening | p.2 | M1 | Campo general de preferencia, no publicación de franjas exactas de gimnasio |
| F-013 | Modo recreativo, constante, enfocado en training o competitivo | p.2 | M1 | Un solo modo actual editable; no determina atractivo o prioridad comercial |
| F-014 | Reto actual (ej. músculo, primer 10K, maratón, HYROX doubles, box, movilidad) | p.2,4 | M1 | Tarjeta opcional editable, sin tabla de posiciones |
| F-015 | Preferencia de entrenar solo, con amigos, en pareja o mixto | p.2 | M1 | Selección y explicación de perfil en lenguaje no prescriptivo |
| F-016 | Participación en competencias nunca/ocasional/regular | p.2 | M1 | Opción declarativa, con posibilidad de modificar u omitir |
| F-017 | Compatibilidad entre disciplinas diferentes | p.3 | M1 | Caso de prueba: runner puede ser candidato de gym/cycling/yoga si el resto y filtros lo permiten |

## C. Perfil — How I Live / Life Rhythm

| ID | Requisito | Fuente | Propuesta | Criterio de aceptación |
| --- | --- | --- | --- | --- |
| F-020 | Ritmo entre semana: hogar, planes ocasionales, salidas frecuentes | p.2 | M1 | Perfil permite seleccionar y modificar preferencia |
| F-021 | Ritmo de fin de semana: entrenamiento temprano, brunch, nightlife, outdoors, recovery, familia, etc. | p.2 | M1 | Múltiples preferencias; explicación sin revelar localización habitual |
| F-022 | Frecuencia social de consumo de alcohol (none/occasional/social/frequent) con neutralidad | p.3 | M1 | Campo opcional, sin inferencia médica ni ranking moral |
| F-023 | Ritmo de sueño early bird/flexible/night owl | p.3 | M1 | Campo editable; usada solo como preferencia de ritmo |
| F-024 | Enfoque alimentario (unrestricted/vegetarian/vegan/other) **solo si aporta** | p.3 | M1 | Campo opcional, no utilizado para diagnosticar salud ni excluir por cuerpo |
| F-025 | Estilo de viaje y continuidad de entrenar durante viajes | p.3 | M1 | Campo editable sin divulgación de itinerarios privados |
| F-026 | Intereses no deportivos: música, arte, escritura, gaming, cocina, mascotas, etc. | p.3 | M1 | Múltiples intereses independientes del deporte |
| F-027 | Preguntas situacionales sobre sábados, noches laborales, vacaciones y domingo libre | p.4 | M1 | Al menos prototipos de preguntas donde la respuesta se pueda editar/eliminar |

## D. Perfil — How I Relate / Relationship Rhythm

| ID | Requisito | Fuente | Propuesta | Criterio de aceptación |
| --- | --- | --- | --- | --- |
| F-030 | Intención de relación: long-term, open to serious, dating intentionally, still exploring | p.3 | M1 | La UI refleja distinciones sin sobreinterpretar, permite modificar y opt-out |
| F-031 | Preferencia de tiempo compartido vs. independencia | p.3 | M1 | Preferencia explícita; no se deduce del historial de actividad |
| F-032 | Entrenar en pareja: often/sometimes/rarely/separately is great | p.3 | M1 | Se evita exigir entrenamiento conjunto para compatibilidad |
| F-033 | Importancia de vida activa de la otra persona | p.3 | M1 | Preferencia explícita y editable; no filtro elitista forzado |
| F-034 | Vida en pareja entre semana y apoyo durante training block | p.3–4 | M1 | Prompts situacionales editables y razones de compatibilidad transparentes |
| F-035 | Tiempo personal y expectativas de relación distinguibles del deporte común | p.3 | M1 | Pruebas verifican mayor peso relativo de expectativas que de mismo deporte |

## E. Matching explicable, discovery y ubicación

| ID | Requisito | Fuente | Propuesta | Criterio de aceptación |
| --- | --- | --- | --- | --- |
| F-040 | Compatibilidad life rhythm con peso sugerido **high** | p.3 | M1 | Prototipo da mayor importancia que deporte idéntico; pesos reales requieren validación |
| F-041 | Relationship intent con peso **high** | p.3 | M1 | Incompatibilidades evidentes de intención se explican, no se ocultan bajo porcentaje |
| F-042 | Activity compatibility con peso **medium–high** | p.3 | M1 | Considera frecuencia/intensidad/competencia, no solo coincidencia textual |
| F-043 | Shared interests con peso **medium** | p.3 | M1 | Incluye hobbies no deportivos en razones comprensibles |
| F-044 | Same sport con peso **low–medium**, no obligatorio | p.3 | M1 | Prueba cruzada de disciplinas y ausencia de exclusión por diferencia deportiva |
| F-045 | Distancia como filtro práctico, **no puntuación personal** | p.3 | M1 | Radio de descubrimiento configurable sin exponer dirección ni trayectos reales |
| F-046 | Razones específicas visibles, no «87%» inexplicable | p.3 | M1 | Cada recomendación visible ofrece explicación basada en rasgos consentidos, sin revelar señales privadas de seguridad |
| F-047 | Discovery photo-first con razones antes del swipe | p.5 | M1 | Diseño combina imagen consentida con razones; no publicar fotos sin moderación/sanitización |
| F-048 | Flujo de interés y **mutual match** con control de acceso | p.5 | M1 | Ninguna conversación romántica se crea sin interés mutuo y autorización |
| F-049 | Chat después de mutual match | p.5 | M1 | Chat solo para coincidencias válidas; bloquear/reportar y controles antispam operativos |

**Conflicto a resolver:** el PDF habla de `discovery` antes del swipe y mutual matching/chat; el producto actual no los declara liberados. Una lista de candidatos protegida no equivale a dichos flujos.

## F. Gym Shield: diferenciador protegido

| ID | Requisito | Fuente | Propuesta | Criterio de aceptación |
| --- | --- | --- | --- | --- |
| F-050 | A: excluir personas del propio gimnasio | pp.3–4 | M1 | El backend excluye perfiles de mismo gym; sin revelar que fue por gym |
| F-051 | B: admitir mismo gym evitando franja horaria habitual | pp.3–4 | M1 | Validación server-side de horarios, separación y consentimiento bilateral existente |
| F-052 | C: no importar la comunidad del mismo gym | p.4 | **DECISIÓN PENDIENTE** | Analizar peligro de reidentificación y definir semántica; jamás omitir reglas actuales por simple cambio de selector |
| F-053 | Gym/horarios privados **no** visibles en perfil | p.4 | M1 seguridad | API, UI, notificaciones y razones de match nunca exponen lugar exacto ni franja recurrente |
| F-054 | No revelar ubicación exacta ni rutina antes de confianza mutua | p.4 | M1 seguridad | QA negativo contra filtración directa, metadata, inferencia y respuestas de error |
| F-055 | Regla existente: consentimiento bilateral, diferencias de 29/30 min, bloqueo y límite de intentos | base My Fitness Date | M1 seguridad | Pruebas de equivalencia y antielusión se conservan al incorporar las opciones del PDF |

## G. Experiencia, protección y sugerencias

| ID | Requisito | Fuente | Propuesta | Criterio de aceptación |
| --- | --- | --- | --- | --- |
| F-060 | Active Date después de match: walk+coffee, yoga+brunch, climbing, easy 5K, museo+walk, etc. | p.4–5 | M1/M2 | Reglas explicables con preferencias compartidas; sin obligación de entrenamiento |
| F-061 | Prompt system basado en comportamiento, no adjetivos aspiracionales | p.4 | M1 | Preguntas sobre rutina y prioridades; no pedir diagnósticos |
| F-062 | Tarjeta Current Challenge opcional, sin performance scoreboard | p.4 | M1 | Se permite omitir y cambiar; no hay rankings |
| F-063 | Verificación foto/selfie/teléfono como capas opcionales | p.4 | M2 | Revisión de privacidad y proveedores antes de habilitar; no marcar verificado automáticamente |
| F-064 | Integraciones con gimnasios/eventos solo opt-in, en fases futuras | p.4,6 | M2 | Consentimiento separado, contrato y privacidad antes de enviar datos |
| F-065 | Bloqueo y reporte fáciles, community standards y moderación | p.4–5 | M1 seguridad | Usuarios pueden bloquear y reportar en flujos relevantes; destinatario no recibe señal de la denuncia |
| F-066 | No exigir peso, body-fat %, PRs, calorie burn | p.4 | M1 seguridad | Formularios de dating carecen de esos campos obligatorios |
| F-067 | Prohibido rankear personas por performance atlético | p.4,6 | M1 seguridad | No hay score público de rendimiento ni pay-to-rank |
| F-068 | Personas adultas y consentimiento diferenciado para FitDating | base My Fitness Date | M1 seguridad | Declaración de edad **no** habilita discovery; verificación externa vigente y opt-in separados son obligatorios |
| F-069 | Sin perfiles o imágenes falsas presentadas como reales | base My Fitness Date | M1 seguridad | Datos sintéticos explícitamente etiquetados; nunca visibles como candidatos reales |

## H. Hipótesis de monetización y descarte

| ID | Requisito/hipótesis | Fuente | Propuesta | Criterio de aceptación |
| --- | --- | --- | --- | --- |
| E-001 | Freemium y premium utility **después** de conversaciones/citas útiles | pp.5–6 | M2 | Estudio de valor/precio antes de pagos; no inventar conversión |
| E-002 | Filtros avanzados, más discovery, likes, travel mode, deeper insights | pp.5–6 | M2 | Cada funcionalidad se valida separadamente y no compromete privacidad |
| E-003 | FITTED+ (nombre provisional): Gym Shield avanzado y matching eventos/viajes | p.6 | M2 | No mover bloqueo/reporte esencial a plan pago |
| E-004 | Event partnerships, venues/experiencias, gimnasios B2B2C más tarde | p.6 | M2 | Opt-in explícito, terceros verificados, contrato y datos minimizados |
| E-005 | Prohibido vender datos de ubicación/rutina, cobrar block/report, pay-to-rank, suplementos en score | p.6 | Transversal | Revisión de negocio y seguridad rechaza tales diseños |
| E-006 | IA compleja, wearables, nutrition tracking, leaderboards, gran feed como **fuera del primer MVP** | p.5 | Defer | Roadmap los mantiene fuera salvo decisión explícita y estudio de impacto |
| E-007 | Investigación naming: FITTED/SPOTTER/CADENCE/PACE/SYNC | p.7–8 | M0 | Trademark, dominio, handles, stores, pronunciación y sentido cultural antes de aprobar nombre |

## I. Descubrimiento, métricas y fases

| ID | Requisito/hipótesis | Fuente | Propuesta | Criterio de aceptación |
| --- | --- | --- | --- | --- |
| E-010 | Entrevistas a 15–20 singles activos de diferentes disciplinas | p.6 | M0 | Resultados anonimizado + consentimiento de investigación; sin respuestas inventadas |
| E-011 | Test Gym Shield: excluir gym o franja | p.6 | M0 | Entrevistas/observaciones registran comprensión y preferencia real |
| E-012 | Presentar 2–3 prototipos de perfiles y evaluar intención de match | p.6 | M0 | Prototipos etiquetados, matriz de cambios y dudas |
| E-013 | Landing/waitlist bilingüe y prototipo liviano | p.6 | M0 | Copy en ES/EN validado sin promesas falsas de miembros |
| E-014 | Evitar experiencia que juzgue capacidad atlética | p.6 | M0 | Test moderado pregunta percepción y documenta hallazgos reales |
| E-015 | Medir finalización de secciones, detalles abiertos, match→mensaje, continuación 24–72 h, valoración de contexto y adopción Gym Shield | p.6 | M1 | Diccionario y telemetría agregada aprobados, sin PII; datos = SIN_DATOS hasta instrumentar |
| E-016 | Roadmap Phase 0 validación → Phase 1 MVP → Phase 2 retención → Phase 3 comunidad → Phase 4 inteligencia | p.7 | M0 | Hitos sujetos a gates, riesgos y decisiones, no a fecha inventada |
| E-017 | Validar mercado, competencia, trademark, dominio, precios, privacidad, arquitectura antes de lanzamiento comercial | p.8 | M0 | Evidencia y responsable por frente, `NO_EVALUADO` por defecto |

## J. Requisitos no funcionales y restricciones vinculantes de integración

Estos controles provienen del **producto existente y Estándar Maestro v1.9**, no deben atribuirse al PDF como si el brief los definiera:

| ID | Restricción de plataforma o seguridad | Criterio de aceptación / evidencia |
| --- | --- | --- |
| N-001 | Flutter **Web/Android/iOS**, diseño responsivo, accesibilidad | Pruebas en 320/390/768/1440 px y móviles reales; WCAG 2.2 AA como objetivo |
| N-002 | API HTTPS versionada, gateway/BFF, dominios modulares | OpenAPI, autenticación y autorización en servidor; nunca datos de gym en interfaz |
| N-003 | Supabase/Auth/DB en nube, entornos separados y RLS | Evidencia de aislamiento por propietario, protección anti-BOLA y pruebas negativas |
| N-004 | Consentimiento trazable, privacidad por defecto y revocación | Términos/aviso y FitDating separados; retirada deshabilita dating sin borrar derechos básicos |
| N-005 | Mayoría de edad verificada fuera de declaración de perfil | Ninguna persona aparece en candidatos sin revisión independiente vigente |
| N-006 | Datos precisos de gym/horario nunca se revelan en razones de match, logs, telemetría ni capturas | Pruebas de redacción, minimización y antiinferencia |
| N-007 | Bloqueo/reporte no son de pago; moderación real para lanzamiento | Protocolo de incidente, personas responsables y evidencias |
| N-008 | Acceso, corrección, baja/exportación, retención y derechos ARCO | Flujo probado, responsables y plazos con revisión jurídica |
| N-009 | Seguridad de fotografías y chat | Sanitización/EXIF, moderación, antispam/abuso, privacidad, retención, pruebas antes de liberar |
| N-010 | Localización ES/EN como arquitectura de producto | Strings parametrizados, tono natural, pruebas de formatos y revisión bilingüe humana |
| N-011 | Métricas con minimización; aprendizaje sin inventar | No registrar dirección, horario, JWT, edad exacta, contenido sensible ni perfiles de terceros |
| N-012 | CI/CD y release gates `G0–G5` y `release/readiness.json` | No marcar `verified` sin propietario, evidencia externa y QA |
| N-013 | Free First, límites/costo por proveedor; no despliegues pagos inferidos | Registrar cuotas, monitoreo y aprobar costos antes de agregarlos |
| N-014 | Reglas de Gym Shield existentes siguen vigentes | Pruebas de consentimiento bilateral, buffer de 30 min, cuotas, bloqueos y datos no expuestos |

## K. Historias verticales de aceptación (propuestas, no entregadas)

**H1 — Perfil multidimensional bilingüe.** Dado que una persona adulta autorizada accede al onboarding, puede completar, omitir cuando proceda, editar y revisar **How I Move**, **How I Live** y **How I Relate**; no se publican datos de gimnasio/horario exactos. Cambiar idioma no borra preferencias.

**H2 — Discovery comprensible.** Dada una pareja hipotética de actividades diferentes y rutinas compatibles, el sistema devuelve explicaciones comprensibles sin un porcentaje vacío ni inferir atractivo físico. El radio de distancia solo filtra movilidad; no puntúa personas.

**H3 — Gym Shield seguro.** Dados dos adultos verificados con gimnasios y horarios privados, las opciones A/B se evalúan en servidor con controles recíprocos y separación mínima actual. Un observador no puede saber gym/horario de nadie ni motivos de exclusión. La opción C permanece en decisión sin romper política vigente.

**H4 — Mutual match + mensajería.** Dado un interés unilateral, no se habilita chat; tras un match mutuo y verificación/consentimiento vigentes, se permite el canal. Bloquear retira inmediatamente acceso e impide recontacto.

**H5 — Active Date basado en reglas.** Tras un match válido, mostrar planes low-pressure acordes a las preferencias de ambos, incluidas opciones no deportivas, sin publicar ubicación exacta ni automatizar reservas/consumos.

**H6 — Investigación falsable.** No afirmar impacto del modelo hasta entrevistar público diverso, probar 2–3 prototipos y recoger medidas de comprensión/elección, con consentimiento y datos anonimizados.

## L. Estado de la documentación y próximos vínculos

1. [Concepto de origen](FITTED_EXPLORATORY_CONCEPT_2026.md) — lectura editorial fiel de pp.1–8.
2. [Análisis de brechas y decisiones](FITTED_GAP_ANALYSIS_DECISIONS.md) — comparación con My Fitness Date y bloqueos.
3. [Discovery existente](DISCOVERY_BRIEF.md) — investigación inicial; **SIN_DATOS** no cambia.
4. [Visión previa MVP](../MVP.md), [arquitectura](../adr/0001-flutter-microservices-standard.md), [diseño](../design/ACTIVE_CHEMISTRY_AUDIT_V25.md), [gates](../../release/readiness.json).

**No sustituye decisiones de producto ni el registro de control del estándar SaaS.** Aprobaciones de alcance, arquitectura, datos, UI, gastos y release requieren su propia evidencia.
