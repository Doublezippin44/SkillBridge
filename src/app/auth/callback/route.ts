import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/server';

// The callback exchanges one-time codes on the server so auth cookies are set securely.
// Only known local destinations are allowed after the exchange.
export async function GET(req: NextRequest) {
  const url = req.nextUrl;
  const db = await createClient();
  const code = url.searchParams.get('code');
  const tokenHash = url.searchParams.get('token_hash');
  const type = url.searchParams.get('type');
  const isRecovery = type === 'recovery' || url.searchParams.get('next') === 'reset-password';

  if (code) {
    const { error } = await db.auth.exchangeCodeForSession(code);
    if (!error) return NextResponse.redirect(new URL(isRecovery ? '/reset-password' : '/dashboard', url.origin));
  } else if (tokenHash && (type === 'email' || type === 'signup' || type === 'recovery')) {
    // Supports a scanner-resistant custom Supabase template with TokenHash links.
    const { error } = await db.auth.verifyOtp({
      token_hash: tokenHash,
      type: type === 'recovery' ? 'recovery' : 'email',
    });
    if (!error) return NextResponse.redirect(new URL(isRecovery ? '/reset-password' : '/dashboard', url.origin));
  }

  const fallback = new URL('/login', url.origin);
  fallback.searchParams.set('auth_error', 'verification');
  return NextResponse.redirect(fallback);
}
