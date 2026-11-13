# B10 — Auditoría integral FITTED (documento exploratorio, 8 páginas)

**Fecha:** 2026-11-12 (México). **Issue:** #74. **Rama:** `feature/b10-fitted-concept-audit-20261112`.
**Fuente:** `FITTED_Concepto_Exploratorio_Spanglish.pdf` (PDF adjunto por el propietario), sintetizado sin elevar hipótesis a PRD aprobado en `FITTED_EXPLORATORY_CONCEPT_2026.md`.
**Matriz derivada de requisitos:** `docs/product/LIFESTYLE_COMPATIBILITY_REQUIREMENTS.md`, **84 identificadores F/N/E**. Los requisitos N extienden la fuente con estándares del producto, no son citas literales del PDF.

## Veredicto global

**NO CUMPLE COMPLETAMENTE EL MVP DEL PDF. NO-GO beta/comercial.**

FITTED es un **working brand concept**, no nombre aprobado. My Fitness Date (comunidad deportiva + FitDating opt-in) y FITTED (dating-first) requieren la decisión D-02; no sustituir silenciosamente marca ni identidad. La mera documentación o un prototipo no es prueba de valor ni de seguridad real.

- **BLOQUEADO_NO_ACTIVAR: 6** requisitos
- **INVESTIGACION_PENDIENTE: 11** requisitos
- **NO_IMPLEMENTADO: 1** requisitos
- **PARCIAL_EXISTENTE: 21** requisitos
- **POSPUESTO_O_NO_INICIADO: 7** requisitos
- **PROTOTIPO_LOCAL: 38** requisitos

**Interpretación de estados:** `PROTOTIPO_LOCAL` significa UI/algoritmo de demostración sin persistencia, perfiles ni QA en producción; `PARCIAL_EXISTENTE` indica controles implementados en código cuya validación integral falta; `BLOQUEADO_NO_ACTIVAR` necesita gates externos; `INVESTIGACION_PENDIENTE` exige evidencia humana; `POSPUESTO_O_NO_INICIADO` incluye futuras fases; `NO_IMPLEMENTADO` significa sin evidencia de flujo funcional.

## Cobertura de los 8 módulos de MVP del PDF p.5

| Módulo | Estado de B10 | Requisitos | Resultado pendiente |
| --- | --- | --- | --- |
| 1. Onboarding | PARCIAL; identidad existente + estudio B10 sin guardado | F-005, F-030, N-004 | Onboarding persistente, completo, bilingüe y radios de distancia con privacidad |
| 2. Training DNA | DEMO LOCAL B10; algunos datos deportivos B5 persistidos | F-010..F-017 | Guardado seguro + edición + QA mobile/es/en |
| 3. Life Rhythm | DEMO LOCAL B10 | F-020..F-027 | Modelo consentido, validación legal, persistencia privada |
| 4. Relationship Rhythm | DEMO LOCAL B10; intención básica B5 | F-030..F-035 | Modelo consentido, API y pruebas multiusuario |
| 5. Discovery photo-first y razones | RAZONES HIPOTÉTICAS; **discovery real bloqueado** | F-040..F-049 | Moderación/foto, consentimiento, edad externa, antiacoso, explicación por perfiles consentidos |
| 6. Gym Shield | A/B parcialmente funcional y CI; C deliberadamente bloqueado | F-050..F-055 | Pruebas E2E antiinferencia, decisión sobre C; no revelar gimnasio/ventana exacta |
| 7. Mutual match + chat | NO IMPLEMENTADO EN FLUJO VIGENTE | F-048..F-049, N-009 | Seguridad, chat solo bilateral, bloqueo/reporte, retención, moderación 24/7 o política aprobada |
| 8. Active Date | SOLO EJEMPLOS RULE-BASED B10 | F-060 | Activar exclusivamente después del match real, moderación/consentimiento, sin localizaciones privadas |

## Riesgos P0 que impiden release

1. Edad verificada por proveedor **independiente** no acreditada (N-005).
2. Moderación humana y protocolos de incidentes sin evidencia operativa (N-007).
3. Revisión legal, privacidad, retención, eliminación, exportación/ARCO y fotografía/chat pendientes (N-008/009).
4. Flutter Android/iOS en dispositivos físicos, accesibilidad WCAG, E2E de dos cuentas y BOLA/IDOR no acreditados (N-001/003).
5. CI MVP B8 detectó drift de secuencia de migraciones; Auth local E2E no recibió OTP en Mailpit; no declarar verdes los flujos incompletos.
6. Experimento cualitativo 15–20 personas, 2–3 prototipos, naming, trademark, países/culturas y métricas sin investigación real (E-007, E-010..017).
7. B10 no cuenta con una nueva compilación remota porque el límite acordado de **10/10** ejecuciones ya fue consumido por el cierre de B9.
8. Las decisiones D-01..14 permanecen abiertas. El usuario solicita implementar el último build, no ha aprobado sustituir marca/dominio, abrir datos románticos, lanzar a tiendas, ni pagar proveedores.

## Alcance funcional final B10 (sin promesas infladas)

- Tres capas de perfil ES/EN como **estudio interactivo temporal** dentro de FitDating. Sin red ni almacenamiento; descarta información al salir.
- Campos por conducta de entrenamiento, ritmo de vida e intención; opciones multiselección; reto actual/prompts situacionales.
- Reglas deterministas de compatibilidad sobre escenarios **ficticios etiquetados**; alto peso explicativo a vida e intención, medio a actividad, bajo a mismo deporte. **Sin puntuación arbitraria ni atributos corporales.**
- Gym Shield A/B visibles como concepto, C **bloqueado**; no se exponen gym ni franjas concretas en explicaciones.
- Active Date solo en escenarios hipotéticos con aviso de uso real únicamente después de match mutuo.
- Mensajería, swipe, perfiles externos, pagos, verificación de edad y discovery **no se activan**.

## Matriz individual: fuente → evidencia → brecha

| ID | Concepto o requisito | PDF / origen | Estado auditado | Evidencia consultable | Trabajo o verificación pendiente |
| --- | --- | --- | --- | --- | --- |
| F-001 | Compatibilidad de estilo de vida antes que mismo deporte o atractivo físico | p.1,3 | **PROTOTIPO_LOCAL** | B10 Flutter rhythm_concept_b10.dart + rhythm_concept_lab_b10.dart | Sin persistencia ni perfiles reales; requiere QA Flutter y validación de producto. |
| F-002 | Dating de adultos con vida activa, sin elitismo fitness | p.1 | **PROTOTIPO_LOCAL** | B10 Flutter rhythm_concept_b10.dart + rhythm_concept_lab_b10.dart | Sin persistencia ni perfiles reales; requiere QA Flutter y validación de producto. |
| F-003 | Cuatro segmentos de comportamiento: Move for fun, Consistent, Training-focused, Competitive | p.2 | **PROTOTIPO_LOCAL** | B10 Flutter rhythm_concept_b10.dart + rhythm_concept_lab_b10.dart | Sin persistencia ni perfiles reales; requiere QA Flutter y validación de producto. |
| F-004 | Actividades multiselección de fuerza, running, cycling, HYROX, CrossFit, boxing, yoga, pilates, barre, swimming, hiking, climbing, racket y otras | p.2 | **PROTOTIPO_LOCAL** | B10 Flutter rhythm_concept_b10.dart + rhythm_concept_lab_b10.dart | Sin persistencia ni perfiles reales; requiere QA Flutter y validación de producto. |
| F-005 | Experiencia bilingüe español/inglés **desde el diseño** | p.2 | **PROTOTIPO_LOCAL** | B10 Flutter rhythm_concept_b10.dart + rhythm_concept_lab_b10.dart | Sin persistencia ni perfiles reales; requiere QA Flutter y validación de producto. |
| F-006 | Adaptación cultural por país/ciudad; validación de un piloto con densidad | p.2 | **INVESTIGACION_PENDIENTE** | docs/product/FITTED_GAP_ANALYSIS_DECISIONS.md — hipótesis SIN_DATOS | Entrevistas, métricas sin PII, revisión humana, legal/naming y piloto. |
| F-007 | Mensajes sin juicios moralizantes sobre hábitos e intensidad deportiva | pp.2–4 | **PROTOTIPO_LOCAL** | B10 Flutter rhythm_concept_b10.dart + rhythm_concept_lab_b10.dart | Sin persistencia ni perfiles reales; requiere QA Flutter y validación de producto. |
| F-010 | Actividad principal y actividades secundarias | p.2 | **PROTOTIPO_LOCAL** | B10 Flutter rhythm_concept_b10.dart + rhythm_concept_lab_b10.dart | Sin persistencia ni perfiles reales; requiere QA Flutter y validación de producto. |
| F-011 | Frecuencia de entrenamiento semanal | p.2 | **PROTOTIPO_LOCAL** | B10 Flutter rhythm_concept_b10.dart + rhythm_concept_lab_b10.dart | Sin persistencia ni perfiles reales; requiere QA Flutter y validación de producto. |
| F-012 | Horario **preferido**: early morning, morning, midday, evening | p.2 | **PROTOTIPO_LOCAL** | B10 Flutter rhythm_concept_b10.dart + rhythm_concept_lab_b10.dart | Sin persistencia ni perfiles reales; requiere QA Flutter y validación de producto. |
| F-013 | Modo recreativo, constante, enfocado en training o competitivo | p.2 | **PROTOTIPO_LOCAL** | B10 Flutter rhythm_concept_b10.dart + rhythm_concept_lab_b10.dart | Sin persistencia ni perfiles reales; requiere QA Flutter y validación de producto. |
| F-014 | Reto actual (ej. músculo, primer 10K, maratón, HYROX doubles, box, movilidad) | p.2,4 | **PROTOTIPO_LOCAL** | B10 Flutter rhythm_concept_b10.dart + rhythm_concept_lab_b10.dart | Sin persistencia ni perfiles reales; requiere QA Flutter y validación de producto. |
| F-015 | Preferencia de entrenar solo, con amigos, en pareja o mixto | p.2 | **PROTOTIPO_LOCAL** | B10 Flutter rhythm_concept_b10.dart + rhythm_concept_lab_b10.dart | Sin persistencia ni perfiles reales; requiere QA Flutter y validación de producto. |
| F-016 | Participación en competencias nunca/ocasional/regular | p.2 | **PROTOTIPO_LOCAL** | B10 Flutter rhythm_concept_b10.dart + rhythm_concept_lab_b10.dart | Sin persistencia ni perfiles reales; requiere QA Flutter y validación de producto. |
| F-017 | Compatibilidad entre disciplinas diferentes | p.3 | **PROTOTIPO_LOCAL** | B10 Flutter rhythm_concept_b10.dart + rhythm_concept_lab_b10.dart | Sin persistencia ni perfiles reales; requiere QA Flutter y validación de producto. |
| F-020 | Ritmo entre semana: hogar, planes ocasionales, salidas frecuentes | p.2 | **PROTOTIPO_LOCAL** | B10 Flutter rhythm_concept_b10.dart + rhythm_concept_lab_b10.dart | Sin persistencia ni perfiles reales; requiere QA Flutter y validación de producto. |
| F-021 | Ritmo de fin de semana: entrenamiento temprano, brunch, nightlife, outdoors, recovery, familia, etc. | p.2 | **PROTOTIPO_LOCAL** | B10 Flutter rhythm_concept_b10.dart + rhythm_concept_lab_b10.dart | Sin persistencia ni perfiles reales; requiere QA Flutter y validación de producto. |
| F-022 | Frecuencia social de consumo de alcohol (none/occasional/social/frequent) con neutralidad | p.3 | **PROTOTIPO_LOCAL** | B10 Flutter rhythm_concept_b10.dart + rhythm_concept_lab_b10.dart | Sin persistencia ni perfiles reales; requiere QA Flutter y validación de producto. |
| F-023 | Ritmo de sueño early bird/flexible/night owl | p.3 | **PROTOTIPO_LOCAL** | B10 Flutter rhythm_concept_b10.dart + rhythm_concept_lab_b10.dart | Sin persistencia ni perfiles reales; requiere QA Flutter y validación de producto. |
| F-024 | Enfoque alimentario (unrestricted/vegetarian/vegan/other) **solo si aporta** | p.3 | **PROTOTIPO_LOCAL** | B10 Flutter rhythm_concept_b10.dart + rhythm_concept_lab_b10.dart | Sin persistencia ni perfiles reales; requiere QA Flutter y validación de producto. |
| F-025 | Estilo de viaje y continuidad de entrenar durante viajes | p.3 | **PROTOTIPO_LOCAL** | B10 Flutter rhythm_concept_b10.dart + rhythm_concept_lab_b10.dart | Sin persistencia ni perfiles reales; requiere QA Flutter y validación de producto. |
| F-026 | Intereses no deportivos: música, arte, escritura, gaming, cocina, mascotas, etc. | p.3 | **PROTOTIPO_LOCAL** | B10 Flutter rhythm_concept_b10.dart + rhythm_concept_lab_b10.dart | Sin persistencia ni perfiles reales; requiere QA Flutter y validación de producto. |
| F-027 | Preguntas situacionales sobre sábados, noches laborales, vacaciones y domingo libre | p.4 | **PROTOTIPO_LOCAL** | B10 Flutter rhythm_concept_b10.dart + rhythm_concept_lab_b10.dart | Sin persistencia ni perfiles reales; requiere QA Flutter y validación de producto. |
| F-030 | Intención de relación: long-term, open to serious, dating intentionally, still exploring | p.3 | **PROTOTIPO_LOCAL** | B10 Flutter rhythm_concept_b10.dart + rhythm_concept_lab_b10.dart | Sin persistencia ni perfiles reales; requiere QA Flutter y validación de producto. |
| F-031 | Preferencia de tiempo compartido vs. independencia | p.3 | **PROTOTIPO_LOCAL** | B10 Flutter rhythm_concept_b10.dart + rhythm_concept_lab_b10.dart | Sin persistencia ni perfiles reales; requiere QA Flutter y validación de producto. |
| F-032 | Entrenar en pareja: often/sometimes/rarely/separately is great | p.3 | **PROTOTIPO_LOCAL** | B10 Flutter rhythm_concept_b10.dart + rhythm_concept_lab_b10.dart | Sin persistencia ni perfiles reales; requiere QA Flutter y validación de producto. |
| F-033 | Importancia de vida activa de la otra persona | p.3 | **PROTOTIPO_LOCAL** | B10 Flutter rhythm_concept_b10.dart + rhythm_concept_lab_b10.dart | Sin persistencia ni perfiles reales; requiere QA Flutter y validación de producto. |
| F-034 | Vida en pareja entre semana y apoyo durante training block | p.3–4 | **PROTOTIPO_LOCAL** | B10 Flutter rhythm_concept_b10.dart + rhythm_concept_lab_b10.dart | Sin persistencia ni perfiles reales; requiere QA Flutter y validación de producto. |
| F-035 | Tiempo personal y expectativas de relación distinguibles del deporte común | p.3 | **PROTOTIPO_LOCAL** | B10 Flutter rhythm_concept_b10.dart + rhythm_concept_lab_b10.dart | Sin persistencia ni perfiles reales; requiere QA Flutter y validación de producto. |
| F-040 | Compatibilidad life rhythm con peso sugerido **high** | p.3 | **PROTOTIPO_LOCAL** | B10 Flutter rhythm_concept_b10.dart + rhythm_concept_lab_b10.dart | Sin persistencia ni perfiles reales; requiere QA Flutter y validación de producto. |
| F-041 | Relationship intent con peso **high** | p.3 | **PROTOTIPO_LOCAL** | B10 Flutter rhythm_concept_b10.dart + rhythm_concept_lab_b10.dart | Sin persistencia ni perfiles reales; requiere QA Flutter y validación de producto. |
| F-042 | Activity compatibility con peso **medium–high** | p.3 | **PROTOTIPO_LOCAL** | B10 Flutter rhythm_concept_b10.dart + rhythm_concept_lab_b10.dart | Sin persistencia ni perfiles reales; requiere QA Flutter y validación de producto. |
| F-043 | Shared interests con peso **medium** | p.3 | **PROTOTIPO_LOCAL** | B10 Flutter rhythm_concept_b10.dart + rhythm_concept_lab_b10.dart | Sin persistencia ni perfiles reales; requiere QA Flutter y validación de producto. |
| F-044 | Same sport con peso **low–medium**, no obligatorio | p.3 | **PROTOTIPO_LOCAL** | B10 Flutter rhythm_concept_b10.dart + rhythm_concept_lab_b10.dart | Sin persistencia ni perfiles reales; requiere QA Flutter y validación de producto. |
| F-045 | Distancia como filtro práctico, **no puntuación personal** | p.3 | **NO_IMPLEMENTADO** | No encontrado como funcionalidad integral en Flutter B9 o API auditada | Definir arquitectura, consentimiento y prueba de aceptación antes de habilitar. |
| F-046 | Razones específicas visibles, no «87%» inexplicable | p.3 | **PROTOTIPO_LOCAL** | B10 Flutter rhythm_concept_b10.dart + rhythm_concept_lab_b10.dart | Sin persistencia ni perfiles reales; requiere QA Flutter y validación de producto. |
| F-047 | Discovery photo-first con razones antes del swipe | p.5 | **BLOQUEADO_NO_ACTIVAR** | release/readiness.json, fitdating_gate_b5 y docs/product/FITTED_GAP_ANALYSIS_DECISIONS.md | Verificación externa, seguridad, revisión legal, moderación y autorización expresa. |
| F-048 | Flujo de interés y **mutual match** con control de acceso | p.5 | **BLOQUEADO_NO_ACTIVAR** | release/readiness.json, fitdating_gate_b5 y docs/product/FITTED_GAP_ANALYSIS_DECISIONS.md | Verificación externa, seguridad, revisión legal, moderación y autorización expresa. |
| F-049 | Chat después de mutual match | p.5 | **BLOQUEADO_NO_ACTIVAR** | release/readiness.json, fitdating_gate_b5 y docs/product/FITTED_GAP_ANALYSIS_DECISIONS.md | Verificación externa, seguridad, revisión legal, moderación y autorización expresa. |
| F-050 | A: excluir personas del propio gimnasio | pp.3–4 | **PARCIAL_EXISTENTE** | B5 FitDating / B4 comunidad / Gym Shield / API; revisar integración real | Cerrar pruebas reales, reglas, operación y firma humana; no equivale a release. |
| F-051 | B: admitir mismo gym evitando franja horaria habitual | pp.3–4 | **PARCIAL_EXISTENTE** | B5 FitDating / B4 comunidad / Gym Shield / API; revisar integración real | Cerrar pruebas reales, reglas, operación y firma humana; no equivale a release. |
| F-052 | C: no importar la comunidad del mismo gym | p.4 | **BLOQUEADO_NO_ACTIVAR** | release/readiness.json, fitdating_gate_b5 y docs/product/FITTED_GAP_ANALYSIS_DECISIONS.md | Verificación externa, seguridad, revisión legal, moderación y autorización expresa. |
| F-053 | Gym/horarios privados **no** visibles en perfil | p.4 | **PARCIAL_EXISTENTE** | B5 FitDating / B4 comunidad / Gym Shield / API; revisar integración real | Cerrar pruebas reales, reglas, operación y firma humana; no equivale a release. |
| F-054 | No revelar ubicación exacta ni rutina antes de confianza mutua | p.4 | **PARCIAL_EXISTENTE** | B5 FitDating / B4 comunidad / Gym Shield / API; revisar integración real | Cerrar pruebas reales, reglas, operación y firma humana; no equivale a release. |
| F-055 | Regla existente: consentimiento bilateral, diferencias de 29/30 min, bloqueo y límite de intentos | base My Fitness Date | **PARCIAL_EXISTENTE** | B5 FitDating / B4 comunidad / Gym Shield / API; revisar integración real | Cerrar pruebas reales, reglas, operación y firma humana; no equivale a release. |
| F-060 | Active Date después de match: walk+coffee, yoga+brunch, climbing, easy 5K, museo+walk, etc. | p.4–5 | **PROTOTIPO_LOCAL** | B10 Flutter rhythm_concept_b10.dart + rhythm_concept_lab_b10.dart | Sin persistencia ni perfiles reales; requiere QA Flutter y validación de producto. |
| F-061 | Prompt system basado en comportamiento, no adjetivos aspiracionales | p.4 | **PROTOTIPO_LOCAL** | B10 Flutter rhythm_concept_b10.dart + rhythm_concept_lab_b10.dart | Sin persistencia ni perfiles reales; requiere QA Flutter y validación de producto. |
| F-062 | Tarjeta Current Challenge opcional, sin performance scoreboard | p.4 | **PROTOTIPO_LOCAL** | B10 Flutter rhythm_concept_b10.dart + rhythm_concept_lab_b10.dart | Sin persistencia ni perfiles reales; requiere QA Flutter y validación de producto. |
| F-063 | Verificación foto/selfie/teléfono como capas opcionales | p.4 | **POSPUESTO_O_NO_INICIADO** | FITTED PDF p.4-6, roadmap en docs/product/FITTED_EXPLORATORY_CONCEPT_2026.md | No integrar monetización ni proveedores sin aprendizaje y permisos. |
| F-064 | Integraciones con gimnasios/eventos solo opt-in, en fases futuras | p.4,6 | **POSPUESTO_O_NO_INICIADO** | FITTED PDF p.4-6, roadmap en docs/product/FITTED_EXPLORATORY_CONCEPT_2026.md | No integrar monetización ni proveedores sin aprendizaje y permisos. |
| F-065 | Bloqueo y reporte fáciles, community standards y moderación | p.4–5 | **PARCIAL_EXISTENTE** | B5 FitDating / B4 comunidad / Gym Shield / API; revisar integración real | Cerrar pruebas reales, reglas, operación y firma humana; no equivale a release. |
| F-066 | No exigir peso, body-fat %, PRs, calorie burn | p.4 | **PARCIAL_EXISTENTE** | B5 FitDating / B4 comunidad / Gym Shield / API; revisar integración real | Cerrar pruebas reales, reglas, operación y firma humana; no equivale a release. |
| F-067 | Prohibido rankear personas por performance atlético | p.4,6 | **PARCIAL_EXISTENTE** | B5 FitDating / B4 comunidad / Gym Shield / API; revisar integración real | Cerrar pruebas reales, reglas, operación y firma humana; no equivale a release. |
| F-068 | Personas adultas y consentimiento diferenciado para FitDating | base My Fitness Date | **PARCIAL_EXISTENTE** | B5 FitDating / B4 comunidad / Gym Shield / API; revisar integración real | Cerrar pruebas reales, reglas, operación y firma humana; no equivale a release. |
| F-069 | Sin perfiles o imágenes falsas presentadas como reales | base My Fitness Date | **PARCIAL_EXISTENTE** | B5 FitDating / B4 comunidad / Gym Shield / API; revisar integración real | Cerrar pruebas reales, reglas, operación y firma humana; no equivale a release. |
| E-001 | Freemium y premium utility **después** de conversaciones/citas útiles | pp.5–6 | **POSPUESTO_O_NO_INICIADO** | FITTED PDF p.4-6, roadmap en docs/product/FITTED_EXPLORATORY_CONCEPT_2026.md | No integrar monetización ni proveedores sin aprendizaje y permisos. |
| E-002 | Filtros avanzados, más discovery, likes, travel mode, deeper insights | pp.5–6 | **POSPUESTO_O_NO_INICIADO** | FITTED PDF p.4-6, roadmap en docs/product/FITTED_EXPLORATORY_CONCEPT_2026.md | No integrar monetización ni proveedores sin aprendizaje y permisos. |
| E-003 | FITTED+ (nombre provisional): Gym Shield avanzado y matching eventos/viajes | p.6 | **POSPUESTO_O_NO_INICIADO** | FITTED PDF p.4-6, roadmap en docs/product/FITTED_EXPLORATORY_CONCEPT_2026.md | No integrar monetización ni proveedores sin aprendizaje y permisos. |
| E-004 | Event partnerships, venues/experiencias, gimnasios B2B2C más tarde | p.6 | **POSPUESTO_O_NO_INICIADO** | FITTED PDF p.4-6, roadmap en docs/product/FITTED_EXPLORATORY_CONCEPT_2026.md | No integrar monetización ni proveedores sin aprendizaje y permisos. |
| E-005 | Prohibido vender datos de ubicación/rutina, cobrar block/report, pay-to-rank, suplementos en score | p.6 | **PARCIAL_EXISTENTE** | B5 FitDating / B4 comunidad / Gym Shield / API; revisar integración real | Cerrar pruebas reales, reglas, operación y firma humana; no equivale a release. |
| E-006 | IA compleja, wearables, nutrition tracking, leaderboards, gran feed como **fuera del primer MVP** | p.5 | **POSPUESTO_O_NO_INICIADO** | FITTED PDF p.4-6, roadmap en docs/product/FITTED_EXPLORATORY_CONCEPT_2026.md | No integrar monetización ni proveedores sin aprendizaje y permisos. |
| E-007 | Investigación naming: FITTED/SPOTTER/CADENCE/PACE/SYNC | p.7–8 | **INVESTIGACION_PENDIENTE** | docs/product/FITTED_GAP_ANALYSIS_DECISIONS.md — hipótesis SIN_DATOS | Entrevistas, métricas sin PII, revisión humana, legal/naming y piloto. |
| E-010 | Entrevistas a 15–20 singles activos de diferentes disciplinas | p.6 | **INVESTIGACION_PENDIENTE** | docs/product/FITTED_GAP_ANALYSIS_DECISIONS.md — hipótesis SIN_DATOS | Entrevistas, métricas sin PII, revisión humana, legal/naming y piloto. |
| E-011 | Test Gym Shield: excluir gym o franja | p.6 | **INVESTIGACION_PENDIENTE** | docs/product/FITTED_GAP_ANALYSIS_DECISIONS.md — hipótesis SIN_DATOS | Entrevistas, métricas sin PII, revisión humana, legal/naming y piloto. |
| E-012 | Presentar 2–3 prototipos de perfiles y evaluar intención de match | p.6 | **INVESTIGACION_PENDIENTE** | docs/product/FITTED_GAP_ANALYSIS_DECISIONS.md — hipótesis SIN_DATOS | Entrevistas, métricas sin PII, revisión humana, legal/naming y piloto. |
| E-013 | Landing/waitlist bilingüe y prototipo liviano | p.6 | **INVESTIGACION_PENDIENTE** | docs/product/FITTED_GAP_ANALYSIS_DECISIONS.md — hipótesis SIN_DATOS | Entrevistas, métricas sin PII, revisión humana, legal/naming y piloto. |
| E-014 | Evitar experiencia que juzgue capacidad atlética | p.6 | **INVESTIGACION_PENDIENTE** | docs/product/FITTED_GAP_ANALYSIS_DECISIONS.md — hipótesis SIN_DATOS | Entrevistas, métricas sin PII, revisión humana, legal/naming y piloto. |
| E-015 | Medir finalización de secciones, detalles abiertos, match→mensaje, continuación 24–72 h, valoración de contexto y adopción Gym Shield | p.6 | **INVESTIGACION_PENDIENTE** | docs/product/FITTED_GAP_ANALYSIS_DECISIONS.md — hipótesis SIN_DATOS | Entrevistas, métricas sin PII, revisión humana, legal/naming y piloto. |
| E-016 | Roadmap Phase 0 validación → Phase 1 MVP → Phase 2 retención → Phase 3 comunidad → Phase 4 inteligencia | p.7 | **INVESTIGACION_PENDIENTE** | docs/product/FITTED_GAP_ANALYSIS_DECISIONS.md — hipótesis SIN_DATOS | Entrevistas, métricas sin PII, revisión humana, legal/naming y piloto. |
| E-017 | Validar mercado, competencia, trademark, dominio, precios, privacidad, arquitectura antes de lanzamiento comercial | p.8 | **INVESTIGACION_PENDIENTE** | docs/product/FITTED_GAP_ANALYSIS_DECISIONS.md — hipótesis SIN_DATOS | Entrevistas, métricas sin PII, revisión humana, legal/naming y piloto. |
| N-001 | Flutter **Web/Android/iOS**, diseño responsivo, accesibilidad | Pruebas en 320/390/768/1440 px y móviles reales; WCAG 2.2 AA como objetivo | **PARCIAL_EXISTENTE** | B1-B9 / B5 / Supabase y políticas, según componente | Cerrar pruebas reales, reglas, operación y firma humana; no equivale a release. |
| N-002 | API HTTPS versionada, gateway/BFF, dominios modulares | OpenAPI, autenticación y autorización en servidor; nunca datos de gym en interfaz | **PARCIAL_EXISTENTE** | B1-B9 / B5 / Supabase y políticas, según componente | Cerrar pruebas reales, reglas, operación y firma humana; no equivale a release. |
| N-003 | Supabase/Auth/DB en nube, entornos separados y RLS | Evidencia de aislamiento por propietario, protección anti-BOLA y pruebas negativas | **PARCIAL_EXISTENTE** | B1-B9 / B5 / Supabase y políticas, según componente | Cerrar pruebas reales, reglas, operación y firma humana; no equivale a release. |
| N-004 | Consentimiento trazable, privacidad por defecto y revocación | Términos/aviso y FitDating separados; retirada deshabilita dating sin borrar derechos básicos | **PARCIAL_EXISTENTE** | B1-B9 / B5 / Supabase y políticas, según componente | Cerrar pruebas reales, reglas, operación y firma humana; no equivale a release. |
| N-005 | Mayoría de edad verificada fuera de declaración de perfil | Ninguna persona aparece en candidatos sin revisión independiente vigente | **BLOQUEADO_NO_ACTIVAR** | release/readiness.json, fitdating_gate_b5 y docs/product/FITTED_GAP_ANALYSIS_DECISIONS.md | Verificación externa, seguridad, revisión legal, moderación y autorización expresa. |
| N-006 | Datos precisos de gym/horario nunca se revelan en razones de match, logs, telemetría ni capturas | Pruebas de redacción, minimización y antiinferencia | **PARCIAL_EXISTENTE** | B1-B9 / B5 / Supabase y políticas, según componente | Cerrar pruebas reales, reglas, operación y firma humana; no equivale a release. |
| N-007 | Bloqueo/reporte no son de pago; moderación real para lanzamiento | Protocolo de incidente, personas responsables y evidencias | **PARCIAL_EXISTENTE** | B1-B9 / B5 / Supabase y políticas, según componente | Cerrar pruebas reales, reglas, operación y firma humana; no equivale a release. |
| N-008 | Acceso, corrección, baja/exportación, retención y derechos ARCO | Flujo probado, responsables y plazos con revisión jurídica | **PARCIAL_EXISTENTE** | B1-B9 / B5 / Supabase y políticas, según componente | Cerrar pruebas reales, reglas, operación y firma humana; no equivale a release. |
| N-009 | Seguridad de fotografías y chat | Sanitización/EXIF, moderación, antispam/abuso, privacidad, retención, pruebas antes de liberar | **BLOQUEADO_NO_ACTIVAR** | release/readiness.json, fitdating_gate_b5 y docs/product/FITTED_GAP_ANALYSIS_DECISIONS.md | Verificación externa, seguridad, revisión legal, moderación y autorización expresa. |
| N-010 | Localización ES/EN como arquitectura de producto | Strings parametrizados, tono natural, pruebas de formatos y revisión bilingüe humana | **PROTOTIPO_LOCAL** | B10 Flutter rhythm_concept_b10.dart + rhythm_concept_lab_b10.dart | Sin persistencia ni perfiles reales; requiere QA Flutter y validación de producto. |
| N-011 | Métricas con minimización; aprendizaje sin inventar | No registrar dirección, horario, JWT, edad exacta, contenido sensible ni perfiles de terceros | **INVESTIGACION_PENDIENTE** | docs/product/FITTED_GAP_ANALYSIS_DECISIONS.md — hipótesis SIN_DATOS | Entrevistas, métricas sin PII, revisión humana, legal/naming y piloto. |
| N-012 | CI/CD y release gates `G0–G5` y `release/readiness.json` | No marcar `verified` sin propietario, evidencia externa y QA | **PARCIAL_EXISTENTE** | B1-B9 / B5 / Supabase y políticas, según componente | Cerrar pruebas reales, reglas, operación y firma humana; no equivale a release. |
| N-013 | Free First, límites/costo por proveedor; no despliegues pagos inferidos | Registrar cuotas, monitoreo y aprobar costos antes de agregarlos | **PARCIAL_EXISTENTE** | B1-B9 / B5 / Supabase y políticas, según componente | Cerrar pruebas reales, reglas, operación y firma humana; no equivale a release. |
| N-014 | Reglas de Gym Shield existentes siguen vigentes | Pruebas de consentimiento bilateral, buffer de 30 min, cuotas, bloqueos y datos no expuestos | **PARCIAL_EXISTENTE** | B1-B9 / B5 / Supabase y políticas, según componente | Cerrar pruebas reales, reglas, operación y firma humana; no equivale a release. |

## Criterio de aceptación final

**No cambiar `release/readiness.json` a `verified` sin pruebas y aprobación humana.** El candidato B10 sigue privado y sujeto a gates. El siguiente paso del proceso es cerrar los nueve release gates existentes, resolver CI heredado, verificar la experiencia ES/EN con personas reales e instrumentar métricas sin PII. Todas las propuestas del PDF se conservan como hipótesis cuando no fueron aprobadas por el propietario.
