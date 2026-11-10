# ADR-0002 — Interpretación modular-first de SaaS Factory v1.9
- **Estado:** PROPUESTA para revisión, no revoca ADR-0001.
- **Motivo:** la ADR-0001 fija microservicios independientes como objetivo; el estándar canónico v1.9 favorece módulos por dominio y extraer sólo por necesidades verificadas.
- **Decisión propuesta:** mantener API Gateway y Gym Shield ya desarrollados y probados en DEV sintético; nuevos dominios se implementan primero como módulos o paquetes con fronteras claras. Crear servicio autónomo sólo ante motivación comprobable de escala, aislamiento, seguridad o despliegue. No migrar la RPC crítica Gym Shield sin equivalencia y controles de edad/RLS.
- **Consecuencias:** menor costo/operación y acoplamiento manejable; exige contratos, disciplina modular y ADR por extracción.
- **Condición de aprobación:** revisión técnica, pruebas, presupuesto Free First y reconciliación explícita con ADR-0001, sin cambios de runtime implícitos.
