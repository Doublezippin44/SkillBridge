# SkillBridge early release — actual scope

This is a functional prototype, not completion of the entire original production specification.

## Implemented
- Next.js SSR marketing, public discovery, profile pages, protected application pages.
- Supabase password registration/login/logout, verification/recovery code or link exchange, password reset. Email delivery requires a working Supabase Auth mail setup and is not yet verified with a real mailbox.
- Persistent profile, visibility, onboarding completion, learning interests, skill offering create/edit/publish/archive/delete.
- Combined keyword/category/level/language/format/mode discovery filters with pagination. Newest/oldest sorting.
- Transparent recommendations: skill 40, reciprocal 25, weekly overlap 15, language 10, level 10. Availability overlap currently scores only matching IANA zones. Candidate cap 200.
- Direct exchange propose/accept/reject/cancel pending proposals; two obligations; booking and completion tracking.
- Real available-slot query, UTC booking, weekly local IANA availability, exceptions enforced in database, 24-hour notice/cancellation, buffers, maximum daily sessions, cross-role conflict constraint.
- Transactional credit reserve/release/settle. Mutual completion after end time. Unique settlement protects retries. Zero initial credits; direct swaps cost none.
- Private conversations, text messages, idempotent sending, block/report, Supabase Realtime publication with polling reconciliation.
- In-app notifications/read state; verified participant reviews.
- Admin-only user suspension/reactivation, listing moderation, report decisions, ledger inspection, completion rate; audit logs.

## Incomplete requirements / release limitations
- Production email/redirect configuration and real-mailbox signup/reset E2E verification.
- Optional Google OAuth, Resend, Razorpay and authenticated Jitsi adapters are not implemented/configured. These are disabled, not fake-success controls. Users coordinate external private meetings through messages.
- Avatar Storage uploads, stepped onboarding navigation/preferences, notification preferences, unread badges/read receipts/search/message pagination, reminder jobs.
- Rating/relevance sorting; rating distributions; cross-time-zone overlap scoring; large-scale candidate/filter optimization.
- Rescheduling, accepted-exchange cancellation/disputes, no-show adjudication, availability-exception UI, configurable scheduling policy UI.
- Admin category CRUD, richer analytics, dispute resolution UI and audited credit grants. Initial credit issuance still requires operator-reviewed SQL. No arbitrary user credit minting.
- Full 13-step multi-user Playwright suite, concurrency stress test, browser accessibility/mobile QA. PostgreSQL tests exercise transactions sequentially, not concurrent network clients.
- Development-only fictional data generator and complete academic diagram set.

## Test evidence
46 actual Vitest tests passed: pure domain rules, PostgreSQL schema/RLS, and transactional workflows. TypeScript checks and the production Next.js build passed. Hosted Supabase security advisor returned zero findings after core workflow migration. The browser download failed in this environment; browser tests must not be represented as passing.

The hosted public API responds successfully for taxonomy and joined listing discovery. A signup probe using an example.com test email was rejected by Supabase as an invalid address; it does not establish real email deliverability.

## Deployment attempt
Vercel project `prj_rWkhLh7gtmmTSHM8mb9T3ACsmpYN` was created with the public Supabase variables. Deployment `dpl_BxsHpW4CxZYnkxp8G8nsFPiJ5rLV` for commit `ac116e0b043d13a91a046055ec4174d80a05526a` was accepted and last reported QUEUED. Its public alias returned DEPLOYMENT_NOT_FOUND during browser verification. Vercel subsequently denied deployment/log inspection with 403, requiring team authorization for `pirate-apollo`. Live deployment is therefore **not verified**. Do not advertise this as the final product.

Hosted migration filenames were aligned with the actual Supabase migration versions to avoid applying the same schema twice via the CLI. The final hosted security advisor check after both feature migrations returned zero findings.
