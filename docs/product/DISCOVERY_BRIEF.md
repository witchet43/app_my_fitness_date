# Product Discovery — My Fitness Date (SaaS Factory PX-01..PX-09)
**Estado: HIPÓTESIS SIN VALIDACIÓN CON USUARIOS REALES.** No contiene testimonios ni resultados inventados.

## Segmentos candidatos
1. Adultos que buscan crear comunidad y participar en actividades físicas (usuario principal).
2. Adultos que quieren habilitar voluntariamente FitDating y descubrir perfiles sin revelar su gimnasio ni horarios privados.
3. Organizadores/moderadores, cuyos objetivos y necesidades operativas requieren investigación distinta.

**Comprador:** pendiente de definir; no se ha validado pricing, paywall ni disposición a pagar.

## JTBD candidato
Cuando quiero conocer a personas con intereses deportivos compatibles, deseo participar de forma segura en actividades reales sin exponer mis rutinas o ubicación precisa, para construir vínculos sociales respetando mi privacidad.

## Alternativas por estudiar
Comunidades deportivas, grupos de mensajería, redes sociales y aplicaciones de encuentros; comparar flujos, reputación, costos, privacidad y actividad útil con datos verificables. Ninguna ventaja competitiva se afirma como probada.

## Hipótesis falsables
- H1: adultos que quieren comunidad pueden descubrir y confirmar participación en una actividad sin orientación del desarrollador.
- H2: quienes activan FitDating comprenden y confían en las restricciones Gym Shield sin necesidad de revelar gimnasio/horarios.
- H3: reportar o bloquear a otra persona resulta accesible y verificable sin compartir datos sensibles.

**Criterios de refutación:** bloqueos de tareas críticas, dudas sobre privacidad, abandono sistemático y riesgos reportados durante pruebas observadas.

## Plan G0 antes de beta
- Reclutar participantes adultos voluntarios y representativos; no activar registro público por invitación hasta revisar gates.
- Probar prototipos con datos sintéticos y consentimiento específico; permitir retiro y definir retención/borrado de notas.
- Observar flujo comunidad → actividad → confirmación segura y (opt-in) ajustes FitDating y bloqueo.
- Registrar tareas completadas, ayuda necesaria, fallos, comprensión de privacidad y cambios al backlog sin PII.
- Definir propietario, ventana, tamaño de muestra y criterio CONTINUAR / ITERAR / PIVOTAR / PAUSAR.

**Entrevistas realizadas y validadas:** SIN_DATOS. **Pruebas de usabilidad con personas reales:** SIN_DATOS.

---

## Complemento exploratorio — FITTED (documento recibido, 11-nov-2026)

Se incorporó un **segundo eje de descubrimiento**: evaluar si el *lifestyle* (rutina de vida, preferencias de tiempo compartido, modo de entrenamiento y expectativas de relación) permite decisiones de compatibilidad más útiles que compartir el mismo deporte. El concepto se titula provisionalmente **FITTED**, pero **la marca actual sigue siendo My Fitness Date** y **FitDating** permanece opcional mientras no exista decisión de negocio.

- [Concepto FITTED — lectura fiel del PDF de 8 páginas](FITTED_EXPLORATORY_CONCEPT_2026.md).
- [Requisitos y criterios de aceptación candidatos, con trazabilidad](LIFESTYLE_COMPATIBILITY_REQUIREMENTS.md).
- [Brechas con el producto actual y decisiones D-01..D-14](FITTED_GAP_ANALYSIS_DECISIONS.md).
- [ADR-0004: hipótesis, no rebranding](../adr/0004-fitted-lifestyle-discovery-proposed.md).

**Hipótesis a comprobar, sin datos reales todavía:**
- H-FIT-01: conocer Life Rhythm y Relationship Rhythm cambia la intención de match más que el deporte idéntico.
- H-FIT-02: Gym Shield A/B aumenta sensación de control de privacidad sin revelar gimnasio ni horarios.
- H-FIT-03: una explicación comprensible de compatibilidad es más útil que un porcentaje misterioso.
- H-FIT-04: los prompts situacionales proporcionan información relacional que una bio genérica omite.

**Investigación propuesta por la fuente:** 15–20 entrevistas a personas solteras activas de diferentes disciplinas; 2–3 perfiles prototipo; prototipos bilingües, revisión cultural por ciudad/país y estudio de naming/trademark. No iniciar pago, chat, citas, rebranding o nuevas capturas de datos por este documento. **Entrevistas y métricas de FITTED: SIN_DATOS.**

**Tensión deliberadamente abierta:** el PDF propone una app `dating-first` cuyo MVP deja un gran social feed para después, mientras que My Fitness Date fue concebido `community-first` con citas opt-in. Resolver explícitamente antes de reordenar o retirar módulos.
