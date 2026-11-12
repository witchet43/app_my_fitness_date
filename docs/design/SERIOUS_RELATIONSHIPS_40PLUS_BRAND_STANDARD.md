# My Fitness Date — Estándar de marca, diseño y experiencia para relaciones serias 40+

**Estado:** `DIRECCIÓN DE PRODUCTO CONFIRMADA POR EL PROPIETARIO` — 11 de noviembre de 2026.  
**Alcance:** identidad visual, voz, UX, descubrimiento y requisitos para próximos desarrollos Web/Android/iOS.  
**Implementación:** **pendiente**; este documento no modifica por sí solo la aplicación publicada.  
**Issue:** [#46](https://github.com/witchet43/app_my_fitness_date/issues/46).  
**Producto/marca actual:** **My Fitness Date**, con **FitDating** como función opcional de conexión personal. El naming «FITTED» continúa siendo exploratorio.  
**Fuente:** dirección explícita del propietario en conversación; **no** se atribuye al PDF exploratorio FITTED, que incluía opciones de dating más abiertas.  
**Normativa de ingeniería aplicable:** SaaS Factory v1.9, `AGENTS.md`, accesibilidad WCAG 2.2 AA como objetivo, privacidad por defecto, gates existentes.

## 1. Posicionamiento obligatorio (producto)

**My Fitness Date no es una aplicación de ligue o citas casuales.** Su propósito es ayudar a personas **mayores de 40 años**, con un estilo de vida activo y expectativas maduras, a conocerse desde la compatibilidad real de valores, rutinas y proyectos de vida, con la intención de construir **relaciones serias y estables**.

**Atributos de marca:** elegante, sobria, discreta, confiable, contemporánea, humana, cálida sin ser cursi, formal sin parecer fría y activa sin ser un gimnasio competitivo.

**Cómo se traduce a decisiones de experiencia:**
- La afinidad se presenta como **compatibilidad de vida**, respeto de tiempos, intereses y propósito; nunca como valoración física.
- Destacar **How I Move / How I Live / How I Relate**, poniendo énfasis en hábitos, valores, intenciones y cómo conviven dos vidas, no en apariencia o frecuencia atlética.
- La navegación debe parecer un **servicio cuidado y de confianza**, no un juego de corazones, flechas, confeti, «swipes» y recompensas.
- Las conversaciones y eventuales encuentros deben favorecer **calma, claridad, consentimiento y trato respetuoso**, sin presión ni urgencia artificial.
- El segmento de marketing prioritario es **personas mayores de 40 años**. **No** convertir esta orientación en un corte automatizado de elegibilidad o exclusión de cuentas más jóvenes sin decisión explícita adicional, análisis legal, UX y cambios de términos. El requisito vigente de mayoría de edad verificada y consentimiento de FitDating **no se modifica**.

### Lo que explícitamente **no** somos

- App vulgar, sexualizada o de «hookups»; tampoco un «Tinder del gym».
- Estética adolescente, tonos de enamorados, exceso de rosa/rojo fucsia, corazones, cupidos, besos, llamas, filtros de belleza o cuerpos como producto.
- Un concurso de popularidad, atractivo, cuerpos, edad, peso, récords o nivel deportivo.
- Una app que prometa «encontrar el amor garantizado» o que invente coincidencias, perfiles, eventos o testimonios.

## 2. Sistema de color propuesto para aprobación visual

**Dirección confirmada:** paleta **atemporal, elegante, neutra y contenida**. **Valores HEX de abajo son propuesta técnica para prototipado y accesibilidad**, no una paleta aprobada visualmente por el propietario todavía. El contraste debe probarse por combinación real de fondos, estados y texto.

| Token semántico | HEX sugerido | Uso previsto |
| --- | --- | --- |
| `ink` | `#14211F` | Textos principales / fondo profundo |
| `forest` | `#28463D` | Acciones primarias, encabezados, selección |
| `alabaster` | `#F7F5F0` | Fondo claro base |
| `paper` | `#FFFEFB` | Superficie principal clara / cards |
| `stone` | `#DEDAD0` | Divisores, campos, bordes discretos |
| `slate` | `#52625B` | Texto secundario en claro, ayudas |
| `bronze` | `#B49A6A` | Acento ornamental limitado: detalles y separadores |
| `midnight` | `#101C1A` | Fondo alternativo oscuro |
| `darkSurface` | `#21302C` | Tarjetas oscuras |
| `ivoryText` | `#F3F4EE` | Tipografía sobre fondo oscuro |
| `mutedDark` | `#C4CFC7` | Secundario sobre fondo oscuro |
| `danger` | `#A1423C` | Errores/alertas únicamente; **no** amor ni CTA |
| `success` | `#37674B` | Confirmaciones; acompañar con texto e icono |

**Reglas:**
1. Priorizar `paper/alabaster + ink/forest`; el modo oscuro combina `midnight/darkSurface + ivoryText`.
2. `bronze` es un **acento muy pequeño**, no texto sobre blanco de tamaño normal ni botones de bajo contraste.
3. Los botones primarios deben tener contraste AA de texto e icono; bosque con texto claro es la dirección candidata.
4. Eliminar progresivamente de **identidad dominante** coral romántico `#FF617B`, lima fluorescente `#C8FF6B`, lila vibrante `#A995FF`, degradados magenta/rosa y neon. Podrían existir tonos funcionales aislados si son necesarios y accesibles, nunca como personalidad principal.
5. No diseñar con gradientes intensos; preferir luz, superficies, jerarquía y espacios en blanco.
6. Evaluación de color considerando discapacidad visual, texto ampliado, daltonismo, modo oscuro, estado disabled/foco y contrastes WCAG 2.2 AA. No declarar AA sin medición y test real.

## 3. Tipografía y composición

**Dirección confirmada:** editorial, contemporánea, seria y muy legible, especialmente para el público 40+.

**Pareja tipográfica candidata, pendiente de revisar licencias y pruebas:** 
- **Titulares/editorial:** `Lora` (o `Georgia` como fallback). Uso restringido al título de portada, títulos de sección y una frase de valor; **sin exceso decorativo**.
- **Interfaz, cuerpo, formularios y navegación:** `Source Sans 3` (o sans-serif de sistema como fallback), preferentemente 400/500/600. No usar tipografía ultradelgada ni condensada.
- **No** incrustar fuentes externas sin revisar redistribución y política de privacidad; en web priorizar self-hosting solo con licencia válida.

**Escala candidata** (modificable por accesibilidad):
| Elemento | Escritorio | Móvil | Reglas |
| --- | --- | --- | --- |
| H1/editorial | 40–44 px | 30–32 px | Peso 500–600, interlineado ~1.2 |
| H2 | 27–31 px | 24–26 px | Distinción por jerarquía, no solo color |
| H3 | 20–22 px | 19–21 px | Legible |
| Cuerpo | 17–18 px | 17 px | Interlineado ~1.5–1.65 |
| Formularios/CTA | 16–17 px | 16–17 px | Objetivo táctil >= 48 px |
| Ayuda/metadata | 14–15 px | 14–15 px | Evitar 11–12 px en acciones críticas |

**Composición:** grilla consistente, márgenes respirables, bloques de texto breves, secciones jerarquizadas, bordes sutiles, radio contenido (aprox. 12–16 px), sombras mínimas, transiciones discretas (y `reducedMotion`), interfaz utilizable con teclado y lector de pantalla. No usar MAYÚSCULAS permanentes, `fontWeight.w900` de forma dominante, textos en neón ni títulos enormes tipo evento nocturno.

## 4. Logotipo e iconografía: conflicto visual explícito

Los dos logos que ya proporcionó el propietario **incluyen un corazón prominente en rojo/rosa y figuras deportivas**. Son **assets existentes y válidos como referencia histórica**, pero **entran en conflicto con la directriz nueva** de evitar iconos románticos típicos.

**Decisión:** **no borrarlos ni reemplazarlos silenciosamente**. Abrir un proceso de rediseño/selección aprobado por el propietario: wordmark tipográfico **My Fitness Date**, iniciales geométricas **MFD**, ritmo/movimiento abstracto o composición minimalista; explorar sin utilizar corazones ni siluetas como pareja de enamorados.

- Hasta aprobar un logo nuevo, el cliente actual puede seguir usando los assets antiguos; no declararlos conformes al nuevo estándar.
- En nuevas vistas/prototipos, usar **wordmark tipográfico neutral** y símbolos abstractos de **trayectoria, diálogo, conexión respetuosa**.
- Iconografía: lineal, espaciado consistente, tamaño objetivo 20–24 px, sin confeti/emojis de amor, no corazones para `like`, no llamas, no iconos sexuales.
- Una acción de interés puede usar `Conocer`, `Expresar interés` o `Iniciar conversación` cuando esté permitida, con icono neutral y explicación de consentimiento.

## 5. Fotografía, retratos y contenido

- Adultos **40+ representados con autenticidad**, diversidad de estilos, disciplinas, contextos y apariencias reales. El mensaje no debe sugerir que solo personas jóvenes, musculosas o con un cuerpo específico merecen ser vistas.
- Preferir imágenes con luz natural y ambientes sobrios: café, conversación, caminata, actividad física cotidiana, cultura, aire libre, convivencia respetuosa. No erotizar ni cosificar.
- Evitar poses sugestivas, filtros que alteren radicalmente el rostro, fotografías de gimnasio tipo publicidad de suplementos, cuerpos recortados o sexualizados.
- Una foto de una persona **debe estar autorizada**; nunca usar fotos de personas reales como usuarios ficticios ni mostrar retratos de muestra como candidatos auténticos.
- Si se añaden fotografías de perfil: moderación, minimización de metadatos EXIF, reporte/bloqueo, protección de privacidad, edad y derechos de autor antes de abrir a usuarios.

## 6. Tono de comunicación y microcopy

**Voz:** formal contemporánea, directa, clara, elegante, inclusiva y confiable. **Calidez sin cursilería**. Español latino natural con tratamiento consistente de «tú» y equivalentes en inglés culturalmente revisados.

| Contexto | Preferir | Evitar |
| --- | --- | --- |
| Valor | «Conoce personas con quienes compartas valores y estilo de vida.» | «Encuentra tu media naranja», «amor a primera vista» |
| Propósito | «Conexiones con intención.» / «Relaciones que encajan con tu forma de vivir.» | «Ligue al instante», «citas calientes», «match explosivo» |
| Exploración | «Descubre afinidades» / «Personas compatibles con tu ritmo» | «Desliza sin parar», «que empiece el coqueteo» |
| Perfil | «Cómo vivo», «Mis intereses», «Qué valoro en una relación» | «¿Qué tan hot eres?», ranking de atractivo |
| Interés | «Expresar interés» / «Conocer mejor» | Corazones infinitos, presión para dar likes |
| Seguridad | «Tu espacio y tus horarios de entrenamiento permanecen privados.» | Prometer seguridad absoluta |
| Sin resultados | «Todavía no hay perfiles disponibles con estas preferencias.» | Contadores o coincidencias ficticias |
| Invitación | «Un espacio para conversar con calma y propósito.» | Urgencia/manipulación: «¡No pierdas esta oportunidad!» |

**Intención de relación:** no presentar hookups, encuentros de una noche o «sin compromiso» como objetivos centrales ni promocionarlos. Priorizar `relación estable`, `conocer con intención`, `proyecto compartido`, `afinidad y compañía`, `compromiso gradual`. No moralizar a quienes tengan otra forma de relacionarse; el producto simplemente define su posicionamiento. La colección de intenciones y los filtros deben revisar equivalencias del PDF original (incluido `still exploring`) sin cambiar contratos existentes antes de ADR/QA.

## 7. Diseño de experiencia por pantalla

### Landing y registro
- Priorizar mensaje elegante de propósito serio, privacidad y compatibilidad de vida, no un gimnasio romántico.
- Hero con tipografía editorial, espacio en blanco y pieza visual neutral; Google/correo accesibles y previsibles.
- Aclarar comunidad deportiva y FitDating opt-in sin prometer disponibilidad de parejas ni verificación no cumplida.
- Consentimientos claros, aviso de privacidad visible, sin dark patterns.

### Perfil en tres capas
- Formularios paso a paso **How I Move / How I Live / How I Relate** con preguntas maduras, lenguaje sencillo y opciones de omitir cuando proceda.
- Enfatizar valores, proyectos, tiempo compartido vs. independencia, familia, viajes, hábitos y relaciones estables.
- Sin preguntas sobre performance, peso, porcentaje de grasa, métricas corporales o glamour.

### Discovery, interés y conversación
- Presentar personas reales autorizadas **como seres humanos**, con información contextual/afinidad antes que un carrusel de caras.
- **No** diseñar una máquina de swipe infinito, loterías de likes, ranking por atractivo, streaks, recompensas ni presión temporal.
- Mostrar *por qué* coinciden prioridades y hábitos, sin filtrar razones derivadas de gimnasio/horario privados.
- Solo habilitar interés mutuo, chat, reportes y controles después de verificación de edad, consentimiento y moderación exigidos.

### Gym Shield / confianza
- Tratamiento sobrio, fácil de entender, con prioridad al control de seguridad. Ubicaciones/horarios exactos no aparecen en perfiles ni razones de coincidencia.
- La estética premium **no debe esconder** el bloqueo/reporte ni trasladarlo a pago.

## 8. Criterios de aceptación de la siguiente implementación visual

| ID | Condición de aceptación | Validación |
| --- | --- | --- |
| BR-01 | El primer vistazo comunica **conexión seria y activa para 40+**, no hookups | Revisión de contenido y pruebas con participantes del segmento |
| BR-02 | Sin motivos visuales románticos comunes en pantallas nuevas | Inspección UI: sin corazones, fucsia, gradientes de amor, llamas, sexualización |
| BR-03 | Paleta funcional sobria y pareja tipográfica consistente | Tokens Flutter + pruebas de screenshots claros/oscuros |
| BR-04 | Legibilidad 40+: cuerpo >=17 px, controles >=16 px, touch targets >=48 px | QA a escalado 200%, móvil, teclado, lector de pantalla |
| BR-05 | Sin publicidad o mensaje de citas casuales | Auditoría ES/EN de copy en onboarding/perfil/discovery |
| BR-06 | Preferencias de relación priorizadas sobre mismo deporte | Pruebas de UX/matching y transparencia de razones |
| BR-07 | Compatibilidad con perfil y edad; sin cambios de elegibilidad por marketing | Verificación de flujos existentes, no modificar cuentas |
| BR-08 | Nuevo logo/wordmark aprobado y archivo histórico resguardado | Decisión owner, recursos adecuados, favicon/app icon/launcher probados |
| BR-09 | Privacidad Gym Shield y autenticación preservadas | CI, RLS/anti-BOLA, pruebas negativas y revisión manual |
| BR-10 | No se publica sin revisión visual y gates de release aplicables | Capturas 390/768/1440, QA accesibilidad, PR y evidencia exacta de commit |

## 9. Ruta de implementación (no desplegada)

1. **Diseño:** crear una propuesta visual para **portada + registro + perfil** siguiendo este estándar; comparar con diseño «Active Chemistry» V25 y obtener revisión explícita.
2. **Sistema de diseño:** introducir tokens semánticos claros/oscuros, tipografías licenciadas y componentes reutilizables en Flutter con pruebas.
3. **Branding:** acordar un wordmark/isotipo que sustituya el corazón existente sin perder reconocimiento de marca.
4. **Copy:** migrar frases/íconos que sugieren flirteo casual; conservar propósito de comunidad y FitDating voluntario.
5. **UX:** diseñar perfil en tres capas y discovery sin gamificación adictiva; completar consentimiento, edad y moderación antes de habilitar interacciones románticas.
6. **QA:** revisión de 40+ con consentimiento, pruebas de legibilidad/contraste/accesibilidad, Android/iOS/Web; release con evidencia, seguridad y aprobación.

## 10. Jerarquía documental

- **Esta directriz posterior del propietario** tiene prioridad para el posicionamiento del producto frente a opciones casuales del PDF FITTED.
- El [concepto FITTED exploratorio](../product/FITTED_EXPLORATORY_CONCEPT_2026.md) **se conserva como fuente histórica sin reescritura**.
- Los [requisitos trazables](../product/LIFESTYLE_COMPATIBILITY_REQUIREMENTS.md) incorporan los nuevos BR-xx por separado.
- El [análisis de brechas](../product/FITTED_GAP_ANALYSIS_DECISIONS.md) mantiene decisiones técnicas abiertas; la intención de relaciones serias y el enfoque 40+ **ya no son hipótesis de copy**.
- La [auditoría Active Chemistry V25](ACTIVE_CHEMISTRY_AUDIT_V25.md) es un registro histórico de la estética coral/lima; **no** una dirección visual a reutilizar.
- **No** actualizar las puertas `release/readiness.json` a cumplidas sin evidencia; este documento por sí solo no implica que la experiencia haya sido implementada.
