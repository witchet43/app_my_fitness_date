# My Fitness Date — instrucciones vinculantes para agentes (SaaS Factory v1.9)

Antes de diseñar, editar o desplegar, consultar:
- Índice: https://docs.google.com/document/d/1jl6c96siJ1ef501iYKH3tM7eEV1bcB_IRDmownnxiLQ/edit
- Estándar: https://docs.google.com/document/d/11hytKADuIUpmWzHEmAfZwcYNJ04M7n1ev4A1fbeZy9Q/edit
- `product.manifest.yaml`, `docs/compliance/SAAS_V19_CONTROL_BASELINE.csv` y `docs/SAAS_FACTORY_ADOPTION_V19.md`.
- **Antes de modificar marca, UX, interfaz, copy, onboarding o descubrimiento:** `docs/design/SERIOUS_RELATIONSHIPS_40PLUS_BRAND_STANDARD.md` (dirección confirmada: estilo elegante, público 40+, relaciones serias, sin estética romántica típica). No sustituir los logos heredados ni bloquear por edad 40+ sin decisión específica.

Política de ejecución:
1. Trabajar en ramas y PR revisables, no alterar main ni desplegar por inferencia. Respetar la cadena de PR #23–#27.
2. Las acciones de pago, publicación, cambios de permisos, borrado o producción necesitan autorización específica y evidencia externa. No introducir secretos en el código, documentos o prompts.
3. Conservar Supabase DEV y permisos RLS; no añadir políticas abiertas por un aviso INFO de tablas privadas. No activar registro real ni datos de personas sin gates cumplidos.
4. Flutter consume exclusivamente el Gateway/BFF para negocio. Nunca incrustar service_role o claves privilegiadas; no migrar RPC Gym Shield sin pruebas de equivalencia y anti-BOLA.
5. Preferir arquitectura modular primero; no introducir nuevos microservicios, costos, proveedores ni funciones IA sin ADR y justificación.
6. Para cada trabajo: Issue → criterios de aceptación → PR → pruebas → revisión → release identificable → smoke real. Mostrar estado de CI confirmado, no simulado.
7. Los controles inician NO_EVALUADO. Nunca cambiarlos a CUMPLE sin propietario y enlace a evidencia verificable. NO_APLICA requiere justificación. Ejecutar `python3 scripts/check_saas_factory.py` y `--release` antes de recomendar producción.
8. Un servicio o build con CI aprobado no equivale a beta ni App Store/Play. Mantener NO-GO hasta cumplir `release/readiness.json`, gates G0–G5, QA física, revisión de seguridad, edad, privacidad y moderación.
9. Nada de PII en logs/eventos, pruebas con datos sintéticos; no declarar satisfacción, retención ni margen sin telemetría real.
10. Monitoreo y controles de gasto Free First no son garantía de costo 0. Consultar cuotas oficiales vigentes antes de cada recurso adicional.
