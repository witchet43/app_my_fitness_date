-- Run after V7 tests; 4 users and social posts remain for checks.
set role anon;
do $$
begin
 if has_function_privilege(current_user,'public.my_account_export()','EXECUTE')
  or has_function_privilege(current_user,'public.request_account_deletion()','EXECUTE')
  or has_schema_privilege(current_user,'app_private','USAGE') then
  raise exception 'Anonymous privacy API access';
 end if;
end $$;
reset role;

set role authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000001',false);
do $$
declare v jsonb;
begin
 select public.my_account_export() into v;
 if v->'account'->>'id' is distinct from '10000000-0000-4000-8000-000000000001'
 or jsonb_array_length(v->'posts')<>1 then
  raise exception 'Own export incomplete or wrong owner: %',v;
 end if;
 if v->'account' ? 'encrypted_password' then
   raise exception 'Credential material in export';
 end if;
end $$;
select public.request_account_deletion();
do $$
declare v jsonb;
begin
 select public.my_account_status() into v;
 if v->>'pending'<>'true' or v->>'earliest_review_at' is null then
  raise exception 'Deletion request not retained';
 end if;
 if exists(select 1 from app_private.dating_profiles where false) then null; end if;
exception when insufficient_privilege then null;
end $$;
do $$
begin
 begin
  insert into public.community_posts(author_id,sport,body)
  values ('10000000-0000-4000-8000-000000000001','Running','Post after deletion request');
  raise exception 'Post allowed after deletion request' using errcode='P0002';
 exception when insufficient_privilege then null;
 end;
 begin
  perform * from public.discover_dating_candidates(1);
  raise exception 'Dating allowed after deletion request' using errcode='P0002';
 exception when sqlstate 'P0001' then
  if sqlerrm<>'ACCOUNT_DELETION_PENDING' then raise; end if;
 end;
end $$;
reset role;

-- Another unblocked signed-in account cannot see pending user's public profile.
set role authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000003',false);
do $$
begin
 if exists(select 1 from public.social_profiles
  where user_id='10000000-0000-4000-8000-000000000001') then
  raise exception 'Pending-deletion account visible';
 end if;
 if exists(select 1 from public.community_posts
  where author_id='10000000-0000-4000-8000-000000000001') then
  raise exception 'Pending-deletion post visible';
 end if;
 if (public.my_account_export()->'account'->>'id') is distinct from
   '10000000-0000-4000-8000-000000000003' then
  raise exception 'Another account can export foreign profile';
 end if;
end $$;
reset role;

-- Pending request may be cancelled: old posts become visible, Dating stays opt-out.
set role authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000001',false);
select public.cancel_account_deletion();
do $$
begin
 if (public.my_account_status()->>'pending')<>'false' then
  raise exception 'Cancellation did not work';
 end if;
end $$;
reset role;

set role authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000003',false);
do $$
begin
 if not exists(select 1 from public.social_profiles
  where user_id='10000000-0000-4000-8000-000000000001') then
  raise exception 'Profile not restored after cancellation';
 end if;
end $$;
reset role;
