# Route contract

Only `/` (development foundation), loading, error and not-found UI exist in Phase 1. All other paths below are reserved directories, not placeholder product screens.

| Route | Access | Status |
|---|---|---|
| `/` | public | foundation-only |
| `/login` | public | planned |
| `/register` | public | planned |
| `/forgot-password` | public | planned |
| `/reset-password` | public | planned |
| `/explore` | public | planned |
| `/skills/[id]` | public | planned |
| `/users/[id]` | public | planned |
| `/how-it-works` | public | planned |
| `/about` | public | planned |
| `/contact` | public | planned |
| `/privacy` | public | planned |
| `/terms` | public | planned |
| `/dashboard` | member | planned |
| `/onboarding` | member | planned |
| `/profile` | member | planned |
| `/profile/edit` | member | planned |
| `/my-skills` | member | planned |
| `/my-skills/new` | member | planned |
| `/my-skills/[id]/edit` | member | planned |
| `/matches` | member | planned |
| `/exchanges` | member | planned |
| `/exchanges/[id]` | member | planned |
| `/bookings` | member | planned |
| `/bookings/[id]` | member | planned |
| `/calendar` | member | planned |
| `/messages` | member | planned |
| `/messages/[id]` | member | planned |
| `/wallet` | member | planned |
| `/wallet/history` | member | planned |
| `/notifications` | member | planned |
| `/settings` | member | planned |
| `/admin` | admin | planned |
| `/admin/users` | admin | planned |
| `/admin/skills` | admin | planned |
| `/admin/bookings` | admin | planned |
| `/admin/reports` | admin | planned |
| `/admin/transactions` | admin | planned |
| `/admin/analytics` | admin | planned |

Member pages require a validated user and active account. Admin pages and every admin mutation independently require a database-backed admin role. Listing/exchange/booking/message IDs additionally require ownership or participation checks. Proxy refresh is not an authorization boundary. Add `/auth/callback`, `/auth/confirm`, `/api/webhooks/razorpay`, and an authenticated worker endpoint when their integrations are implemented.
