-- B18: only a candidate actually returned by the existing B11 safety gate
-- can have their explicitly-shared biography and approved profile photograph read.
begin;
create table if not exists app_private.member_profile_summaries_b17(
  user_id uuid primary key references auth.users(id) on delete cascade,
  summary_es text not null default '',
  summary_en text not null default '',
  summary_mode text not null default 'manual',
  ai_consented boolean not null default false,
  ai_consented_at timestamptz,
  share_consented boolean not null default false,
  manual_summary_es text not null default '',
  manual_summary_en text not null default '',
  updated_at timestamptz not null default now()
);
create or replace function public.fitted_candidate_showcase_b18(p_user uuid)
returns jsonb language plpgsql stable security definer set search_path=''
as $fn$
declare viewer uuid:=auth.uid(); result jsonb; own_photo text;
begin
 if viewer is null or p_user is null or viewer=p_user
    or not app_private.b11_member_eligible(viewer)
    or not app_private.b11_member_eligible(p_user)
    or not exists (
      select 1 from app_private.b11_candidates(25) c where c.user_id=p_user
    )
 then return jsonb_build_object('available',false); end if;
 select jsonb_build_object(
   'available',true,
   'summary_es',left(coalesce(s.summary_es,''),560),
   'summary_en',left(coalesce(s.summary_en,''),560),
   'photo_key',(
       select m.object_key from public.member_media_v26 m
       where m.user_id=p_user and m.position=0
         and m.moderation_state='approved'
         and app_private.fitted_photo_viewable_b17(m.object_key)
       limit 1
   )
 ) into result
 from app_private.member_profile_summaries_b17 s
 join public.member_profiles_v26 p on p.user_id=s.user_id
 where s.user_id=p_user and s.share_consented
   and p.social_visibility='members';
 return coalesce(result,jsonb_build_object('available',false));
end;
$fn$;
revoke all on function public.fitted_candidate_showcase_b18(uuid)
 from public,anon,authenticated;
grant execute on function public.fitted_candidate_showcase_b18(uuid)
 to authenticated;
comment on function public.fitted_candidate_showcase_b18(uuid) is
 'Only eligible in-feed candidates; owner consent; approved photo; private gym/venue/schedule never returned';
commit;