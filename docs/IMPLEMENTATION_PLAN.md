# Incremental implementation and evidence gates

Every phase ends with changed-file inventory, actual executed checks, failures/fixes and integration status. A checked phase means its scoped acceptance gate passed, not that the entire product is production-ready.

| Phase | Scope | Acceptance gate | Status |
|---|---|---|---|
| 1 | Architecture, schema, route contract, Next.js scaffold and tooling | Migration executes; RLS/constraints tested; typecheck and build | Implemented, see VERIFICATION.md |
| 2 | Auth, terms acceptance, onboarding, profile, listing CRUD and discovery | Two verified users; ownership/validation negatives; filters combine correctly | Next |
| 3 | Candidate query, component derivation, exchange RPCs and obligation tracking | Reciprocal and one-way recommendations; actor/state/duplicate rejection | Planned |
| 4 | UTC scheduling, DST availability, reservations, settlement and refunds | Concurrent booking/credit tests; replay-safe settlement; reschedule rollback | Planned |
| 5 | Conversations, Realtime, notifications/outbox and meeting authorization | Unauthorized readers blocked; reconnect reconciliation; email outage resilience | Planned |
| 6 | Verified reviews, payment adapter, admin moderation and analytics | Review eligibility; forged/replayed webhook negatives; audited admin actions | Planned |
| 7 | Full multi-user E2E, accessibility, security, performance | All critical workflows executed; advisors clean or justified; measured query plans | Planned |
| 8 | Production configuration, migration, release, live verification and final report | New user can complete real end-to-end workflow on live URL | Planned |

## Requirement coverage / no silent omissions
Sections 1–4: framework/configuration in Phase 1; all actual Auth forms, verification, reset, OAuth and secure route rendering in Phase 2.
Sections 5–9: marketing sections with clearly labelled samples, persistent onboarding, database dashboards, complete skill CRUD/discovery in Phase 2; dashboard sections expand with each subsequent workflow.
Sections 10–11: scoring primitive exists; candidate queries, explainable recommendations and complete exchanges in Phase 3.
Section 12 and credit requirements: Phase 4 transactional functions, availability UI, policy snapshots and reconciliation.
Sections 13–14 and 16: Phase 5 messaging, notifications/preferences, reminders, Resend outbox, secure optional meetings.
Sections 15, 17–18: profiles/settings begin Phase 2; verified review aggregates, moderation, suspension, disputes and real analytics Phase 6.
Section 19: all required tables and baseline RLS in Phase 1; subsequent migrations add verified mutation contracts and integration policies.
Section 20: all routes inventoried in Phase 1; real route implementations appear only with functional workflows.
Sections 21–22: least privilege from Phase 1; rate limits, CSRF checks, secure uploads and measured caching/query performance before launch.
Section 23: development-only seed in Phase 7 after the workflows it seeds exist; no shared public demo passwords.
Section 24: pure-domain and real isolated PostgreSQL tests in Phase 1; provider/integration/Playwright tests accompany their phases.
Section 25: reproducible setup documented from Phase 1; actual Vercel publication and verified URL only in Phase 8.
Section 26: architecture, ER and route docs Phase 1; final SRS and all requested diagram types updated against implemented behavior in Phase 8.
Sections 27–29: phased checks, honest evidence, explicit blockers and no simulated completed features throughout.

## Planned test cases

| ID | Scenario | Expected result |
|---|---|---|
| AUTH-01 | Register, confirm email, sign in, log out and reset | Correct cookie session and profile; no privilege escalation |
| CRUD-01 | Create/edit/archive own listing; edit another user's listing | Own changes persist; other user's change denied |
| FIND-01 | Combine category, language, format, level, mode and pagination | Stable filtered results; empty state when none |
| MATCH-01 | Reciprocal Python/design fixture and one-way alternative | Explained deterministic ranking; blocked/inactive excluded |
| EX-01 | Propose, accept, fulfill both obligations | Correct actor transitions and linked distinct sessions |
| BOOK-01 | Concurrent requests for same learner/teacher time | Exactly one succeeds, no orphan hold |
| BOOK-02 | DST gap, repeated hour, buffers, daily cap and reschedule | Correct UTC slots and atomic conflict rejection |
| CREDIT-01 | Insufficient credits, cancellation, repeat settlement | No overspend; hold released once; transfer once |
| MSG-01 | Two-user exchange, reconnect, unauthorized third user | Persistent authorized messages and read counts |
| REVIEW-01 | Incomplete, nonparticipant, duplicate and completed session | First three rejected; eligible review changes aggregates |
| PAY-01 | Invalid HMAC, wrong amount, duplicate event and out-of-order event | Invalid events rejected; no duplicate settlement/refund |
| ADMIN-01 | Ordinary user calls admin action; admin suspends user | Unauthorized rejected; valid action logged and enforced |
| E2E-01 | Full two-account register → onboarding → listing → exchange → booking → message → completion → review | Dashboard and ledger reconcile with persisted activity |

These are test specifications, not claimed executed integration/E2E results.
