# B4 · QA de comunidad y moderación

**NO se habilita beta pública con este runbook.** Todas las operaciones privadas deben preservar la separación de administrador/member.

## Despliegue seguro
1. Ejecutar preflight local de TypeScript y `python3 scripts/check_b1_static.py`, `check_b2_static.py`, `check_b3_static.py`, `check_b4_static.py`. Revisar Flutter analyze/tests antes de activar el único job B4. No llamar jobs por cada modificación.
2. Aplicar `202611120019_community_safety_b4.sql` primero a una base aislada cuando exista. Si solo está disponible la BD alojada existente, confirmar que las tablas/funciones son NUEVAS, que el proyecto no tiene tráfico social real y que ninguna API pública previa es reemplazada.
3. Inspeccionar RLS, GRANT y EXECUTE: tablas comunitarias sin privilegios de lectura/escritura anon/authenticated; solo funciones explicitamente permitidas para JWT autenticado.
4. Verificar `community_status_b4` en ausencia de JWT => `not_authenticated`; `admin_community_queue_b4` sin sesión AAL2 => lista vacía; `admin_community_publish_b4` sin owner MFA => `forbidden`.
5. Publicar API en **función independiente** `member-api-b4-preview`, con origen CORS exacto `https://b4-preview.my-fitness-date.pages.dev`; no reemplazar la API anterior.
6. Activar un solo pipeline/slot B4 que haga Node/contratos, Flutter analyze/tests, build web release, despliegue rama Cloudflare `b4-preview` y smoke de SHA exacto. No publicar a `main`.

## Pruebas de dos identidades
- Cuenta miembro A y B: ambas confirmadas y adultas; aceptar legal y comunidad. Cuenta admin OWNER en MFA AAL2.
- A publica; B ve y reporta post + perfil, A no conoce reporter.
- B bloquea A; ambos dejan de ver posts del otro; desbloquear restaura solo los posts no moderados.
- Admin recibe denuncia, elige ocultar, registra motivo; el post desaparece incluso para otros miembros; revisar auditoría.
- Admin publica un comunicado legítimo y comprueba aparición desde cuenta B sin publicar como miembro.
- A solicita baja; sus posts dejan de estar visibles; administrador ve solicitud pendiente; no afirmar supresión.
- Forzar 403, 409, 429, caídas de red, texto con teléfono/link, doble click, reportes duplicados.
- Confirmar que el administrador NO pueda postear con API de miembro y que miembros no puedan invocar funciones de moderación.

## Riesgos abiertos / NO-GO
No abrir a público sin verificación externa de edad, staffing/moderación humana con SLA, normas de contenido, abuso/anti-scraping, proceso de eliminación completa y revisión de seguridad. Citas/chat permanecen inactivos. El bloqueo aplicado en comunidad deberá propagarse a todos los descubrimientos de FitDating antes de B5.

## FinOps
El contador de partida de B4 es 4/10 ejecuciones remotas ya consumidas. B4 corresponde a la quinta (5/10); B10 es contingencia, B9 ya se utilizó. Si B4 falla, corregir localmente y arrastrar a B5, sin reruns automáticos.
