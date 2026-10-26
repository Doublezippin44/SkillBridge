-- Phase 1 foundation. Mutations of workflows/finance remain denied until audited RPCs land.
begin;
create extension if not exists btree_gist;
create schema if not exists private;
revoke all on schema private from public;
create type public.experience_level as enum ('beginner','intermediate','advanced','expert');
create type public.learning_mode as enum ('exchange','credits','paid');
create type public.booking_state as enum ('requested','confirmed','completed','cancelled','no_show','disputed');
create type public.exchange_state as enum ('pending','accepted','rejected','cancelled','in_progress','completed','disputed');

create table public.profiles (
 id uuid primary key references auth.users(id), full_name text not null check(length(full_name) between 1 and 100),
 avatar_path text, bio text not null default '' check(length(bio)<=2000), location text,
 languages text[] not null default '{}', visibility text not null default 'public' check(visibility in ('public','private')),
 is_demo boolean not null default false, created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
-- Account status and onboarding/private preferences never appear on public profiles.
create table public.account_settings (
 user_id uuid primary key references public.profiles(id), timezone text not null default 'Asia/Kolkata',
 status text not null default 'active' check(status in ('active','suspended','deletion_requested')),
 onboarding_step smallint not null default 0 check(onboarding_step between 0 and 5),
 onboarding_completed_at timestamptz, terms_accepted_at timestamptz, terms_version text,
 learning_modes public.learning_mode[] not null default '{exchange,credits}',
 notification_preferences jsonb not null default '{"in_app":true,"email":false}',
 notice_minutes integer not null default 1440 check(notice_minutes>=0),
 buffer_minutes integer not null default 15 check(buffer_minutes between 0 and 180),
 max_sessions_per_day integer not null default 4 check(max_sessions_per_day between 1 and 24),
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table public.user_roles (
 user_id uuid primary key references public.profiles(id), role text not null check(role in ('user','admin')),
 created_at timestamptz not null default now()
);
create table public.skill_categories (
 id uuid primary key default gen_random_uuid(), name text not null unique, slug text not null unique,
 active boolean not null default true, created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table public.skills (
 id uuid primary key default gen_random_uuid(), category_id uuid not null references public.skill_categories(id),
 name text not null, normalized_name text generated always as (lower(btrim(name))) stored unique,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table public.user_skills (
 id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles(id),
 skill_id uuid not null references public.skills(id), level public.experience_level not null,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now(), unique(user_id,skill_id), unique(id,user_id)
);
create table public.learning_interests (
 id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles(id),
 skill_id uuid not null references public.skills(id), preferred_level public.experience_level not null default 'beginner',
 goals text not null default '' check(length(goals)<=2000), created_at timestamptz not null default now(),
 updated_at timestamptz not null default now(), unique(user_id,skill_id)
);
create table public.skill_listings (
 id uuid primary key default gen_random_uuid(), owner_id uuid not null references public.profiles(id), user_skill_id uuid not null,
 title text not null check(length(title) between 3 and 120), description text not null check(length(description) between 20 and 5000),
 format text not null check(format in ('online','in_person','hybrid')), duration_minutes integer not null check(duration_minutes in (30,45,60,90,120)),
 languages text[] not null check(cardinality(languages)>0), prerequisites text not null default '',
 modes public.learning_mode[] not null check(cardinality(modes)>0), hourly_price_paise integer check(hourly_price_paise>0),
 status text not null default 'draft' check(status in ('draft','published','archived','moderated')), visibility text not null default 'public' check(visibility in ('public','private')),
 search_document tsvector generated always as (to_tsvector('english',title || ' ' || description)) stored,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
 foreign key(user_skill_id,owner_id) references public.user_skills(id,user_id), unique(id,owner_id),
 check(not ('paid'=any(modes)) or hourly_price_paise is not null)
);
create table public.exchange_requests (
 id uuid primary key default gen_random_uuid(), requester_id uuid not null references public.profiles(id), recipient_id uuid not null references public.profiles(id),
 offered_listing_id uuid not null, requested_listing_id uuid not null,
 session_count integer not null check(session_count between 1 and 12), message text not null default '' check(length(message)<=3000),
 proposed_schedule jsonb not null default '[]', status public.exchange_state not null default 'pending',
 created_at timestamptz not null default now(), updated_at timestamptz not null default now(), check(requester_id<>recipient_id),
 foreign key(offered_listing_id,requester_id) references public.skill_listings(id,owner_id),
 foreign key(requested_listing_id,recipient_id) references public.skill_listings(id,owner_id)
);
create table public.exchange_obligations (
 id uuid primary key default gen_random_uuid(), exchange_id uuid not null references public.exchange_requests(id),
 teacher_id uuid not null references public.profiles(id), learner_id uuid not null references public.profiles(id), listing_id uuid not null,
 required_sessions integer not null check(required_sessions between 1 and 12), check(teacher_id<>learner_id),
 created_at timestamptz not null default now(), unique(exchange_id,teacher_id), foreign key(listing_id,teacher_id) references public.skill_listings(id,owner_id)
);
create table public.exchange_status_history (
 id uuid primary key default gen_random_uuid(), exchange_id uuid not null references public.exchange_requests(id), actor_id uuid references public.profiles(id),
 old_status public.exchange_state, new_status public.exchange_state not null, reason text, created_at timestamptz not null default now()
);
create table public.availability_rules (
 id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles(id), weekday smallint not null check(weekday between 0 and 6),
 start_local time not null, end_local time not null, timezone text not null, check(start_local<end_local),
 created_at timestamptz not null default now(), updated_at timestamptz not null default now(), unique(user_id,weekday,start_local,end_local)
);
create table public.availability_exceptions (
 id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles(id),
 starts_at timestamptz not null, ends_at timestamptz not null, available boolean not null default false, check(starts_at<ends_at),
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table public.bookings (
 id uuid primary key default gen_random_uuid(), listing_id uuid not null, teacher_id uuid not null references public.profiles(id), learner_id uuid not null references public.profiles(id),
 obligation_id uuid references public.exchange_obligations(id), mode public.learning_mode not null, status public.booking_state not null default 'requested',
 starts_at timestamptz not null, ends_at timestamptz not null, credit_cost integer not null default 0 check(credit_cost>=0),
 price_paise integer not null default 0 check(price_paise>=0), currency text not null default 'INR' check(currency='INR'),
 cancellation_cutoff_at timestamptz not null, policy_version text not null, requested_expires_at timestamptz,
 teacher_confirmed_completion_at timestamptz, learner_confirmed_completion_at timestamptz,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
 check(teacher_id<>learner_id), check(starts_at<ends_at), check(cancellation_cutoff_at<=starts_at),
 check((mode='exchange' and obligation_id is not null and credit_cost=0 and price_paise=0) or
       (mode='credits' and obligation_id is null and credit_cost>0 and price_paise=0) or
       (mode='paid' and obligation_id is null and price_paise>0 and credit_cost=0)),
 foreign key(listing_id,teacher_id) references public.skill_listings(id,owner_id)
);
-- Both teacher AND learner are protected, even if switching roles. RPC must insert two rows atomically.
create table public.booking_participants (
 booking_id uuid not null references public.bookings(id), user_id uuid not null references public.profiles(id),
 occupied_range tstzrange not null, active boolean not null default true, primary key(booking_id,user_id),
 check(not isempty(occupied_range) and lower(occupied_range) is not null and upper(occupied_range) is not null),
 exclude using gist (user_id with =, occupied_range with &&) where(active)
);
create table public.booking_status_history (
 id uuid primary key default gen_random_uuid(), booking_id uuid not null references public.bookings(id), actor_id uuid references public.profiles(id),
 old_status public.booking_state, new_status public.booking_state not null, reason text, created_at timestamptz not null default now()
);
create table public.conversations (id uuid primary key default gen_random_uuid(), created_at timestamptz not null default now());
create table public.conversation_participants (
 conversation_id uuid not null references public.conversations(id), user_id uuid not null references public.profiles(id),
 last_read_at timestamptz, created_at timestamptz not null default now(), primary key(conversation_id,user_id)
);
create table public.messages (
 id uuid primary key default gen_random_uuid(), conversation_id uuid not null references public.conversations(id), sender_id uuid not null references public.profiles(id),
 body text not null check(length(btrim(body)) between 1 and 4000), client_nonce uuid not null,
 created_at timestamptz not null default now(), unique(sender_id,client_nonce),
 foreign key(conversation_id,sender_id) references public.conversation_participants(conversation_id,user_id)
);
create table public.credit_wallets (
 user_id uuid primary key references public.profiles(id), balance integer not null default 0 check(balance>=0),
 reserved integer not null default 0 check(reserved>=0 and reserved<=balance), updated_at timestamptz not null default now()
);
-- Immutable transfer journal: one transfer row is both debit and credit. Wallets are transactional projections.
create table public.credit_transactions (
 id uuid primary key default gen_random_uuid(), debit_user_id uuid references public.credit_wallets(user_id), credit_user_id uuid references public.credit_wallets(user_id),
 booking_id uuid references public.bookings(id), amount integer not null check(amount>0),
 kind text not null check(kind in ('grant','settlement','refund','adjustment')), idempotency_key text not null unique,
 reason text not null, actor_id uuid references public.profiles(id), created_at timestamptz not null default now(),
 check(debit_user_id is not null or credit_user_id is not null), check(debit_user_id is distinct from credit_user_id),
 check(kind<>'settlement' or (booking_id is not null and debit_user_id is not null and credit_user_id is not null))
);
create unique index one_settlement_per_booking on public.credit_transactions(booking_id) where kind='settlement';
create table public.credit_reservations (
 id uuid primary key default gen_random_uuid(), booking_id uuid not null unique references public.bookings(id), user_id uuid not null references public.credit_wallets(user_id),
 amount integer not null check(amount>0), status text not null default 'held' check(status in ('held','released','settled')),
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table public.payments (
 id uuid primary key default gen_random_uuid(), booking_id uuid not null references public.bookings(id), payer_id uuid not null references public.profiles(id),
 provider_order_id text unique, provider_payment_id text unique, amount_paise integer not null check(amount_paise>0), currency text not null default 'INR' check(currency='INR'),
 status text not null default 'created' check(status in ('created','authorized','captured','failed','refund_pending','refunded')),
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table public.payment_webhook_events (
 id uuid primary key default gen_random_uuid(), provider_event_id text not null unique, event_type text not null,
 payload_hash text not null, processed_at timestamptz, created_at timestamptz not null default now()
);
create table public.reviews (
 id uuid primary key default gen_random_uuid(), booking_id uuid not null references public.bookings(id), reviewer_id uuid not null references public.profiles(id), reviewee_id uuid not null references public.profiles(id),
 rating smallint not null check(rating between 1 and 5), communication smallint not null check(communication between 1 and 5),
 teaching_quality smallint check(teaching_quality between 1 and 5), punctuality smallint not null check(punctuality between 1 and 5),
 feedback text not null check(length(feedback)<=3000), hidden boolean not null default false,
 created_at timestamptz not null default now(), check(reviewer_id<>reviewee_id), unique(booking_id,reviewer_id)
);
create table public.notifications (
 id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles(id),
 kind text not null check(kind in ('exchange_request','exchange_accepted','exchange_rejected','booking','cancellation','reminder','message','credit','review','announcement')),
 title text not null, target_path text, read_at timestamptz, created_at timestamptz not null default now()
);
create table public.reports (
 id uuid primary key default gen_random_uuid(), reporter_id uuid not null references public.profiles(id), reported_user_id uuid references public.profiles(id),
 listing_id uuid references public.skill_listings(id), message_id uuid references public.messages(id), booking_id uuid references public.bookings(id),
 reason text not null check(length(reason) between 10 and 3000), status text not null default 'open' check(status in ('open','investigating','resolved','dismissed')),
 created_at timestamptz not null default now(), updated_at timestamptz not null default now(), check(num_nonnulls(reported_user_id,listing_id,message_id,booking_id)=1)
);
create table public.user_blocks (
 blocker_id uuid not null references public.profiles(id), blocked_id uuid not null references public.profiles(id),
 created_at timestamptz not null default now(), primary key(blocker_id,blocked_id), check(blocker_id<>blocked_id)
);
create table public.admin_audit_logs (
 id uuid primary key default gen_random_uuid(), actor_id uuid not null references public.profiles(id), action text not null,
 target_type text not null, target_id uuid, reason text not null, details jsonb not null default '{}', created_at timestamptz not null default now()
);
create table public.email_outbox (
 id uuid primary key default gen_random_uuid(), notification_id uuid not null unique references public.notifications(id),
 attempts integer not null default 0 check(attempts>=0), next_attempt_at timestamptz not null default now(), sent_at timestamptz,
 created_at timestamptz not null default now()
);
create table public.booking_meetings (
 booking_id uuid primary key references public.bookings(id), provider text not null check(provider in ('jitsi_authenticated','external')),
 room_reference text not null, created_at timestamptz not null default now()
);

create index skills_category on public.skills(category_id);
create index user_skills_skill on public.user_skills(skill_id,user_id);
create index interests_skill on public.learning_interests(skill_id,user_id);
create index listings_search on public.skill_listings using gin(search_document);
create index listings_published on public.skill_listings(created_at desc,id) where status='published';
create index listings_owner on public.skill_listings(owner_id);
create index exchange_inbox on public.exchange_requests(recipient_id,status,created_at desc);
create index exchange_outbox on public.exchange_requests(requester_id,status,created_at desc);
create index bookings_teacher on public.bookings(teacher_id,starts_at);
create index bookings_learner on public.bookings(learner_id,starts_at);
create index availability_user on public.availability_exceptions(user_id,starts_at);
create index conversations_user on public.conversation_participants(user_id,conversation_id);
create index messages_history on public.messages(conversation_id,created_at desc,id);
create index credits_debit on public.credit_transactions(debit_user_id,created_at desc);
create index credits_credit on public.credit_transactions(credit_user_id,created_at desc);
create index reviews_reviewee on public.reviews(reviewee_id,created_at desc);
create index notifications_inbox on public.notifications(user_id,created_at desc);
create index reports_queue on public.reports(status,created_at);
create index blocks_reverse on public.user_blocks(blocked_id,blocker_id);

create function private.is_active(uid uuid) returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.account_settings where user_id=uid and status='active'); $$;
create function private.is_admin() returns boolean language sql stable security definer set search_path='' as $$
 select private.is_active(auth.uid()) and exists(select 1 from public.user_roles where user_id=auth.uid() and role='admin'); $$;
create function private.is_blocked(a uuid,b uuid) returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.user_blocks where (blocker_id=a and blocked_id=b) or (blocker_id=b and blocked_id=a)); $$;
create function private.can_view_profile(uid uuid) returns boolean language sql stable security definer set search_path='' as $$
 select uid=auth.uid() or private.is_admin() or exists(select 1 from public.profiles p where p.id=uid and p.visibility='public' and private.is_active(uid) and not private.is_blocked(auth.uid(),uid)); $$;
create function private.in_conversation(cid uuid) returns boolean language sql stable security definer set search_path='' as $$
 select private.is_active(auth.uid()) and exists(select 1 from public.conversation_participants where conversation_id=cid and user_id=auth.uid())
 and not exists(select 1 from public.conversation_participants where conversation_id=cid and (not private.is_active(user_id) or private.is_blocked(auth.uid(),user_id))); $$;
create function private.in_booking(bid uuid) returns boolean language sql stable security definer set search_path='' as $$
 select private.is_active(auth.uid()) and exists(select 1 from public.bookings where id=bid and auth.uid() in (teacher_id,learner_id)); $$;
create function private.in_exchange(eid uuid) returns boolean language sql stable security definer set search_path='' as $$
 select private.is_active(auth.uid()) and exists(select 1 from public.exchange_requests where id=eid and auth.uid() in (requester_id,recipient_id)); $$;

-- Default-deny all writes. Phase 2+ introduces narrow policies/RPCs with tests, never broad client writes.
do $$ declare t record; begin
 for t in select tablename from pg_tables where schemaname='public' loop
 execute format('alter table public.%I enable row level security',t.tablename);
 execute format('revoke all on public.%I from anon, authenticated',t.tablename);
 execute format('grant select on public.%I to anon, authenticated',t.tablename);
 end loop;
end $$;
grant usage on schema private to anon,authenticated;
revoke all on all functions in schema private from public;
grant execute on all functions in schema private to anon,authenticated;
create policy profile_read on public.profiles for select using(private.can_view_profile(id));
create policy settings_read on public.account_settings for select using(user_id=auth.uid() or private.is_admin());
create policy roles_read on public.user_roles for select using(user_id=auth.uid() or private.is_admin());
create policy categories_read on public.skill_categories for select using(active or private.is_admin());
create policy skills_read on public.skills for select using(true);
create policy user_skills_read on public.user_skills for select using(private.can_view_profile(user_id));
create policy interests_read on public.learning_interests for select using(user_id=auth.uid() or private.is_admin());
create policy listings_read on public.skill_listings for select using(owner_id=auth.uid() or private.is_admin() or (status='published' and visibility='public' and private.can_view_profile(owner_id)));
create policy exchanges_read on public.exchange_requests for select using(private.in_exchange(id) or private.is_admin());
create policy obligations_read on public.exchange_obligations for select using(private.in_exchange(exchange_id) or private.is_admin());
create policy exchange_history_read on public.exchange_status_history for select using(private.in_exchange(exchange_id) or private.is_admin());
create policy availability_read on public.availability_rules for select using(user_id=auth.uid() or private.is_admin());
create policy exceptions_read on public.availability_exceptions for select using(user_id=auth.uid() or private.is_admin());
create policy bookings_read on public.bookings for select using(private.in_booking(id) or private.is_admin());
create policy participants_read on public.booking_participants for select using(private.in_booking(booking_id) or private.is_admin());
create policy booking_history_read on public.booking_status_history for select using(private.in_booking(booking_id) or private.is_admin());
create policy conversations_read on public.conversations for select using(private.in_conversation(id));
create policy conversation_participants_read on public.conversation_participants for select using(private.in_conversation(conversation_id));
create policy messages_read on public.messages for select using(private.in_conversation(conversation_id));
create policy wallets_read on public.credit_wallets for select using(user_id=auth.uid() or private.is_admin());
create policy credits_read on public.credit_transactions for select using(auth.uid() in (debit_user_id,credit_user_id) or private.is_admin());
create policy reservations_read on public.credit_reservations for select using(user_id=auth.uid() or private.is_admin());
create policy payments_read on public.payments for select using(payer_id=auth.uid() or private.is_admin());
create policy webhooks_read on public.payment_webhook_events for select using(private.is_admin());
create policy reviews_read on public.reviews for select using((not hidden and private.can_view_profile(reviewee_id)) or reviewer_id=auth.uid() or private.is_admin());
create policy notifications_read on public.notifications for select using(user_id=auth.uid());
create policy reports_read on public.reports for select using(reporter_id=auth.uid() or private.is_admin());
create policy blocks_read on public.user_blocks for select using(blocker_id=auth.uid());
create policy audit_read on public.admin_audit_logs for select using(private.is_admin());
create policy outbox_read on public.email_outbox for select using(private.is_admin());
create policy meetings_read on public.booking_meetings for select using(private.in_booking(booking_id));

create function private.touch_updated_at() returns trigger language plpgsql set search_path='' as $$
 begin new.updated_at=now(); return new; end; $$;
do $$ declare t record; begin
 for t in select table_name from information_schema.columns where table_schema='public' and column_name='updated_at' loop
 execute format('create trigger touch_updated_at before update on public.%I for each row execute function private.touch_updated_at()',t.table_name);
 end loop;
end $$;
create function private.bootstrap_user() returns trigger language plpgsql security definer set search_path='' as $$
begin
 insert into public.profiles(id,full_name) values(new.id,left(coalesce(nullif(btrim(new.raw_user_meta_data->>'full_name'),''),'New learner'),100));
 insert into public.account_settings(user_id) values(new.id);
 insert into public.user_roles(user_id,role) values(new.id,'user');
 insert into public.credit_wallets(user_id) values(new.id);
 return new;
end; $$;
create trigger on_auth_user_created after insert on auth.users for each row execute function private.bootstrap_user();
-- No sign-up credit minting: grants require explicit administrative funding, idempotency and audit.
revoke all on all functions in schema private from public;
commit;
