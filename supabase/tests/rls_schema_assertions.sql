-- Run only against an isolated SchoolConnect test database after migrations.
-- This is a schema regression check, not a substitute for two-user API/RLS tests.
do $$
declare
  required_policy text;
begin
  foreach required_policy in array array[
    'school_users_select',
    'school_users_insert',
    'school_users_update',
    'school_users_delete'
  ] loop
    if not exists (
      select 1 from pg_policies
      where schemaname = 'public'
        and tablename = 'school_users'
        and policyname = required_policy
        and roles @> array['authenticated']::name[]
    ) then
      raise exception 'Missing authenticated school_users policy: %', required_policy;
    end if;
  end loop;

  if exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'school_users'
      and policyname = 'school_users_access'
  ) then
    raise exception 'Legacy broad school_users_access policy remains';
  end if;

  if exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename in ('events','exam_marks','notices','report_cards')
      and 'public' = any(roles)
  ) then
    raise exception 'A reviewed tenant table still has a policy targeting public';
  end if;

  if not exists (
    select 1
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'private'
      and p.proname = 'is_school_admin'
      and p.prosecdef
      and pg_get_functiondef(p.oid) ilike '%su.is_active = true%'
  ) then
    raise exception 'is_school_admin must be SECURITY DEFINER and require active membership';
  end if;
end
$$;

-- Inspect public/anon EXECUTE exposure separately; do not blanket-revoke RPCs.
select n.nspname as schema_name,
       p.proname as function_name,
       pg_get_function_identity_arguments(p.oid) as arguments,
       p.prosecdef as security_definer,
       coalesce(array_to_string(p.proacl, ','), 'default ACL') as privileges
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname in ('public','private')
  and p.prosecdef
order by n.nspname, p.proname;
