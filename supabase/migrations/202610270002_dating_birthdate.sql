-- Expose existing user's date of birth ONLY to that same authenticated user.
-- This prevents the mobile edit form from requiring DOB to be entered again.
create function app_private.my_dating_birthdate()
returns date language plpgsql security definer set search_path = '' stable
as $$
declare
  v_user uuid := (select auth.uid());
  v_birthdate date;
begin
  if v_user is null then raise exception 'Sign-in required'; end if;
  select p.date_of_birth into v_birthdate
  from app_private.dating_profiles p where p.user_id = v_user;
  return v_birthdate;
end;
$$;

create function public.my_dating_birthdate()
returns date language sql security invoker set search_path = '' stable
as $$ select app_private.my_dating_birthdate(); $$;

revoke execute on function app_private.my_dating_birthdate() from public, anon, authenticated;
revoke execute on function public.my_dating_birthdate() from public, anon, authenticated;
grant execute on function app_private.my_dating_birthdate() to authenticated;
grant execute on function public.my_dating_birthdate() to authenticated;
