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
- SMTP delivery for arbitrary non-team email addresses, final Auth dashboard URL allowlist, and full real-browser signup/reset E2E verification. One real confirmation email was observed; deliverability to other users is not established.
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

## October 26, 2026: deployed prototype and authentication corrections
Vercel production has a READY deployment on the stable alias https://skillbridge-pirate-apollo.vercel.app. This is confirmation of a successful build and alias assignment, **not** evidence that every browser user journey passed.

An existing registration in Supabase Auth was observed to be email-confirmed and active. Repeating signup for a confirmed account will not generate another confirmation email. The original confirmation link had redirected to localhost and subsequent clicks produced an expired-token error; the account nevertheless became confirmed.

Repository changes added an explicit resend action, changed signup/recovery redirects to the stable production alias, fixed recovery callback routing to the password-reset form, and displayed recovery errors. The homepage now renders dynamically so CI need not read Supabase credentials at static build time. Earlier GitHub CI runs had 46 passing tests and TypeScript checks, but failed at page prerender with missing CI environment variables; the corrected code compiled and built on Vercel. A successful GitHub Actions rerun has not been independently established.

**Remaining launch gate:** the operator must securely configure SMTP and verify the Supabase Auth Site URL / redirect allowlist. The connected project tools did not provide Auth SMTP/template/URL configuration writes. This cannot be completed just by editing application source. The email-confirmation flow for new non-team addresses is still not verified, and payment/video optional features remain disabled.
