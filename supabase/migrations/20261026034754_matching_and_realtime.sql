begin;
create function private.recommendations() returns jsonb language sql stable security definer set search_path='' as $$
 with candidates as (
 select l.*,us.skill_id,us.level from public.skill_listings l join public.user_skills us on us.id=l.user_skill_id
 where auth.uid() is not null and private.is_active(auth.uid()) and l.owner_id<>auth.uid() and l.status='published' and l.visibility='public' and private.can_view_profile(l.owner_id)
 order by exists(select 1 from public.learning_interests i where i.user_id=auth.uid() and i.skill_id=us.skill_id) desc,l.created_at desc limit 200
 ), scored as (
 select id,
 exists(select 1 from public.learning_interests i where i.user_id=auth.uid() and i.skill_id=c.skill_id)::int*40 as skill,
 (('exchange'=any(c.modes)) and exists(select 1 from public.learning_interests i join public.user_skills s on s.skill_id=i.skill_id join public.skill_listings sl on sl.user_skill_id=s.id where i.user_id=c.owner_id and s.user_id=auth.uid() and sl.status='published' and 'exchange'=any(sl.modes)))::int*25 as reciprocal,
 exists(select 1 from public.availability_rules a join public.availability_rules b on a.timezone=b.timezone and a.weekday=b.weekday and a.start_local<b.end_local and b.start_local<a.end_local where a.user_id=auth.uid() and b.user_id=c.owner_id)::int*15 as availability,
 exists(select 1 from public.profiles p where p.id=auth.uid() and p.languages&&c.languages)::int*10 as language,
 exists(select 1 from public.learning_interests i where i.user_id=auth.uid() and i.skill_id=c.skill_id and i.preferred_level=c.level)::int*10 as experience
 from candidates c
 ) select coalesce(jsonb_agg(to_jsonb(s) order by skill+reciprocal+availability+language+experience desc),'[]') from scored s;
$$;
revoke all on function private.recommendations() from public,anon;
grant execute on function private.recommendations() to authenticated;
create function public.recommendations() returns jsonb language sql stable security invoker set search_path='' as $$select private.recommendations();$$;
revoke all on function public.recommendations() from public,anon;
grant execute on function public.recommendations() to authenticated;
create function private.available_slots(listing uuid,day date) returns jsonb language sql stable security definer set search_path='' as $$
 with l as(select s.*,a.notice_minutes,a.buffer_minutes,a.timezone,a.max_sessions_per_day from public.skill_listings s join public.account_settings a on a.user_id=s.owner_id where s.id=listing and s.status='published' and s.visibility='public' and private.can_view_profile(s.owner_id)),
 slots as(select t as starts_at,t+make_interval(mins=>l.duration_minutes) as ends_at,l.* from l cross join generate_series(day::timestamp at time zone 'UTC',(day+1)::timestamp at time zone 'UTC'-interval '30 minutes',interval '30 minutes') t)
 select coalesce(jsonb_agg(jsonb_build_object('starts_at',s.starts_at,'ends_at',s.ends_at) order by s.starts_at),'[]') from slots s where auth.uid() is not null and private.is_active(auth.uid()) and s.owner_id<>auth.uid() and s.starts_at>=now()+make_interval(mins=>s.notice_minutes) and s.starts_at<=now()+interval '90 days'
 and exists(select 1 from public.availability_rules a where a.user_id=s.owner_id and a.weekday=extract(dow from s.starts_at at time zone a.timezone) and (s.starts_at at time zone a.timezone)::date=(s.ends_at at time zone a.timezone)::date and (s.starts_at at time zone a.timezone)::time>=a.start_local and (s.ends_at at time zone a.timezone)::time<=a.end_local)
 and not exists(select 1 from public.booking_participants p join public.account_settings a on a.user_id=p.user_id where p.user_id in(auth.uid(),s.owner_id) and p.active and p.occupied_range&&tstzrange(s.starts_at,s.ends_at+make_interval(mins=>a.buffer_minutes),'[)'))
 and not exists(select 1 from public.availability_exceptions e where e.user_id=s.owner_id and not e.available and tstzrange(e.starts_at,e.ends_at,'[)')&&tstzrange(s.starts_at,s.ends_at,'[)'))
 and (select count(*) from public.bookings b where b.teacher_id=s.owner_id and b.status in('requested','confirmed','completed') and (b.starts_at at time zone s.timezone)::date=(s.starts_at at time zone s.timezone)::date)<s.max_sessions_per_day;
$$;
revoke all on function private.available_slots(uuid,date) from public,anon;
grant execute on function private.available_slots(uuid,date) to authenticated;
create function public.available_slots(listing uuid,day date) returns jsonb language sql stable security invoker set search_path='' as $$select private.available_slots(listing,day);$$;
revoke all on function public.available_slots(uuid,date) from public,anon;
grant execute on function public.available_slots(uuid,date) to authenticated;
-- PGlite does not run a logical replication service; hosted Supabase does.
do $$begin if exists(select 1 from pg_publication where pubname='supabase_realtime') then
 if not exists(select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='messages') then alter publication supabase_realtime add table public.messages; end if;
 end if;end$$;
commit;
