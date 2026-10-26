# SkillBridge

**Exchange Knowledge. Unlock Potential.** A database-backed peer-learning prototype built with Next.js App Router, React, TypeScript, Tailwind, and Supabase Auth/PostgreSQL/Realtime.

See [release scope and verification limits](docs/RELEASE_STATUS.md). This release does not yet meet every requirement of the original production specification.

## Run locally
Prerequisites: Node 24, npm, a Supabase project.

```sh
npm ci
cp .env.example .env.local
npm run dev
```
Set `NEXT_PUBLIC_SUPABASE_URL` and `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY` in `.env.local`. These are public client credentials; never put service-role or payment secrets in public variables or Git.

Apply all SQL files in `supabase/migrations` in order to a fresh Supabase project. For CLI use, run `npx supabase --help`, link the intended project, inspect migration status, then push migrations. Do not apply existing migrations twice to the hosted SkillBridge database.

## Authentication setup
In Supabase Authentication → URL Configuration, set the deployed site URL and allow `/auth/callback`. Enable email/password and email confirmation. Configure an SMTP provider for delivery to people outside the project team. Supabase default email has delivery restrictions and rate limits.

Use email templates containing `{{ .Token }}` for code entry, or copy the confirmation/recovery link into the application's verification field. Link verification validates the exact Supabase origin. For conventional email-link flow, configure the template and exact redirect URL; `/auth/callback` exchanges PKCE codes. Never disable verification simply to make a demonstration pass.

## Checks
```sh
npm run typecheck
npm test
npm run build
```
Vitest executes PGlite PostgreSQL migrations and 46 domain/access/workflow tests. The minimal Auth fixture is not a Supabase Auth emulator. See `docs/RELEASE_STATUS.md` for unverified scenarios.

## Deployment
1. Import `Doublezippin44/SkillBridge` in Vercel, framework Next.js, Node 24.
2. Add the two public Supabase environment variables for the intended environments.
3. Apply and verify migrations on the intended Supabase project.
4. Configure Auth email delivery, templates, site URL and callback allowlist.
5. Build/deploy the tested Git commit. Verify public routes, signup, confirmation, login and two-user workflows against the deployment.
6. Run Supabase security advisors after migrations. Enable backups and define retention before commercial use.

Optional providers are disabled. Payment, email-outbox and authenticated-video adapters remain future work; setting environment flags alone does not enable them.

## Security and operations
Business mutations execute through `public.command` (security invoker) → `private.command` (fixed search path, authenticated authorization, one database transaction). Direct table mutations remain denied. All application tables use RLS. Monetary values and actors are derived server-side. Booking participant exclusion constraints enforce no overlap. Credits settle only after dual confirmation and cannot settle twice.

The private schema must never be exposed in the Data API. Admin access comes from `user_roles`; signup metadata never assigns privileges. To bootstrap an administrator, the operator must identify a verified account and explicitly change its role through reviewed SQL. Do not grant the first visitor admin access.

## Troubleshooting
- Confirmation email missing: check Supabase Auth logs, SMTP configuration, allowed recipients and email rate limits. Do not repeatedly submit registration.
- No listings: the production marketplace intentionally starts empty. Create a real account and publish an offering.
- Zero credits: start with a direct exchange. No signup credits or payment purchases are supported.
- No available slots: publish teacher availability, choose a date 24 hours–90 days ahead, and check time zones/conflicts/daily limits.
- Private page unavailable: sign in; suspended/deletion-requested accounts cannot perform mutations.

Architecture and migration history: `docs/ARCHITECTURE.md` and `supabase/migrations`. The initial architecture document describes Phase 1 and target design; `RELEASE_STATUS.md` is authoritative for current implementation status.
