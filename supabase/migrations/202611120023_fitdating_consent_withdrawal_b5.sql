-- B5 consent withdrawal: disabling FitDating also withdraws active consent.
-- The private audit records withdrawal without re-exposing the consent to
-- discovery. Members must consent again before requesting participation.
begin;
create table app_private.fitdating_consent_withdrawals_b5(
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  withdrawn_at timestamptz not null default now(),
  document_version text not null default 'dating-v1'
);
alter table app_private.fitdating_consent_withdrawals_b5 enable row level security;
revoke all on app_private.fitdating_consent_withdrawals_b5
  from public,anon,authenticated;

create or replace function public.fitdating_disable_b5()
returns text
language plpgsql security definer set search_path=''
as $$
declare
  v_user uuid := (select auth.uid());
  v_deleted integer := 0;
begin
  if v_user is null or coalesce(auth.jwt()->>'is_anonymous','false')='true'
  then return 'forbidden'; end if;
  update app_private.fitdating_preferences_b5
    set participation_requested=false,updated_at=now()
    where user_id=v_user;
  update app_private.dating_profiles
    set dating_enabled=false,updated_at=now()
    where user_id=v_user;
  delete from public.member_consents_v26
    where user_id=v_user and consent_kind='dating';
  get diagnostics v_deleted = row_count;
  if v_deleted>0 then
    insert into app_private.fitdating_consent_withdrawals_b5(
      user_id,document_version)
    values(v_user,'dating-v1');
  end if;
  return 'disabled';
end;
$$;
revoke all on function public.fitdating_disable_b5()
  from public,anon,authenticated;
grant execute on function public.fitdating_disable_b5()
  to authenticated;
commit;
