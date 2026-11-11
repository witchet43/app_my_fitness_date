-- Minimal local CI shims for Supabase-specific database roles and auth.
-- These are test-only; NEVER execute against a managed Supabase project.
create role authenticated nologin;
create role anon nologin;
-- Mirror Supabase hosted service_role RLS bypass in disposable CI only.
-- NEVER run this file against a managed Supabase project.
create role service_role nologin bypassrls;
create schema auth;
create table auth.users (id uuid primary key, email text, created_at timestamptz not null default now());
create function auth.uid() returns uuid language sql stable
as $$ select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid $$;
grant usage on schema auth to authenticated;
grant execute on function auth.uid() to authenticated;
create schema extensions;
create extension if not exists pgcrypto with schema extensions;

-- Supabase Storage test-only schema shim for V26 migration. NOT for hosted Supabase.
create schema storage;
create table storage.buckets (id text primary key, name text, public boolean,
  file_size_limit bigint, allowed_mime_types text[]);
create table storage.objects (id uuid primary key default gen_random_uuid(),
  bucket_id text not null, name text not null, owner_id text);
create function storage.foldername(path text) returns text[] language sql immutable
  as $$ select string_to_array(path, '/') $$;
alter table storage.objects enable row level security;
grant usage on schema storage to authenticated;
grant select, insert, delete on storage.objects to authenticated;
