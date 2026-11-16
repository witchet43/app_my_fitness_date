-- Upgrade only the untouched legacy seed. Never overwrite an owner's edits.
begin;
with seed as (
 select jsonb_build_object(
   'name','Fitted',
   'tagline','Personas en movimiento. Conexiones con intención.',
   'title','Personas en movimiento. Conexiones que trascienden.',
   'description','Entrenamiento, recovery y rutinas intencionales. Conecta por tus valores y estilo de vida, incluso si practican deportes distintos.',
   'paletteName','Editorial Obsidian',
   'colors',jsonb_build_object(
     'primary','#D5BE8A','accent','#9FB5A9','background','#101B21'),
   'font','Georgia','logo','catalog:8','media','{}'::jsonb,
   'mode','dark','layout','editorial'
 ) as settings
), updated as (
 update public.mfd_brand_live b
 set settings=seed.settings,version=1,updated_at=now()
 from seed
 where b.id=true and b.version=0
   and b.settings->>'name'='My Fitness Date'
   and b.settings->>'paletteName'='Original'
 returning b.version,b.settings
)
insert into app_private.mfd_brand_history(version,settings)
select version,settings from updated
on conflict (version) do nothing;
commit;
