-- Restrict tenant-scoped policies that were accidentally granted to PUBLIC.
-- These policies rely on authenticated membership helpers and should not be
-- evaluated for anonymous requests. Policy expressions are preserved exactly.
do $$
declare
  p record;
  using_clause text;
  check_clause text;
begin
  for p in
    select schemaname, tablename, policyname, cmd, qual, with_check
    from pg_policies
    where schemaname = 'public'
      and tablename in ('events', 'exam_marks', 'notices', 'report_cards')
      and 'public' = any(roles)
  loop
    using_clause := case
      when p.cmd in ('SELECT', 'UPDATE', 'DELETE', 'ALL') and p.qual is not null
        then format(' USING (%s)', p.qual)
      else ''
    end;
    check_clause := case
      when p.cmd in ('INSERT', 'UPDATE', 'ALL') and p.with_check is not null
        then format(' WITH CHECK (%s)', p.with_check)
      else ''
    end;

    execute format('DROP POLICY %I ON %I.%I',
      p.policyname, p.schemaname, p.tablename);
    execute format(
      'CREATE POLICY %I ON %I.%I FOR %s TO authenticated%s%s',
      p.policyname, p.schemaname, p.tablename, p.cmd,
      using_clause, check_clause
    );
  end loop;
end
$$;
