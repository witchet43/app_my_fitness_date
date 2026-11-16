-- Fitted B14 secured happy-path test. EPHEMERAL POSTGRES ONLY.
-- Never apply this file to hosted Supabase: synthetic users and ID images.
begin;
insert into auth.users(id,email,email_confirmed_at) values
 ('00000000-0000-4000-8000-0000000014ad','age-owner@example.invalid',now()),
 ('00000000-0000-4000-8000-0000000014a1','verified-applicant@example.invalid',now());
insert into app_private.brand_administrators(user_id,role)
values('00000000-0000-4000-8000-0000000014ad','owner');
insert into public.member_profiles_v26(
 user_id,display_name,city,date_of_birth,onboarding_complete)
values('00000000-0000-4000-8000-0000000014a1',
 'QA Applicant','Querétaro',date '1991-05-13',true);

-- Member consent must be a direct opt-in and no upload can grant age.
set role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-0000000014a1',false);
select set_config('request.jwt.claims','{"aal":"aal1"}',false);
do $v$
declare r jsonb;
begin
 r:=public.age_start_review_b14(false);
 if r->>'status'<>'consent_required' then raise exception 'Consent bypass'; end if;
 r:=public.age_start_review_b14(true);
 if r->>'status'<>'draft' then raise exception 'Failed to start review: %',r; end if;
 if public.age_submit_review_b14((r->>'request_id')::uuid)
   <>'documents_required' then raise exception 'Missing photos accepted'; end if;
 if public.admin_age_decide_b14(
   (r->>'request_id')::uuid,'approved',date '1991-05-13',
   true,true,null,'Fake member approval')<>'forbidden'
 then raise exception 'User self-approved their age'; end if;
 if public.dating_manual_status_b14()->>'enabled'<>'false'
 then raise exception 'Matching opened before operator'; end if;
end;
$v$;
reset role;

-- Emulate TWO authenticated Storage API uploads in disposable CI only.
insert into storage.objects(bucket_id,name,owner_id,metadata)
select 'mfd-age-proof',r.user_id::text||'/'||r.id::text||'/document',
 r.user_id::text,'{"mimetype":"image/jpeg","size":23000}'::jsonb
from app_private.age_review_requests_b14 r
where r.user_id='00000000-0000-4000-8000-0000000014a1';
insert into storage.objects(bucket_id,name,owner_id,metadata)
select 'mfd-age-proof',r.user_id::text||'/'||r.id::text||'/selfie',
 r.user_id::text,'{"mimetype":"image/jpeg","size":20000}'::jsonb
from app_private.age_review_requests_b14 r
where r.user_id='00000000-0000-4000-8000-0000000014a1';

set role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-0000000014a1',false);
select set_config('request.jwt.claims','{"aal":"aal1"}',false);
do $v$
declare id_value uuid;
begin
 id_value:=(public.age_review_status_b14()->>'request_id')::uuid;
 if public.age_submit_review_b14(id_value)<>'pending' then
    raise exception 'Valid evidence not submitted'; end if;
 if (public.age_review_status_b14()->>'status')<>'pending' then
    raise exception 'Pending review state missing'; end if;
 if app_private.adult_eligible(auth.uid()) then
    raise exception 'Unreviewed documents granted age'; end if;
end;
$v$;
reset role;

-- Administrator AAL1 cannot approve; AAL2 must inspect both proofs and DOB.
set role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-0000000014ad',false);
select set_config('request.jwt.claims','{"aal":"aal1"}',false);
do $v$
declare id_value uuid;
begin
 select r.id into id_value from app_private.age_review_requests_b14 r
 where r.user_id='00000000-0000-4000-8000-0000000014a1';
 if public.admin_age_decide_b14(id_value,'approved',
   date '1991-05-13',true,true,null,
   'Operator AAL1 does not have authority')<>'forbidden'
 then raise exception 'AAL1 admin approved applicant'; end if;
end;
$v$;
select set_config('request.jwt.claims','{"aal":"aal2"}',false);
do $v$
declare id_value uuid; decision text;
begin
 select r.id into id_value from app_private.age_review_requests_b14 r
 where r.user_id='00000000-0000-4000-8000-0000000014a1';
 if public.admin_age_decide_b14(id_value,'approved',
   date '2008-09-20',true,true,null,
   'The date in the document differs from profile')<>'verification_failed'
 then raise exception 'DOB mismatch was approved'; end if;
 decision:=public.admin_age_decide_b14(id_value,'approved',
   date '1991-05-13',true,true,null,
   'Human inspection of ID, DOB, portrait, validity and consent done');
 if decision<>'approved' then raise exception 'Valid ID review failed: %',decision; end if;
 if not app_private.adult_eligible('00000000-0000-4000-8000-0000000014a1')
 then raise exception 'Approved age record missing'; end if;
 if app_private.b5_discovery_open() then
   raise exception 'Single age approval released all dating'; end if;
 if public.admin_dating_launch_b14(true,true,false,true,
   'QA operator explicit operator and privacy declaration')<>'acknowledgement_required'
 then raise exception 'Privacy declaration was not required'; end if;
 if public.admin_dating_launch_b14(true,true,true,true,
    'QA LOCAL ONLY: a human operator is assigned to review age and moderation')<>'enabled'
 then raise exception 'Reviewed-adult program not activated'; end if;
 if not app_private.b5_discovery_open() then
   raise exception 'Admin attestation could not activate verified-only matching'; end if;
 if (select count(*) from public.admin_age_erasure_queue_b14())<>1 then
   raise exception 'Approved ID evidence must be queued for deletion'; end if;
end;
$v$;
reset role;

-- Mimic Storage API erasure (only in disposable CI) and record its verification.
delete from storage.objects where bucket_id='mfd-age-proof'
 and name like '00000000-0000-4000-8000-0000000014a1/%';
set role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-0000000014ad',false);
select set_config('request.jwt.claims','{"aal":"aal2"}',false);
do $v$
declare id_value uuid;
begin
 select r.id into id_value from app_private.age_review_requests_b14 r
 where r.user_id='00000000-0000-4000-8000-0000000014a1';
 if public.admin_age_mark_erased_b14(id_value)<>'erased' then
   raise exception 'Document deletion acknowledgement failed'; end if;
 if (select count(*) from public.admin_age_erasure_queue_b14())<>0 then
   raise exception 'Erased evidence remained in deletion queue'; end if;
end;
$v$;
reset role;

-- Applicant withdrawal must immediately revoke age even when site is live.
set role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-0000000014a1',false);
select set_config('request.jwt.claims','{"aal":"aal1"}',false);
do $v$
begin
 if (public.age_review_status_b14()->>'approved')::boolean is distinct from true
 then raise exception 'Applicant cannot see own approval'; end if;
 if public.age_cancel_review_b14()<>'withdrawn'
 then raise exception 'Member cannot withdraw age verification'; end if;
 if (public.age_review_status_b14()->>'approved')::boolean is distinct from false
 then raise exception 'Age eligibility remained valid after withdrawal'; end if;
 if app_private.adult_eligible(auth.uid()) then
    raise exception 'Revoked applicant remains eligible'; end if;
end;
$v$;
reset role;
rollback;