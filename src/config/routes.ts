// Contract only: planned routes do not masquerade as implemented pages.
export const routes = [
  {
    "path": "/",
    "access": "public",
    "status": "foundation-only"
  },
  {
    "path": "/login",
    "access": "public",
    "status": "planned"
  },
  {
    "path": "/register",
    "access": "public",
    "status": "planned"
  },
  {
    "path": "/forgot-password",
    "access": "public",
    "status": "planned"
  },
  {
    "path": "/reset-password",
    "access": "public",
    "status": "planned"
  },
  {
    "path": "/explore",
    "access": "public",
    "status": "planned"
  },
  {
    "path": "/skills/[id]",
    "access": "public",
    "status": "planned"
  },
  {
    "path": "/users/[id]",
    "access": "public",
    "status": "planned"
  },
  {
    "path": "/how-it-works",
    "access": "public",
    "status": "planned"
  },
  {
    "path": "/about",
    "access": "public",
    "status": "planned"
  },
  {
    "path": "/contact",
    "access": "public",
    "status": "planned"
  },
  {
    "path": "/privacy",
    "access": "public",
    "status": "planned"
  },
  {
    "path": "/terms",
    "access": "public",
    "status": "planned"
  },
  {
    "path": "/dashboard",
    "access": "member",
    "status": "planned"
  },
  {
    "path": "/onboarding",
    "access": "member",
    "status": "planned"
  },
  {
    "path": "/profile",
    "access": "member",
    "status": "planned"
  },
  {
    "path": "/profile/edit",
    "access": "member",
    "status": "planned"
  },
  {
    "path": "/my-skills",
    "access": "member",
    "status": "planned"
  },
  {
    "path": "/my-skills/new",
    "access": "member",
    "status": "planned"
  },
  {
    "path": "/my-skills/[id]/edit",
    "access": "member",
    "status": "planned"
  },
  {
    "path": "/matches",
    "access": "member",
    "status": "planned"
  },
  {
    "path": "/exchanges",
    "access": "member",
    "status": "planned"
  },
  {
    "path": "/exchanges/[id]",
    "access": "member",
    "status": "planned"
  },
  {
    "path": "/bookings",
    "access": "member",
    "status": "planned"
  },
  {
    "path": "/bookings/[id]",
    "access": "member",
    "status": "planned"
  },
  {
    "path": "/calendar",
    "access": "member",
    "status": "planned"
  },
  {
    "path": "/messages",
    "access": "member",
    "status": "planned"
  },
  {
    "path": "/messages/[id]",
    "access": "member",
    "status": "planned"
  },
  {
    "path": "/wallet",
    "access": "member",
    "status": "planned"
  },
  {
    "path": "/wallet/history",
    "access": "member",
    "status": "planned"
  },
  {
    "path": "/notifications",
    "access": "member",
    "status": "planned"
  },
  {
    "path": "/settings",
    "access": "member",
    "status": "planned"
  },
  {
    "path": "/admin",
    "access": "admin",
    "status": "planned"
  },
  {
    "path": "/admin/users",
    "access": "admin",
    "status": "planned"
  },
  {
    "path": "/admin/skills",
    "access": "admin",
    "status": "planned"
  },
  {
    "path": "/admin/bookings",
    "access": "admin",
    "status": "planned"
  },
  {
    "path": "/admin/reports",
    "access": "admin",
    "status": "planned"
  },
  {
    "path": "/admin/transactions",
    "access": "admin",
    "status": "planned"
  },
  {
    "path": "/admin/analytics",
    "access": "admin",
    "status": "planned"
  }
] as const;
