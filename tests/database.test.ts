import { PGlite } from '@electric-sql/pglite';
import { btree_gist } from '@electric-sql/pglite/contrib/btree_gist';
import { readdirSync, readFileSync } from 'node:fs';
import { beforeAll, afterAll, afterEach, describe, expect, it } from 'vitest';
let db: PGlite;
const a='10000000-0000-4000-8000-000000000001';
const b='10000000-0000-4000-8000-000000000002';
const c='10000000-0000-4000-8000-000000000003';
const listing='20000000-0000-4000-8000-000000000001';
const booking='30000000-0000-4000-8000-000000000001';
const conversation='40000000-0000-4000-8000-000000000001';
async function asUser(uid:string) { await db.exec(`set role authenticated; select set_config('request.jwt.claim.sub','${uid}',false);`); }
beforeAll(async()=>{
 db=new PGlite({extensions:{btree_gist}});
 // Minimal Auth contract for isolated PostgreSQL checks; not a Supabase Auth service emulator.
 await db.exec(`create role anon; create role authenticated; create schema auth;
 create table auth.users(id uuid primary key,raw_user_meta_data jsonb default '{}');
 create function auth.uid() returns uuid language sql stable as $$ select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid $$;
 grant usage on schema auth to anon,authenticated; grant execute on function auth.uid() to anon,authenticated;`);
 for(const file of readdirSync('supabase/migrations').filter(f=>f.endsWith('.sql')).sort()) await db.exec(readFileSync(`supabase/migrations/${file}`,'utf8'));
 await db.exec(`insert into auth.users(id,raw_user_meta_data) values('${a}','{"full_name":"Alice","role":"admin"}'),('${b}','{"full_name":"Bob"}'),('${c}','{"full_name":"Carol"}');
 insert into skill_categories(id,name,slug) values('50000000-0000-4000-8000-000000000001','Test Programming','test-programming');
 insert into skills(id,category_id,name) values('60000000-0000-4000-8000-000000000001','50000000-0000-4000-8000-000000000001','Python');
 insert into user_skills(id,user_id,skill_id,level) values('70000000-0000-4000-8000-000000000001','${a}','60000000-0000-4000-8000-000000000001','advanced');
 insert into skill_listings(id,owner_id,user_skill_id,title,description,format,duration_minutes,languages,modes,status)
 values('${listing}','${a}','70000000-0000-4000-8000-000000000001','Learn Python','Learn Python through practical exercises','online',60,'{English}','{credits}','published');
 insert into bookings(id,listing_id,teacher_id,learner_id,mode,starts_at,ends_at,credit_cost,cancellation_cutoff_at,policy_version)
 values('${booking}','${listing}','${a}','${b}','credits','2026-12-01 10:00Z','2026-12-01 11:00Z',4,'2026-11-30 10:00Z','v1');
 insert into booking_participants(booking_id,user_id,occupied_range) values('${booking}','${a}','[2026-12-01 10:00Z,2026-12-01 11:15Z)'),('${booking}','${b}','[2026-12-01 10:00Z,2026-12-01 11:15Z)');
 insert into conversations(id) values('${conversation}');
 insert into conversation_participants(conversation_id,user_id) values('${conversation}','${a}'),('${conversation}','${b}');
 insert into messages(conversation_id,sender_id,body,client_nonce) values('${conversation}','${a}','Hello Bob',gen_random_uuid());`);
});
afterEach(async()=>{ await db.exec('reset role;'); });
afterAll(async()=>{ await db?.close(); });
describe('foundation migration and constraints',()=>{
 it('enables RLS on every public table',async()=>{const r=await db.query<{relname:string}>("select relname from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='public' and relkind='r' and not relrowsecurity");expect(r.rows).toEqual([]);});
 it('creates all 26 required tables',async()=>{const required='profiles user_roles skill_categories skills user_skills learning_interests skill_listings exchange_requests exchange_obligations availability_rules availability_exceptions bookings booking_status_history conversations conversation_participants messages credit_wallets credit_transactions credit_reservations payments payment_webhook_events reviews notifications reports user_blocks admin_audit_logs'.split(' ');const r=await db.query<{tablename:string}>("select tablename from pg_tables where schemaname='public'");expect(r.rows.map(x=>x.tablename)).toEqual(expect.arrayContaining(required));});
 it('bootstraps a zero-balance wallet and rejects metadata admin escalation',async()=>{const r=await db.query<{role:string,balance:number}>(`select role,balance from user_roles join credit_wallets using(user_id) where user_id='${a}'`);expect(r.rows[0]).toEqual({role:'user',balance:0});});
 it('rejects over-reservation',async()=>{await expect(db.exec(`update credit_wallets set reserved=1 where user_id='${a}'`)).rejects.toThrow();});
 it('rejects overlapping participant slots including buffers',async()=>{
 const second='30000000-0000-4000-8000-000000000002';
 await db.exec(`insert into bookings(id,listing_id,teacher_id,learner_id,mode,starts_at,ends_at,credit_cost,cancellation_cutoff_at,policy_version)
 values('${second}','${listing}','${a}','${b}','credits','2026-12-01 11:00Z','2026-12-01 12:00Z',4,'2026-11-30 10:00Z','v1')`);
 await expect(db.exec(`insert into booking_participants(booking_id,user_id,occupied_range) values('${second}','${b}','[2026-12-01 11:00Z,2026-12-01 12:15Z)')`)).rejects.toMatchObject({code:'23P01'});
 });
 it('rejects invalid ratings',async()=>{await expect(db.exec(`insert into reviews(booking_id,reviewer_id,reviewee_id,rating,communication,punctuality,feedback) values('${booking}','${b}','${a}',6,5,5,'Invalid')`)).rejects.toThrow();});
 it('rejects duplicate credit settlement',async()=>{await db.exec(`insert into credit_transactions(debit_user_id,credit_user_id,booking_id,amount,kind,idempotency_key,reason) values('${b}','${a}','${booking}',4,'settlement','settle:one','test fixture')`);await expect(db.exec(`insert into credit_transactions(debit_user_id,credit_user_id,booking_id,amount,kind,idempotency_key,reason) values('${b}','${a}','${booking}',4,'settlement','settle:two','test fixture')`)).rejects.toThrow();});
 it('rejects duplicate webhook IDs',async()=>{await db.exec("insert into payment_webhook_events(provider_event_id,event_type,payload_hash) values('event_1','test','hash')");await expect(db.exec("insert into payment_webhook_events(provider_event_id,event_type,payload_hash) values('event_1','test','hash')")).rejects.toThrow();});
});
describe('actual PostgreSQL RLS under unprivileged roles',()=>{
 it('allows public discovery but hides account settings',async()=>{await db.exec("set role anon; select set_config('request.jwt.claim.sub','',false)");expect((await db.query('select id from skill_listings')).rows).toHaveLength(1);expect((await db.query('select * from account_settings')).rows).toHaveLength(0);});
 it('only reveals the current user wallet',async()=>{await asUser(a);expect((await db.query('select user_id from credit_wallets')).rows).toEqual([{user_id:a}]);});
 it('denies unauthorized profile writes at the grant boundary',async()=>{await asUser(b);await expect(db.exec(`update profiles set full_name='Tampered' where id='${a}'`)).rejects.toThrow();});
 it('denies client wallet manipulation',async()=>{await asUser(a);await expect(db.exec(`update credit_wallets set balance=999 where user_id='${a}'`)).rejects.toThrow();});
 it('allows participants to read messages without recursive policies',async()=>{await asUser(b);expect((await db.query('select body from messages')).rows).toEqual([{body:'Hello Bob'}]);});
 it('hides conversations, messages, and bookings from outsiders',async()=>{await asUser(c);for(const table of ['conversations','conversation_participants','messages','bookings'])expect((await db.query(`select * from ${table}`)).rows).toHaveLength(0);});
 it('hides messages after blocking',async()=>{await db.exec(`insert into user_blocks(blocker_id,blocked_id) values('${b}','${a}')`);await asUser(a);expect((await db.query('select * from messages')).rows).toHaveLength(0);await db.exec(`reset role; delete from user_blocks;`);});
 it('hides suspended providers from public discovery',async()=>{await db.exec(`update account_settings set status='suspended' where user_id='${a}'; set role anon; select set_config('request.jwt.claim.sub','',false)`);expect((await db.query('select * from skill_listings')).rows).toHaveLength(0);await db.exec(`reset role; update account_settings set status='active' where user_id='${a}'`);});
 it('does not expose admin data to regular users',async()=>{await asUser(a);expect((await db.query('select * from payment_webhook_events')).rows).toHaveLength(0);});
});
