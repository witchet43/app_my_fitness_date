-- Minimal local CI shims for Supabase-specific database roles and auth.
-- These are test-only; NEVER execute against a managed Supabase project.
create role authenticated nologin;
create role anon nologin;
create schema auth;
create table auth.users (id uuid primary key, email text, created_at timestamptz not null default now());
create function auth.uid() returns uuid language sql stable
as $$ select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid $$;
grant usage on schema auth to authenticated;
grant execute on function auth.uid() to authenticated;
create schema extensions;
create extension if not exists pgcrypto with schema extensions;
