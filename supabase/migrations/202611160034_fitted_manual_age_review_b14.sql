-- FITTED B14: direct privacy-preserving manual government ID review.
-- Never infer a verified age from a user-supplied birthdate or file upload.
-- No external face recognition, biometrics extraction, or document numbers stored.
begin;
create table app_private.age_review_requests_b14(
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references auth.users(id) on delete cascade,
 status text not null default 'draft' check(status in ('draft','pending','approved','rejected','cancelled')),
 consent_version text not null default 'age-proof-v1',
 consented_at timestamptz not null default now(),
 created_at timestamptz not null default now(),
 submitted_at timestamptz,
 reviewed_at timestamptz,
 reviewer_id uuid references auth.users(id) on delete set null,
 reason text,
 evidence_purged_at timestamptz
);
create index age_review_queue_idx_b14 on app_private.age_review_requests_b14(status,submitted_at);
create index age_review_owner_idx_b14 on app_private.age_review_requests_b14(user_id,created_at desc);
create unique index age_review_open_only_b14 on app_private.age_review_requests_b14(user_id)
 where status in ('draft','pending');
alter table app_private.age_review_requests_b14 enable row level security;
revoke all on app_private.age_review_requests_b14 from public,anon,authenticated;

create table app_private.age_review_audit_b14(
 id uuid primary key default gen_random_uuid(),
 request_id uuid not null references app_private.age_review_requests_b14(id) on delete cascade,
 reviewer_id uuid references auth.users(id) on delete set null,
 decision text not null check(decision in ('approved','rejected','cancelled')),
 verified_age_at_review integer,
 document_valid boolean,
 photo_match boolean,
 checked_at timestamptz not null default now(),
 reason text not null
);
create index age_review_audit_req_idx_b14 on app_private.age_review_audit_b14(request_id,checked_at);
alter table app_private.age_review_audit_b14 enable row level security;
revoke all on app_private.age_review_audit_b14 from public,anon,authenticated;

-- A private bucket: MIME and size constrained server-side, no signed public URL.
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('mfd-age-proof','mfd-age-proof',false,5242880,array['image/jpeg','image/png']::text[])
on conflict(id) do update set public=false,file_size_limit=5242880,
 allowed_mime_types=array['image/jpeg','image/png']::text[];

-- Only the document owner can upload/replace during a fresh draft.
create function app_private.age_can_upload_b14(p_path text)
returns boolean language sql stable security definer set search_path=''
as $$
 select auth.uid() is not null
  and p_path ~ ('^' || auth.uid()::text || '/[0-9a-f-]{36}/(document|selfie)$')
  and exists(select 1 from app_private.age_review_requests_b14 r
    where r.user_id=auth.uid() and r.status='draft'
      and r.created_at>now()-interval '90 minutes'
      and p_path=any(array[
        auth.uid()::text||'/'||r.id::text||'/document',
        auth.uid()::text||'/'||r.id::text||'/selfie'
      ]));
$$;
revoke all on function app_private.age_can_upload_b14(text) from public,anon;
grant execute on function app_private.age_can_upload_b14(text) to authenticated;

create policy mfd_age_owner_insert_b14 on storage.objects
for insert to authenticated
with check(bucket_id='mfd-age-proof' and app_private.age_can_upload_b14(name));
create policy mfd_age_owner_read_draft_or_admin_b14 on storage.objects
for select to authenticated
using(bucket_id='mfd-age-proof' and (
 app_private.age_can_upload_b14(name)
 or app_private.is_brand_administrator(true)
));
create policy mfd_age_owner_update_draft_b14 on storage.objects
for update to authenticated
using(bucket_id='mfd-age-proof' and app_private.age_can_upload_b14(name))
with check(bucket_id='mfd-age-proof' and app_private.age_can_upload_b14(name));
create policy mfd_age_delete_withdrawn_or_admin_b14 on storage.objects
for delete to authenticated
using(bucket_id='mfd-age-proof' and (
 app_private.is_brand_administrator(true)
 or (auth.uid() is not null and
     name like auth.uid()::text||'/%' and
     exists(select 1 from app_private.age_review_requests_b14 r
      where name like auth.uid()::text||'/'||r.id::text||'/%'
        and r.user_id=auth.uid() and r.status in ('draft','cancelled','rejected')))
));

create function public.age_start_review_b14(p_consent boolean)
returns jsonb language plpgsql security definer set search_path=''
as $$
declare me uuid:=auth.uid(); id_value uuid; existing text; 
begin
 if p_consent is distinct from true then
    return jsonb_build_object('status','consent_required'); end if;
 if me is null or coalesce(auth.jwt()->>'is_anonymous','false')='true'
   or not app_private.account_is_active(me)
   or exists(select 1 from app_private.brand_administrators a where a.user_id=me and a.active)
   or not exists(select 1 from auth.users u where u.id=me and u.email_confirmed_at is not null)
 then return jsonb_build_object('status','not_available'); end if;
 if not exists(select 1 from public.member_profiles_v26 p where p.user_id=me
   and p.onboarding_complete and p.date_of_birth<=(current_date-interval '18 years')::date)
 then return jsonb_build_object('status','profile_required'); end if;
 if app_private.adult_eligible(me) then
   return jsonb_build_object('status','approved'); end if;
 select r.id,r.status into id_value,existing
   from app_private.age_review_requests_b14 r
   where r.user_id=me and r.status in ('draft','pending')
   order by r.created_at desc limit 1;
 if id_value is not null then 
   if existing='draft' and exists(select 1 from app_private.age_review_requests_b14 r
     where r.id=id_value and r.created_at<=now()-interval '90 minutes') then
     update app_private.age_review_requests_b14 set status='cancelled' where id=id_value;
   else
     return jsonb_build_object('status',existing,'request_id',id_value);
   end if;
 end if;
 if (select count(*) from app_private.age_review_requests_b14 r
       where r.user_id=me and r.created_at>now()-interval '30 days')>=3 then
   return jsonb_build_object('status','rate_limited');
 end if;
 insert into app_private.age_review_requests_b14(user_id)
 values(me) returning id into id_value;
 return jsonb_build_object('status','draft','request_id',id_value);
end;
$$;

create function public.age_review_status_b14()
returns jsonb language plpgsql security definer set search_path=''
as $$
declare me uuid:=auth.uid(); r app_private.age_review_requests_b14%rowtype;
begin
 if me is null then return jsonb_build_object('status','not_available'); end if;
 select * into r from app_private.age_review_requests_b14
   where user_id=me order by created_at desc limit 1;
 return jsonb_build_object(
  'status',case when app_private.adult_eligible(me) then 'approved'
           else coalesce(r.status,'not_started') end,
  'request_id',r.id,
  'submitted_at',r.submitted_at,
  'approved',app_private.adult_eligible(me));
end;
$$;

create function public.age_submit_review_b14(p_request uuid)
returns text language plpgsql security definer set search_path=''
as $$
declare me uuid:=auth.uid(); proof_count integer; image_count integer;
begin
 if me is null or p_request is null then return 'not_available'; end if;
 if not exists(select 1 from app_private.age_review_requests_b14 r
      where r.id=p_request and r.user_id=me and r.status='draft'
      and r.consented_at is not null and
      r.created_at>now()-interval '90 minutes') then return 'not_available'; end if;
 select count(*),count(*) filter (where metadata->>'mimetype' in ('image/jpeg','image/png')
   and (metadata->>'size')::bigint<=5242880)
   into proof_count,image_count
   from storage.objects
   where bucket_id='mfd-age-proof'
     and name in (me::text||'/'||p_request::text||'/document',
                  me::text||'/'||p_request::text||'/selfie');
 if proof_count<>2 or image_count<>2 then return 'documents_required'; end if;
 update app_private.age_review_requests_b14
 set status='pending',submitted_at=now() where id=p_request and user_id=me;
 return 'pending';
end;
$$;

create function public.age_cancel_review_b14()
returns text language plpgsql security definer set search_path=''
as $$
declare me uuid:=auth.uid(); r_id uuid;
begin
 if me is null then return 'not_available'; end if;
 update app_private.age_review_requests_b14
 set status='cancelled'
 where user_id=me and status in ('draft','pending','approved','rejected')
 returning id into r_id;
 update app_private.adult_eligibility set revoked_at=now()
   where user_id=me and revoked_at is null;
 update app_private.dating_profiles
   set dating_enabled=false,updated_at=now() where user_id=me;
 return 'withdrawn';
end;
$$;

create function public.admin_age_queue_b14()
returns table(request_id uuid,user_id uuid,display_name text,
 declared_birthdate date,submitted_at timestamptz,document_path text,selfie_path text)
language sql stable security definer set search_path=''
as $$
 select r.id,r.user_id,p.display_name,p.date_of_birth,r.submitted_at,
 r.user_id::text||'/'||r.id::text||'/document',
 r.user_id::text||'/'||r.id::text||'/selfie'
 from app_private.age_review_requests_b14 r
 join public.member_profiles_v26 p on p.user_id=r.user_id
 where app_private.is_brand_administrator(true) and r.status='pending'
 order by r.submitted_at asc limit 50;
$$;

create function public.admin_age_decide_b14(
 p_request uuid,p_decision text,p_document_birthdate date,p_document_valid boolean,
 p_photo_match boolean,p_document_expiry date,p_note text)
returns text language plpgsql security definer set search_path=''
as $$
declare me uuid:=auth.uid(); req app_private.age_review_requests_b14%rowtype;
 declared date; expected_age integer; expires timestamptz;
begin
 if not app_private.is_brand_administrator(true) then return 'forbidden'; end if;
 if p_request is null or p_decision not in ('approved','rejected')
   or p_note is null or char_length(btrim(p_note)) not between 10 and 500
 then return 'invalid'; end if;
 select * into req from app_private.age_review_requests_b14
    where id=p_request for update;
 if req.id is null or req.status<>'pending' or req.user_id=me
   or req.submitted_at<now()-interval '14 days' then return 'not_available'; end if;
 select p.date_of_birth into declared from public.member_profiles_v26 p
    where p.user_id=req.user_id;
 if p_decision='approved' then
   if p_document_birthdate is null or p_document_valid is distinct from true
     or p_photo_match is distinct from true
     or declared is null or declared<>p_document_birthdate
     or p_document_birthdate>(current_date-interval '18 years')::date
     or p_document_birthdate<(current_date-interval '110 years')::date
     or (p_document_expiry is not null and p_document_expiry<=current_date)
     or not exists(select 1 from storage.objects o where o.bucket_id='mfd-age-proof'
       and o.name=req.user_id::text||'/'||req.id::text||'/document')
     or not exists(select 1 from storage.objects o where o.bucket_id='mfd-age-proof'
       and o.name=req.user_id::text||'/'||req.id::text||'/selfie')
   then return 'verification_failed'; end if;
   expires:=least(now()+interval '90 days',
         coalesce(p_document_expiry::timestamptz,now()+interval '90 days'));
   if expires<=now() then return 'verification_failed'; end if;
   -- The legacy restricted operator function does not trust member self-claims.
   perform app_private.operator_set_adult_eligibility(req.user_id,
       'manual-age-v14:'||req.id::text,expires,true);
 else
   update app_private.adult_eligibility set revoked_at=now() where user_id=req.user_id;
   update app_private.dating_profiles set dating_enabled=false,updated_at=now()
     where user_id=req.user_id;
 end if;
 expected_age:=case when p_document_birthdate is null then null
   else date_part('year',age(current_date,p_document_birthdate))::integer end;
 update app_private.age_review_requests_b14
   set status=p_decision,reviewed_at=now(),reviewer_id=me,reason=btrim(p_note)
   where id=req.id;
 insert into app_private.age_review_audit_b14(
   request_id,reviewer_id,decision,verified_age_at_review,document_valid,photo_match,reason)
 values(req.id,me,p_decision,case when p_decision='approved' then expected_age else null end,
    p_document_valid,p_photo_match,btrim(p_note));
 return p_decision;
end;
$$;

create function public.admin_age_mark_erased_b14(p_request uuid)
returns text language plpgsql security definer set search_path=''
as $$
declare r app_private.age_review_requests_b14%rowtype;
begin
 if not app_private.is_brand_administrator(true) then return 'forbidden'; end if;
 select * into r from app_private.age_review_requests_b14 where id=p_request;
 if r.id is null or r.status not in ('approved','rejected','cancelled')
 then return 'not_available'; end if;
 if exists(select 1 from storage.objects o where o.bucket_id='mfd-age-proof'
    and o.name like r.user_id::text||'/'||r.id::text||'/%')
 then return 'evidence_not_erased'; end if;
 update app_private.age_review_requests_b14 set evidence_purged_at=now() where id=r.id;
 return 'erased';
end;
$$;


-- Revisit failed or deferred evidence erasure without exposing image data.
create function public.admin_age_erasure_queue_b14()
returns table(request_id uuid,user_id uuid,case_status text,
 document_path text,selfie_path text,reviewed_at timestamptz)
language sql stable security definer set search_path=''
as $$
 select r.id,r.user_id,r.status,
 r.user_id::text||'/'||r.id::text||'/document',
 r.user_id::text||'/'||r.id::text||'/selfie',r.reviewed_at
 from app_private.age_review_requests_b14 r
 where app_private.is_brand_administrator(true)
   and r.status in ('approved','rejected','cancelled')
   and r.evidence_purged_at is null
 order by coalesce(r.reviewed_at,r.created_at) asc limit 50;
$$;

create table app_private.manual_dating_launch_b14 (
 id boolean primary key default true check(id),
 enabled boolean not null default false,
 activated_by uuid references auth.users(id) on delete set null,
 activated_at timestamptz,
 disabled_at timestamptz,
 operator_ack boolean not null default false,
 privacy_ack boolean not null default false,
 incident_ack boolean not null default false,
 declared_responsibility text not null default ''
);
insert into app_private.manual_dating_launch_b14(id) values(true);
alter table app_private.manual_dating_launch_b14 enable row level security;
revoke all on app_private.manual_dating_launch_b14 from public,anon,authenticated;

create function app_private.manual_dating_live_b14()
returns boolean language sql stable security definer set search_path=''
as $$
 select coalesce((select enabled and operator_ack and privacy_ack and incident_ack
     and activated_by is not null
     and exists(select 1 from app_private.brand_administrators a
        where a.user_id=activated_by and a.active)
   from app_private.manual_dating_launch_b14 where id),false);
$$;
revoke all on function app_private.manual_dating_live_b14() from public,anon;

create function public.admin_dating_launch_b14(
 p_enabled boolean,p_operator_ack boolean,p_privacy_ack boolean,
 p_incident_ack boolean,p_responsibility text)
returns text language plpgsql security definer set search_path=''
as $$
declare me uuid:=auth.uid();
begin
 if not app_private.is_brand_administrator(true) then return 'forbidden'; end if;
 if p_enabled is null then return 'invalid'; end if;
 if p_enabled then
   if p_operator_ack is distinct from true or p_privacy_ack is distinct from true
      or p_incident_ack is distinct from true
      or p_responsibility is null or char_length(btrim(p_responsibility)) not between 20 and 500
   then return 'acknowledgement_required'; end if;
 end if;
 update app_private.manual_dating_launch_b14
   set enabled=p_enabled,activated_by=case when p_enabled then me else activated_by end,
       activated_at=case when p_enabled then now() else activated_at end,
       disabled_at=case when p_enabled then null else now() end,
       operator_ack=p_enabled and coalesce(p_operator_ack,false),
       privacy_ack=p_enabled and coalesce(p_privacy_ack,false),
       incident_ack=p_enabled and coalesce(p_incident_ack,false),
       declared_responsibility=case when p_enabled then btrim(p_responsibility) else declared_responsibility end
   where id;
 return case when p_enabled then 'enabled' else 'disabled' end;
end;
$$;

create function public.dating_manual_status_b14()
returns jsonb language sql stable security definer set search_path=''
as $$
 select jsonb_build_object('enabled',app_private.manual_dating_live_b14(),
  'method','document_manual_review','requires_age_approval',true,
  'human_moderation',true,'public_reputation',false);
$$;

-- Public access remains denied by default until operator explicitly attests
-- and activates a staffed manual program. Every member still needs real review.
create or replace function app_private.b5_discovery_open()
returns boolean language sql stable security definer set search_path=''
as $$
 select app_private.manual_dating_live_b14() or coalesce((
    select g.independently_verified_provider_live
      and g.independent_verification_audit_approved
      and g.moderation_staffed and g.privacy_review_approved and g.release_approved
    from app_private.fitdating_gate_b5 g where g.id),false);
$$;

-- The legacy closed-pilot allowlist remains valid as an alternative for
-- future provider mode; manually verified public applicants need no invite.
create or replace function app_private.b11_activation_ready(p_id uuid)
returns boolean language sql stable security definer set search_path=''
as $$
 select p_id is not null and app_private.b5_discovery_open()
   and app_private.adult_eligible(p_id)
   and app_private.account_is_active(p_id)
   and exists(select 1 from auth.users u where u.id=p_id and u.email_confirmed_at is not null)
   and not exists(select 1 from app_private.brand_administrators a where a.user_id=p_id and a.active)
   and (app_private.manual_dating_live_b14() or exists(select 1 from app_private.community_pilot_b4 m
     where m.user_id=p_id and m.active))
   and exists(select 1 from app_private.fitdating_preferences_b5 p
     where p.user_id=p_id and p.participation_requested)
   and exists(select 1 from public.member_consents_v26 c where c.user_id=p_id
     and c.consent_kind='dating' and c.document_version='dating-v1')
   and exists(select 1 from public.member_profiles_v26 m where m.user_id=p_id
     and m.onboarding_complete and m.date_of_birth<=(current_date-interval '18 years')::date)
   and exists(select 1 from public.member_rhythm_b11 r where r.user_id=p_id)
   and not exists(select 1 from app_private.community_suspensions_b4 s where s.user_id=p_id and s.active)
   and not exists(select 1 from app_private.community_deletion_requests_b4 d where d.user_id=p_id);
$$;
create or replace function app_private.b11_member_eligible(p_id uuid)
returns boolean language sql stable security definer set search_path=''
as $$
 select p_id is not null and app_private.b5_discovery_open()
 and app_private.adult_eligible(p_id)
 and exists(select 1 from auth.users u where u.id=p_id and u.email_confirmed_at is not null)
 and not exists(select 1 from app_private.brand_administrators a where a.user_id=p_id and a.active)
 and (app_private.manual_dating_live_b14() or exists(select 1 from app_private.community_pilot_b4 a
   where a.user_id=p_id and a.active))
 and exists(select 1 from app_private.fitdating_preferences_b5 p
   where p.user_id=p_id and p.participation_requested)
 and exists(select 1 from app_private.dating_profiles p where p.user_id=p_id and p.dating_enabled)
 and exists(select 1 from public.member_rhythm_b11 r where r.user_id=p_id)
 and exists(select 1 from public.member_consents_v26 c where c.user_id=p_id
   and c.consent_kind='dating' and c.document_version='dating-v1')
 and not exists(select 1 from app_private.community_suspensions_b4 s where s.user_id=p_id and s.active)
 and not exists(select 1 from app_private.community_deletion_requests_b4 d where d.user_id=p_id)
 and not exists(select 1 from app_private.account_deletion_requests d where d.user_id=p_id);
$$;

revoke all on function public.age_start_review_b14(boolean),public.age_review_status_b14(),
 public.age_submit_review_b14(uuid),public.age_cancel_review_b14(),
 public.admin_age_queue_b14(),public.admin_age_decide_b14(uuid,text,date,boolean,boolean,date,text),
 public.admin_age_mark_erased_b14(uuid),public.admin_age_erasure_queue_b14(),
 public.admin_dating_launch_b14(boolean,boolean,boolean,boolean,text),
 public.dating_manual_status_b14()
 from public,anon,authenticated;
grant execute on function public.age_start_review_b14(boolean),public.age_review_status_b14(),
 public.age_submit_review_b14(uuid),public.age_cancel_review_b14(),
 public.admin_age_queue_b14(),public.admin_age_decide_b14(uuid,text,date,boolean,boolean,date,text),
 public.admin_age_mark_erased_b14(uuid),
 public.admin_dating_launch_b14(boolean,boolean,boolean,boolean,text),
 public.dating_manual_status_b14()
 to authenticated;
comment on table app_private.age_review_requests_b14 is
 'Confidential age evidence case. Human reviewer must inspect both ID and selfie. Never store document number or raw image here.';
commit;