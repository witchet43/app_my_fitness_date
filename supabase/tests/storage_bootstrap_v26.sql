-- Disposable CI shim only. Never deploy this to Supabase hosted.
-- Mimics only the storage definitions required by V26 RLS migration tests.
create schema storage;
create table storage.buckets (
  id text primary key,
  name text not null unique,
  public boolean not null default false,
  file_size_limit bigint,
  allowed_mime_types text[]
);
create table storage.objects (
  id uuid primary key default gen_random_uuid(),
  bucket_id text not null references storage.buckets(id),
  name text not null,
  owner_id text
);
create function storage.foldername(name text)
returns text[] language sql immutable
as $$ select (string_to_array(name, '/'))[1:array_length(string_to_array(name, '/'),1)-1] $$;
grant usage on schema storage to authenticated;
grant select,insert,delete on storage.objects to authenticated;
