-- Integration tests: run after base auth bootstrap, v1/v2/v4 migrations
-- and v1 tests (users 100...001 through ...004 already present).
-- Work in a disposable PostgreSQL database OR wrap in BEGIN/ROLLBACK remotely.

set role anon;
do $$
begin
 if has_table_privilege(current_user, 'public.social_profiles','SELECT')
   or has_table_privilege(current_user,'public.community_posts','SELECT')
   or has_table_privilege(current_user,'public.sport_events','SELECT')
   or has_table_privilege(current_user,'public.event_rsvps','SELECT') then
   raise exception 'Anonymous access to social content is not allowed';
 end if;
end $$;
reset role;

set role authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000001',false);
insert into public.social_profiles (user_id,display_name,city,sports)
values ('10000000-0000-4000-8000-000000000001','Atleta Uno','Querétaro',array['Running']);
insert into public.community_posts (author_id,sport,body)
values ('10000000-0000-4000-8000-000000000001','Running','Hoy hice una ruta de cinco kilometros');

select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000002',false);
insert into public.social_profiles(user_id,display_name,city,sports)
values ('10000000-0000-4000-8000-000000000002','Atleta Dos','Querétaro',array['Pesas']);
do $$
declare c integer;
begin
 select count(*) into c from public.community_posts;
 if c <> 1 then raise exception 'Second signed-in user cannot read community post'; end if;
 if exists(select 1 from app_private.dating_profiles where false) then null; end if;
exception when insufficient_privilege then
 -- Private tables intentionally deny SELECT; if this block catches it, keep testing.
 null;
end $$;

-- Posting as a different author must fail.
do $$
begin
  begin
    insert into public.community_posts(author_id,sport,body)
    values('10000000-0000-4000-8000-000000000001','Pesas','Intento de suplantacion');
    raise exception 'Author spoofing accepted' using errcode='P0001';
  exception when insufficient_privilege then null;
  end;
end $$;

-- Without an approval, a normal user cannot create an event.
do $$
begin
 begin
  insert into public.sport_events(organizer_id,title,description,sport,city,starts_at)
  values('10000000-0000-4000-8000-000000000002','Running grupal',
         'Una actividad deportiva de demostracion','Running','Querétaro',now()+interval '2 days');
  raise exception 'Unapproved organizer accepted' using errcode='P0001';
 exception when insufficient_privilege then null;
 end;
end $$;
reset role;

-- Only a privileged administrator can add an organizer.
insert into app_private.event_organizers(user_id)
values ('10000000-0000-4000-8000-000000000001');

set role authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000001',false);
insert into public.sport_events(organizer_id,title,description,sport,city,starts_at)
values('10000000-0000-4000-8000-000000000001','Running social',
       'Trote ligero y cafe en un lugar publico','Running','Querétaro',now()+interval '2 days');

select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000002',false);
insert into public.event_rsvps(event_id,user_id)
select id,'10000000-0000-4000-8000-000000000002'
from public.sport_events where title='Running social';
do $$
begin
 if (select count(*) from public.event_rsvps) <> 1 then
  raise exception 'Participant cannot see own RSVP';
 end if;
 if has_table_privilege(current_user,'app_private.event_organizers','SELECT') then
  raise exception 'Organizer grants leaked';
 end if;
end $$;

select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000001',false);
do $$
begin
 if exists(select 1 from public.event_rsvps) then
  raise exception 'Private RSVP leaked to organizer';
 end if;
 if exists(select 1 from public.community_posts where author_id='10000000-0000-4000-8000-000000000002') then
  raise exception 'Foreign post unexpectedly created';
 end if;
end $$;

select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000002',false);
do $$
begin
 begin
  delete from public.community_posts
  where author_id='10000000-0000-4000-8000-000000000001';
  if not exists(select 1 from public.community_posts where author_id='10000000-0000-4000-8000-000000000001') then
   raise exception 'Foreign post removed' using errcode='P0001';
  end if;
 exception when sqlstate 'P0001' then raise;
 end;
end $$;

delete from public.event_rsvps
where user_id='10000000-0000-4000-8000-000000000002';
do $$
begin
 if exists(select 1 from public.event_rsvps) then
  raise exception 'Own RSVP was not removed';
 end if;
end $$;
reset role;
