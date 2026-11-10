# Trust & Safety V5 — my_fitness_date

- Reportes desde Comunidad, Actividades y FitDating con selección explícita de motivo.
- Almacenamiento privado en `app_private.safety_reports`; no disponible para lectura de usuarios.
- Moderación de publicaciones mediante `app_private.hidden_posts`: **solo administración por SQL**, todavía sin personal o panel operativo.
- Bloqueo recíproco para lectura de perfiles sociales, posts, eventos y el descubrimiento romántico.
- Mitigación de inferencia: límite por cuenta de 30 consultas de descubrimiento por hora y 12 cambios de preferencias por día.
- Seguridad: límites **reducen, no eliminan** inferencia; siguen pendientes verificación de edad, multicuenta, moderación activa, apelaciones y respuesta a incidentes.
- Pruebas SQL de permisos, bloqueo, ocultamiento de contenido, denuncias y rate limits.
- Aplicar `supabase/migrations/202610270004_trust_safety.sql` exclusivamente a `my_fitness_date_dev`, verificando CI antes.
- En desarrollo local, usar solo la `EXPO_PUBLIC_SUPABASE_PUBLISHABLE_KEY` como clave cliente.

El operador privilegiado puede consultar reportes pendientes en el SQL Editor del proyecto:

```sql
select id,target_type,target_id,reason,created_at
from app_private.safety_reports where status='pending'
order by created_at limit 50;
```

Nunca publicar reportes, identificadores de usuarios reales ni moderación sensible en GitHub. **No abrir beta pública.**
