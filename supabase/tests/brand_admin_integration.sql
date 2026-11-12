-- Disposable CI integration test: admin isolation, MFA AAL2, private media.
-- This file is NEVER applied to hosted Supabase.
begin;

insert into auth.users(id,email,email_confirmed_at)
values
 ('00000000-0000-4000-8000-000000000e11','member-fixture@example.invalid',now()),
 ('00000000-0000-4000-8000-000000000e12','brand-admin-fixture@example.invalid',now())
on conflict(id) do nothing;

-- Simulate malicious misconfiguration: member UUID appears in admin membership.
-- The brand gate must still exclude them as a member.
insert into public.member_profiles_v26(user_id,display_name)
values('00000000-0000-4000-8000-000000000e11','Synthetic member')
on conflict(user_id) do nothing;
insert into app_private.brand_administrators(user_id,role)
values
 ('00000000-0000-4000-8000-000000000e11','owner'),
 ('00000000-0000-4000-8000-000000000e12','owner');

-- Schema and RLS coverage
do $$
declare r record;
begin
  for r in select unnest(array[
    'brand_palettes','brand_design_drafts','brand_design_revisions',
    'brand_assets','brand_release_requests'
  ]) as tab loop
    if not exists(select 1 from pg_tables p
      where p.schemaname='public' and p.tablename=r.tab and p.rowsecurity)
    then raise exception 'RLS disabled on %',r.tab; end if;
  end loop;
  if exists(select 1 from storage.buckets b
            where b.id='mfd-brand-drafts' and b.public)
  then raise exception 'Brand draft bucket must not be public'; end if;
end $$;

set role anon;
do $$
begin
  begin
    perform public.brand_admin_status();
    raise exception 'Anonymous unexpectedly invoked admin status';
  exception when insufficient_privilege then null;
  end;
end $$;
reset role;

-- No admin role means no permissions, even with spoofed AAL2 claims.
set role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000e99',false);
select set_config('request.jwt.claims','{"aal":"aal2"}',false);
do $$
begin
 if public.brand_admin_status() or public.brand_admin_session()
 then raise exception 'Unappointed account has admin access'; end if;
end $$;

-- A purported owner who is also a member remains DENIED.
select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000e11',false);
do $$
begin
 if public.brand_admin_status() or public.brand_admin_session()
 then raise exception 'Member identity gained Brand Admin access'; end if;
end $$;

-- Even a real appointed administrator is not authorized to write at AAL1.
select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000e12',false);
select set_config('request.jwt.claims','{"aal":"aal1"}',false);
do $$
begin
 if not public.brand_admin_status() then
    raise exception 'Previously appointed admin cannot enroll MFA'; end if;
 if public.brand_admin_session() then
    raise exception 'AAL1 session gained admin privileges'; end if;
 begin
  insert into public.brand_palettes(name,colors,created_by)
  values('Forbidden palette','{"primary":"#28463D","accent":"#B49A6A","background":"#F7F5F0"}',
   '00000000-0000-4000-8000-000000000e12');
  raise exception 'AAL1 successfully inserted private palette';
 exception when insufficient_privilege then null;
 end;
 begin
  insert into app_private.brand_administrators(user_id,role)
  values('00000000-0000-4000-8000-000000000e99','owner');
  raise exception 'Admin self-provisioning was allowed';
 exception when insufficient_privilege then null;
 end;
end $$;

-- Confirm actual AAL2 access and persistent revision history.
select set_config('request.jwt.claims','{"aal":"aal2"}',false);
do $$
begin
 if not public.brand_admin_session() then
   raise exception 'AAL2 admin account not authorized'; end if;
end $$;
insert into public.brand_palettes(name,colors,created_by)
values('Safe palette','{"primary":"#28463D","accent":"#B49A6A","background":"#F7F5F0"}',
  '00000000-0000-4000-8000-000000000e12');

insert into public.brand_design_drafts(id,title,settings,revision,created_by,updated_by)
values(
 '00000000-0000-4000-8000-000000000e13','Serious brand',
 '{"name":"My Fitness Date","colors":{"primary":"#28463D"}}',1,
 '00000000-0000-4000-8000-000000000e12',
 '00000000-0000-4000-8000-000000000e12'
);
update public.brand_design_drafts set
  revision=revision+1,settings='{"name":"Cadence","colors":{"primary":"#28463D"}}'
where id='00000000-0000-4000-8000-000000000e13';
do $$
begin
 if (select count(*) from public.brand_design_revisions
       where draft_id='00000000-0000-4000-8000-000000000e13')<>2
 then raise exception 'Immutable version history did not capture both saves'; end if;
end $$;

-- Public release endpoint only accepts pending review, not direct deployment.
do $$
begin
 begin
  insert into public.brand_release_requests(draft_id,revision,status,requested_by)
  values('00000000-0000-4000-8000-000000000e13',2,'deployed',
         '00000000-0000-4000-8000-000000000e12');
  raise exception 'Administrator bypassed publication workflow';
 exception when insufficient_privilege then null;
 end;
end $$;

-- Private object path must begin with currently authenticated admin UUID.
insert into storage.objects(bucket_id,name,owner_id)
values('mfd-brand-drafts',
 '00000000-0000-4000-8000-000000000e12/logo/demo.webp',
 '00000000-0000-4000-8000-000000000e12');
do $$
begin
 begin
   insert into storage.objects(bucket_id,name,owner_id)
   values('mfd-brand-drafts','other-user/logo/bypass.webp',
      '00000000-0000-4000-8000-000000000e12');
   raise exception 'Admin uploaded outside own folder';
 exception when insufficient_privilege then null;
 end;
end $$;

reset role;
rollback;
