begin;
-- All client mutations go through this authenticated, transactional command boundary.
create table private.rate_windows(user_id uuid primary key, started_at timestamptz not null, count integer not null);
create function private.command(op text, payload jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
declare
 u uuid := auth.uid(); rid uuid; other uuid; sid uuid; usid uuid; cid uuid; n integer; result jsonb := '{}';
 l public.skill_listings; e public.exchange_requests; b public.bookings; a public.account_settings; ob public.exchange_obligations;
 start_time timestamptz; end_time timestamptz; cost integer; total integer; lev public.experience_level;
begin
 if u is null or not private.is_active(u) then raise exception 'Sign in with an active account'; end if;
 insert into private.rate_windows values(u,now(),1) on conflict(user_id) do update set
 count=case when rate_windows.started_at<now()-interval '1 minute' then 1 else rate_windows.count+1 end,
 started_at=case when rate_windows.started_at<now()-interval '1 minute' then now() else rate_windows.started_at end returning count into n;
 if n>40 then raise exception 'Please wait before trying again'; end if;
 case op
 when 'profile' then
 if not exists(select 1 from pg_timezone_names where name=payload->>'timezone') then raise exception 'Choose a valid time zone'; end if;
 update public.profiles set full_name=btrim(payload->>'full_name'),bio=coalesce(payload->>'bio',''),location=payload->>'location',
 languages=array(select jsonb_array_elements_text(payload->'languages')),visibility=coalesce(payload->>'visibility','public') where id=u;
 update public.account_settings set timezone=payload->>'timezone',onboarding_step=greatest(onboarding_step,1),
 terms_accepted_at=coalesce(terms_accepted_at,now()),terms_version='2026-10' where user_id=u;
 when 'onboarding' then
 update public.account_settings set onboarding_step=least(5,greatest(onboarding_step,(payload->>'step')::integer)),
 onboarding_completed_at=case when (payload->>'step')::integer=5 then now() else onboarding_completed_at end where user_id=u;
 when 'listing' then
 rid=nullif(payload->>'id','')::uuid;
 if rid is not null and not exists(select 1 from public.skill_listings where id=rid and owner_id=u and status<>'moderated') then raise exception 'Listing unavailable'; end if;
 if payload->>'status' not in ('draft','published','archived') then raise exception 'Invalid status'; end if;
 if length(btrim(payload->>'skill')) not between 2 and 80 then raise exception 'Skill must be 2–80 characters'; end if;
 if not exists(select 1 from public.skill_categories where id=(payload->>'category_id')::uuid and active) then raise exception 'Invalid category'; end if;
 if exists(select 1 from jsonb_array_elements_text(payload->'modes') m where m not in ('exchange','credits')) then raise exception 'Paid sessions are not enabled'; end if;
 insert into public.skills(category_id,name) values((payload->>'category_id')::uuid,btrim(payload->>'skill')) on conflict(normalized_name) do update set name=skills.name returning id into sid;
 insert into public.user_skills(user_id,skill_id,level) values(u,sid,(payload->>'level')::public.experience_level)
 on conflict(user_id,skill_id) do update set level=excluded.level returning id into usid;
 if rid is null then
 insert into public.skill_listings(owner_id,user_skill_id,title,description,format,duration_minutes,languages,modes,status,prerequisites)
 values(u,usid,payload->>'title',payload->>'description',payload->>'format',(payload->>'duration_minutes')::int,
 array(select jsonb_array_elements_text(payload->'languages')),array(select jsonb_array_elements_text(payload->'modes'))::public.learning_mode[],payload->>'status',coalesce(payload->>'prerequisites','')) returning id into rid;
 else
 update public.skill_listings set user_skill_id=usid,title=payload->>'title',description=payload->>'description',format=payload->>'format',duration_minutes=(payload->>'duration_minutes')::int,
 languages=array(select jsonb_array_elements_text(payload->'languages')),modes=array(select jsonb_array_elements_text(payload->'modes'))::public.learning_mode[],status=payload->>'status',prerequisites=coalesce(payload->>'prerequisites','') where id=rid;
 end if;
 result=jsonb_build_object('id',rid);
 when 'delete_listing' then
 rid=(payload->>'id')::uuid;
 if exists(select 1 from public.bookings where listing_id=rid) or exists(select 1 from public.exchange_requests where rid in(offered_listing_id,requested_listing_id)) then
 update public.skill_listings set status='archived' where id=rid and owner_id=u;
 else delete from public.skill_listings where id=rid and owner_id=u; end if;
 when 'interest' then
 insert into public.learning_interests(user_id,skill_id,preferred_level,goals) values(u,(payload->>'skill_id')::uuid,(payload->>'preferred_level')::public.experience_level,coalesce(payload->>'goals',''))
 on conflict(user_id,skill_id) do update set preferred_level=excluded.preferred_level,goals=excluded.goals;
 when 'delete_interest' then delete from public.learning_interests where id=(payload->>'id')::uuid and user_id=u;
 when 'availability' then
 if not exists(select 1 from pg_timezone_names where name=payload->>'timezone') then raise exception 'Invalid timezone'; end if;
 insert into public.availability_rules(user_id,weekday,start_local,end_local,timezone) values(u,(payload->>'weekday')::int,(payload->>'start_local')::time,(payload->>'end_local')::time,payload->>'timezone') on conflict do nothing;
 when 'delete_availability' then delete from public.availability_rules where id=(payload->>'id')::uuid and user_id=u;
 when 'exchange' then
 select * into l from public.skill_listings where id=(payload->>'requested_listing_id')::uuid and status='published' and visibility='public';
 if l.id is null or l.owner_id=u or not private.can_view_profile(l.owner_id) or not ('exchange'=any(l.modes)) then raise exception 'Listing unavailable for exchange'; end if;
 if not exists(select 1 from public.skill_listings where id=(payload->>'offered_listing_id')::uuid and owner_id=u and status='published' and 'exchange'=any(modes)) then raise exception 'Choose your published exchange listing'; end if;
 insert into public.exchange_requests(requester_id,recipient_id,offered_listing_id,requested_listing_id,session_count,message)
 values(u,l.owner_id,(payload->>'offered_listing_id')::uuid,l.id,(payload->>'session_count')::int,coalesce(payload->>'message','')) returning id into rid;
 insert into public.exchange_status_history(exchange_id,actor_id,new_status) values(rid,u,'pending');
 insert into public.notifications(user_id,kind,title,target_path) values(l.owner_id,'exchange_request','You received a skill exchange proposal','/exchanges/'||rid);
 result=jsonb_build_object('id',rid);
 when 'exchange_status' then
 select * into e from public.exchange_requests where id=(payload->>'id')::uuid for update;
 if e.id is null or u not in(e.requester_id,e.recipient_id) or private.is_blocked(e.requester_id,e.recipient_id) then raise exception 'Exchange unavailable'; end if;
 if e.status<>'pending' or (payload->>'status' in ('accepted','rejected') and u<>e.recipient_id) or payload->>'status' not in ('accepted','rejected','cancelled') then raise exception 'Invalid exchange transition'; end if;
 update public.exchange_requests set status=(payload->>'status')::public.exchange_state where id=e.id;
 insert into public.exchange_status_history(exchange_id,actor_id,old_status,new_status) values(e.id,u,e.status,(payload->>'status')::public.exchange_state);
 if payload->>'status'='accepted' then
 insert into public.exchange_obligations(exchange_id,teacher_id,learner_id,listing_id,required_sessions) values(e.id,e.requester_id,e.recipient_id,e.offered_listing_id,e.session_count),(e.id,e.recipient_id,e.requester_id,e.requested_listing_id,e.session_count);
 end if;
 insert into public.notifications(user_id,kind,title,target_path) values(case when u=e.requester_id then e.recipient_id else e.requester_id end,case when payload->>'status'='accepted' then 'exchange_accepted' else 'exchange_rejected' end,'Exchange '||(payload->>'status'),'/exchanges/'||e.id);
 when 'book' then
 select * into l from public.skill_listings where id=(payload->>'listing_id')::uuid and status='published' and visibility='public';
 if l.id is null or l.owner_id=u or not private.can_view_profile(l.owner_id) then raise exception 'Listing unavailable'; end if;
 -- Lock participants in a deterministic order: daily limits and cross-role booking checks are serialized.
 perform 1 from public.account_settings where user_id in(u,l.owner_id) order by user_id for update;
 select * into a from public.account_settings where user_id=l.owner_id;
 start_time=(payload->>'starts_at')::timestamptz; end_time=start_time+make_interval(mins=>l.duration_minutes);
 if start_time<now()+make_interval(mins=>a.notice_minutes) or start_time>now()+interval '90 days' then raise exception 'Book between 24 hours and 90 days ahead'; end if;
 if not exists(select 1 from public.availability_rules ar where ar.user_id=l.owner_id
 and ar.weekday=extract(dow from start_time at time zone ar.timezone)
 and (start_time at time zone ar.timezone)::date=(end_time at time zone ar.timezone)::date
 and (start_time at time zone ar.timezone)::time>=ar.start_local and (end_time at time zone ar.timezone)::time<=ar.end_local)
 or exists(select 1 from public.availability_exceptions where user_id=l.owner_id and not available and tstzrange(starts_at,ends_at,'[)') && tstzrange(start_time,end_time,'[)')) then raise exception 'Outside teacher availability'; end if;
 select count(*) into n from public.bookings where teacher_id=l.owner_id and status in ('requested','confirmed','completed') and (starts_at at time zone a.timezone)::date=(start_time at time zone a.timezone)::date;
 if n>=a.max_sessions_per_day then raise exception 'Daily booking limit reached'; end if;
 rid=nullif(payload->>'obligation_id','')::uuid; cost=0;
 if rid is not null then
 select * into ob from public.exchange_obligations where id=rid and learner_id=u and teacher_id=l.owner_id and listing_id=l.id for update;
 if ob.id is null or not exists(select 1 from public.exchange_requests where id=ob.exchange_id and status in('accepted','in_progress')) then raise exception 'Invalid exchange obligation'; end if;
 select count(*) into n from public.bookings where obligation_id=ob.id and status not in('cancelled','no_show');
 if n>=ob.required_sessions then raise exception 'All exchange sessions already scheduled'; end if;
 else
 if not ('credits'=any(l.modes)) then raise exception 'This listing requires an accepted exchange'; end if;
 cost=l.duration_minutes/15;
 perform 1 from public.credit_wallets where user_id in(u,l.owner_id) order by user_id for update;
 update public.credit_wallets set reserved=reserved+cost where user_id=u and balance-reserved>=cost;
 if not found then raise exception 'Insufficient credits. Start with a direct exchange'; end if;
 end if;
 insert into public.bookings(listing_id,teacher_id,learner_id,obligation_id,mode,status,starts_at,ends_at,credit_cost,cancellation_cutoff_at,policy_version)
 values(l.id,l.owner_id,u,rid,case when rid is null then 'credits'::public.learning_mode else 'exchange'::public.learning_mode end,'confirmed',start_time,end_time,cost,start_time-interval '24 hours','24h-v1') returning id into rid;
 insert into public.booking_participants(booking_id,user_id,occupied_range) select rid,s.user_id,tstzrange(start_time,end_time+make_interval(mins=>s.buffer_minutes),'[)') from public.account_settings s where s.user_id in(u,l.owner_id);
 if cost>0 then insert into public.credit_reservations(booking_id,user_id,amount) values(rid,u,cost); end if;
 insert into public.booking_status_history(booking_id,actor_id,new_status) values(rid,u,'confirmed');
 insert into public.notifications(user_id,kind,title,target_path) values(l.owner_id,'booking','A new session is booked','/bookings/'||rid);
 result=jsonb_build_object('id',rid);
 when 'booking_status' then
 select * into b from public.bookings where id=(payload->>'id')::uuid for update;
 if b.id is null or u not in(b.teacher_id,b.learner_id) then raise exception 'Booking unavailable'; end if;
 if b.status<>'confirmed' then raise exception 'Booking is no longer confirmed'; end if;
 perform 1 from public.credit_wallets where user_id in(b.teacher_id,b.learner_id) order by user_id for update;
 if payload->>'status'='cancelled' then
 if now()>b.cancellation_cutoff_at then raise exception 'Cancellation closes 24 hours before the session. Report a dispute if needed'; end if;
 update public.bookings set status='cancelled' where id=b.id;
 update public.booking_participants set active=false where booking_id=b.id;
 update public.credit_wallets set reserved=reserved-b.credit_cost where user_id=b.learner_id;
 update public.credit_reservations set status='released' where booking_id=b.id and status='held';
 elsif payload->>'status'='completed' then
 if now()<b.ends_at then raise exception 'Confirm completion after the scheduled end'; end if;
 update public.bookings set teacher_confirmed_completion_at=case when u=teacher_id then now() else teacher_confirmed_completion_at end,
 learner_confirmed_completion_at=case when u=learner_id then now() else learner_confirmed_completion_at end where id=b.id returning * into b;
 if b.teacher_confirmed_completion_at is not null and b.learner_confirmed_completion_at is not null then
 update public.bookings set status='completed' where id=b.id;
 if b.credit_cost>0 then
 insert into public.credit_transactions(debit_user_id,credit_user_id,booking_id,amount,kind,idempotency_key,reason,actor_id) values(b.learner_id,b.teacher_id,b.id,b.credit_cost,'settlement','settle:'||b.id,'Both participants confirmed completion',u);
 update public.credit_wallets set balance=balance-b.credit_cost,reserved=reserved-b.credit_cost where user_id=b.learner_id;
 update public.credit_wallets set balance=balance+b.credit_cost where user_id=b.teacher_id;
 update public.credit_reservations set status='settled' where booking_id=b.id;
 insert into public.notifications(user_id,kind,title,target_path) values(b.teacher_id,'credit','Session credits received','/wallet');
 end if;
 if b.obligation_id is not null then
 select exchange_id into rid from public.exchange_obligations where id=b.obligation_id;
 perform 1 from public.exchange_requests where id=rid for update;
 if not exists(select 1 from public.exchange_obligations o where exchange_id=rid and (select count(*) from public.bookings bk where bk.obligation_id=o.id and bk.status='completed')<o.required_sessions) then
 update public.exchange_requests set status='completed' where id=rid;
 insert into public.exchange_status_history(exchange_id,actor_id,old_status,new_status) values(rid,u,'accepted','completed');
 end if;
 end if;
 end if;
 else raise exception 'Invalid booking transition'; end if;
 insert into public.booking_status_history(booking_id,actor_id,old_status,new_status) select b.id,u,'confirmed',status from public.bookings where id=b.id;
 when 'conversation' then
 other=(payload->>'user_id')::uuid;
 if other=u or not private.can_view_profile(other) or not private.is_active(other) or private.is_blocked(u,other) then raise exception 'User unavailable'; end if;
 perform 1 from public.account_settings where user_id in(u,other) order by user_id for update;
 select p.conversation_id into cid from public.conversation_participants p join public.conversation_participants q using(conversation_id) where p.user_id=u and q.user_id=other limit 1;
 if cid is null then insert into public.conversations default values returning id into cid; insert into public.conversation_participants(conversation_id,user_id) values(cid,u),(cid,other); end if;
 result=jsonb_build_object('id',cid);
 when 'message' then
 cid=(payload->>'conversation_id')::uuid;
 if not private.in_conversation(cid) then raise exception 'Conversation unavailable'; end if;
 insert into public.messages(conversation_id,sender_id,body,client_nonce) values(cid,u,btrim(payload->>'body'),(payload->>'nonce')::uuid) on conflict(sender_id,client_nonce) do nothing;
 if found then insert into public.notifications(user_id,kind,title,target_path) select user_id,'message','New message','/messages/'||cid from public.conversation_participants where conversation_id=cid and user_id<>u; end if;
 when 'read_messages' then update public.conversation_participants set last_read_at=now() where conversation_id=(payload->>'id')::uuid and user_id=u;
 when 'read_notifications' then update public.notifications set read_at=now() where user_id=u and (payload->>'id' is null or id=(payload->>'id')::uuid);
 when 'review' then
 select * into b from public.bookings where id=(payload->>'booking_id')::uuid;
 if b.id is null or b.status<>'completed' or u not in(b.teacher_id,b.learner_id) then raise exception 'Only completed-session participants can review'; end if;
 other=case when u=b.teacher_id then b.learner_id else b.teacher_id end;
 insert into public.reviews(booking_id,reviewer_id,reviewee_id,rating,communication,teaching_quality,punctuality,feedback)
 values(b.id,u,other,(payload->>'rating')::int,(payload->>'communication')::int,(payload->>'teaching_quality')::int,(payload->>'punctuality')::int,coalesce(payload->>'feedback',''));
 insert into public.notifications(user_id,kind,title,target_path) values(other,'review','You received a verified review','/users/'||other);
 when 'block' then insert into public.user_blocks(blocker_id,blocked_id) values(u,(payload->>'user_id')::uuid) on conflict do nothing;
 when 'unblock' then delete from public.user_blocks where blocker_id=u and blocked_id=(payload->>'user_id')::uuid;
 when 'report' then insert into public.reports(reporter_id,reported_user_id,reason) values(u,(payload->>'user_id')::uuid,payload->>'reason');
 when 'deletion' then update public.account_settings set status='deletion_requested' where user_id=u;
 when 'admin_user' then
 if not private.is_admin() then raise exception 'Administrator required'; end if;
 other=(payload->>'user_id')::uuid;
 if other=u or payload->>'status' not in ('active','suspended') then raise exception 'Invalid moderation action'; end if;
 update public.account_settings set status=payload->>'status' where user_id=other;
 insert into public.admin_audit_logs(actor_id,action,target_type,target_id,reason) values(u,payload->>'status','user',other,payload->>'reason');
 when 'admin_report' then
 if not private.is_admin() then raise exception 'Administrator required'; end if;
 update public.reports set status=payload->>'status' where id=(payload->>'id')::uuid;
 insert into public.admin_audit_logs(actor_id,action,target_type,target_id,reason) values(u,'review_report','report',(payload->>'id')::uuid,payload->>'reason');
 when 'admin_listing' then
 if not private.is_admin() then raise exception 'Administrator required'; end if;
 update public.skill_listings set status='moderated' where id=(payload->>'id')::uuid;
 insert into public.admin_audit_logs(actor_id,action,target_type,target_id,reason) values(u,'moderate','listing',(payload->>'id')::uuid,payload->>'reason');
 else raise exception 'Unknown action'; end case;
 return result;
end $$;
revoke all on function private.command(text,jsonb) from public,anon;
grant execute on function private.command(text,jsonb) to authenticated;
create function public.command(op text,payload jsonb) returns jsonb language sql security invoker set search_path='' as $$ select private.command(op,payload); $$;
revoke all on function public.command(text,jsonb) from public,anon;
grant execute on function public.command(text,jsonb) to authenticated;
-- Availability is deliberately public for public, active teachers; no booking identities are exposed.
create policy availability_public on public.availability_rules for select using(private.can_view_profile(user_id));
-- Seed taxonomy only: these are categories, not fabricated activity or users.
insert into public.skill_categories(name,slug) select n,lower(replace(replace(n,'/','-'),' ','-')) from unnest(array['Programming','Artificial Intelligence','Web Development','Mobile Development','Graphic Design','UI/UX Design','Photography','Music','Languages','Fitness','Business','Marketing','Academic Subjects','Other']) n on conflict do nothing;
commit;
