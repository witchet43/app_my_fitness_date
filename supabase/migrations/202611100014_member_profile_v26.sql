-- My Fitness Date V26: owner-only 360° profile, private training and media.
-- NOT a public discovery or romantic matching release. Apply only to MFD PROD
-- with explicit production approval and post-migration advisor/RLS verification.
-- This file is part of ONE coordinated release, not a migration for MUV PROD.
--
-- Every table in exposed public schema: explicit grants + owner-only RLS.
-- The legacy public.social_profiles has broader read visibility, so DO NOT
-- place date of birth, detailed profile, venues, photos or consent there.

create table public.member_profiles_v26 (
  user_id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default '' check (char_length(display_name) <= 60),
  date_of_birth date check (date_of_birth between date '1900-01-01' and current_date),
  city text not null default '' check (char_length(city) <= 100),
  about_me text not null default '' check (char_length(about_me) <= 1200),
  headline text not null default '' check (char_length(headline) <= 160),
  occupation text not null default '' check (char_length(occupation) <= 100),
  languages text[] not null default '{}'::text[] check (cardinality(languages) <= 8),
  hobbies text[] not null default '{}'::text[] check (cardinality(hobbies) <= 18),
  life_values text[] not null default '{}'::text[] check (cardinality(life_values) <= 12),
  prompts jsonb not null default '[]'::jsonb check (
    jsonb_typeof(prompts) = 'array' and jsonb_array_length(prompts) <= 3
    and pg_column_size(prompts) <= 2048
  ),
  sports text[] not null default '{}'::text[] check (cardinality(sports) <= 16),
  fitness_goals text[] not null default '{}'::text[] check (cardinality(fitness_goals) <= 10),
  achievements text[] not null default '{}'::text[] check (cardinality(achievements) <= 16),
  training_frequency text check (training_frequency is null or training_frequency in (
    'starting','one_to_two','three_to_four','five_plus','flexible'
  )),
  dating_intent text check (dating_intent is null or dating_intent in (
    'unknown','relationship','companionship','open_to_explore'
  )),
  social_visibility text not null default 'private' check (social_visibility in ('private','members')),
  onboarding_complete boolean not null default false,
  updated_at timestamptz not null default now()
);
alter table public.member_profiles_v26 enable row level security;
revoke all on public.member_profiles_v26 from public, anon, authenticated;
grant select, insert, update, delete on public.member_profiles_v26 to authenticated;
create policy v26_profile_read_own on public.member_profiles_v26 for select
  to authenticated using ((select auth.uid()) = user_id);
create policy v26_profile_insert_own on public.member_profiles_v26 for insert
  to authenticated with check ((select auth.uid()) = user_id);
create policy v26_profile_update_own on public.member_profiles_v26 for update
  to authenticated using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);
create policy v26_profile_delete_own on public.member_profiles_v26 for delete
  to authenticated using ((select auth.uid()) = user_id);

-- Exact venues, training areas and scheduled attendance are NEVER included
-- in any social or dating projection. No coordinates or live attendance.
create table public.member_training_places_v26 (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  venue_kind text not null check (venue_kind in (
    'gym','studio','running_club','park','box','other'
  )),
  place_name text not null check (char_length(btrim(place_name)) between 2 and 110),
  city text not null check (char_length(btrim(city)) between 2 and 100),
  general_zone text not null default '' check (char_length(general_zone) <= 70),
  is_favorite boolean not null default false,
  created_at timestamptz not null default now()
);
create index member_training_places_v26_owner on
  public.member_training_places_v26 (user_id, created_at desc);
alter table public.member_training_places_v26 enable row level security;
revoke all on public.member_training_places_v26 from public, anon, authenticated;
grant select, insert, update, delete on public.member_training_places_v26 to authenticated;
create policy v26_place_read_own on public.member_training_places_v26 for select
  to authenticated using ((select auth.uid()) = user_id);
create policy v26_place_insert_own on public.member_training_places_v26 for insert
  to authenticated with check ((select auth.uid()) = user_id);
create policy v26_place_update_own on public.member_training_places_v26 for update
  to authenticated using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);
create policy v26_place_delete_own on public.member_training_places_v26 for delete
  to authenticated using ((select auth.uid()) = user_id);

-- Immutable consent events. No client UPDATE / DELETE: audit cannot be forged.
-- This is not a substitute for legal review or external adult verification.
create table public.member_consents_v26 (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  consent_kind text not null check (consent_kind in ('terms','privacy','community','dating')),
  document_version text not null check (char_length(document_version) between 1 and 50),
  accepted_at timestamptz not null default now(),
  source text not null default 'member_onboarding'
    check (source in ('member_onboarding','profile_settings'))
);
create index member_consents_v26_owner on
  public.member_consents_v26 (user_id, consent_kind, accepted_at desc);
alter table public.member_consents_v26 enable row level security;
revoke all on public.member_consents_v26 from public, anon, authenticated;
grant select on public.member_consents_v26 to authenticated;
grant insert (user_id, consent_kind, document_version, source)
  on public.member_consents_v26 to authenticated;
create policy v26_consent_read_own on public.member_consents_v26 for select
  to authenticated using ((select auth.uid()) = user_id);
create policy v26_consent_insert_own on public.member_consents_v26 for insert
  to authenticated with check ((select auth.uid()) = user_id);

-- Photo metadata is self-only; moderation_state cannot be modified by members.
-- Even approved photos have NO public read policy in this release.
create table public.member_media_v26 (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  object_key text not null unique check (
    char_length(object_key) between 40 and 220
  ),
  alt_text text not null default '' check (char_length(alt_text) <= 240),
  position smallint not null default 0 check (position between 0 and 8),
  moderation_state text not null default 'pending' check (
    moderation_state in ('pending','approved','rejected')
  ),
  created_at timestamptz not null default now()
);
create index member_media_v26_owner on public.member_media_v26 (user_id, position);
alter table public.member_media_v26 enable row level security;
revoke all on public.member_media_v26 from public, anon, authenticated;
grant select on public.member_media_v26 to authenticated;
grant insert (user_id, object_key, alt_text, position)
  on public.member_media_v26 to authenticated;
grant update (alt_text, position) on public.member_media_v26 to authenticated;
grant delete on public.member_media_v26 to authenticated;
create policy v26_media_read_own on public.member_media_v26 for select
  to authenticated using ((select auth.uid()) = user_id);
create policy v26_media_insert_own on public.member_media_v26 for insert
  to authenticated with check (
    (select auth.uid()) = user_id
    and left(object_key, 37) = user_id::text || '/'
  );
create policy v26_media_update_own on public.member_media_v26 for update
  to authenticated using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);
create policy v26_media_delete_own on public.member_media_v26 for delete
  to authenticated using ((select auth.uid()) = user_id);

-- Storage bucket: private and owner-scoped, 5 MiB/file, restricted MIME.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('mfd-profile-private', 'mfd-profile-private', false, 5242880,
        array['image/jpeg','image/png']::text[])
on conflict (id) do nothing;

create policy mfd_v26_storage_read_own on storage.objects for select
  to authenticated
  using (bucket_id = 'mfd-profile-private'
    and (storage.foldername(name))[1] = (select auth.uid())::text);
create policy mfd_v26_storage_insert_own on storage.objects for insert
  to authenticated
  with check (bucket_id = 'mfd-profile-private'
    and (storage.foldername(name))[1] = (select auth.uid())::text);
create policy mfd_v26_storage_delete_own on storage.objects for delete
  to authenticated
  using (bucket_id = 'mfd-profile-private'
    and (storage.foldername(name))[1] = (select auth.uid())::text);

-- Deliberately no public discovery view, no anonymous SELECT,
-- no social feed exposure, no photo publication, no dating activation.
