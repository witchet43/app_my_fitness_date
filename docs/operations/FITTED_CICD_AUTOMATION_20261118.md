# Fitted — automatización CI/CD propia (2026-11-18)

## Alcance
No se incorpora un agente de codificación externo. ChatGPT y conectores GitHub/Supabase coordinan desarrollo; GitHub Actions ejecuta validación y despliegue. La continuidad fuera del chat se limita a tareas deterministas de Actions.

## Arquitectura operativa
1. Ramas/PR revisables; nunca escribir directamente a main por conveniencia.
2. `fitted-change-ci.yml` selecciona pruebas por rutas (no despliega).
3. `mfd-canonical-auth-release.yml` compila y publica Flutter Web en main cuando cambian archivos relevantes y sigue disponible manualmente.
4. `fitted-supabase-deploy.yml` publica migraciones o una función permitida **solo** tras despacho manual y políticas del environment `production`. La aprobación externa de GitHub Environment debe configurarse en Settings; el YAML por sí solo no añade un revisor humano.
5. `fitted-release-reconcile.yml` compara el SHA exacto del artefacto público contra la ejecución que lo originó y guarda evidencia. No acredita automáticamente parity de base de datos ni pruebas autenticadas.
6. `fitted-monitor.yml` realiza comprobación diaria de sitio y heartbeat; los fallos quedan visibles en GitHub Actions.

## Riesgos y límites
- GitHub Actions no corrige semánticamente código por IA ni reanuda conversaciones.
- El frontend web de Flutter se compila como unidad; los cambios de backend no deben recompilarlo.
- No borrar workflows históricos hasta migrar y comprobar sus controles; el inventario inicial contiene 35.
- Las Edge Functions preview requieren revisión de dependencias y autorización antes de desactivarse.
- No autodesplegar migraciones destructivas. Revisar RLS y compatibilidad antes del despacho.
- No confundir release HTTP verificado con aprobación comercial/beta. Respetar AGENTS.md, release/readiness.json y gates G0-G5.
- Configurar SUPABASE_ACCESS_TOKEN y SUPABASE_DB_PASSWORD como secretos del environment production antes de usar el workflow backend. No registrar secretos en logs.
- La telemetría real (latencia, incidentes y gastos) aún requiere evaluación de herramientas y cuotas.

## Siguiente reconciliación
Validar protección de main, required checks y environment production; certificar flujos de autenticación y Match/Gym Shield con usuarios QA; revisar tiempos y minutos de Actions durante varios releases.
