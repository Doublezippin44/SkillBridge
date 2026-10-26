import Link from 'next/link';
import { redirect } from 'next/navigation';
import { createClient } from '@/lib/supabase/server';

// An email scanner may visit a URL with a GET request.
// Never consume a one-time token merely by rendering this page.
// Only a deliberate form submission verifies the token.
export const dynamic = 'force-dynamic';

async function completeConfirmation(formData: FormData) {
  'use server';

  const tokenHash = formData.get('token_hash');
  const type = formData.get('type');
  const validToken = typeof tokenHash === 'string' && /^[a-zA-Z0-9_-]{16,1024}$/.test(tokenHash);
  if (!validToken || (type !== 'email' && type !== 'recovery')) {
    redirect('/login?auth_error=verification');
  }

  const supabase = await createClient();
  const { error } = await supabase.auth.verifyOtp({
    token_hash: tokenHash,
    type,
  });

  if (error) redirect('/login?auth_error=verification');
  redirect(type === 'recovery' ? '/reset-password' : '/dashboard');
}

export default async function ConfirmEmail({
  searchParams,
}: {
  searchParams: Promise<{ token_hash?: string; type?: string }>;
}) {
  const { token_hash: tokenHash, type } = await searchParams;
  const recovery = type === 'recovery';
  const valid = typeof tokenHash === 'string' && /^[a-zA-Z0-9_-]{16,1024}$/.test(tokenHash)
    && (type === 'email' || type === 'recovery');

  return (
    <section className="auth card">
      <div className="eyebrow">SkillBridge security</div>
      <h1>{recovery ? 'Reset your password.' : 'Confirm your email.'}</h1>
      {valid ? (
        <>
          <p className="muted">
            {recovery
              ? 'Click below to verify your password-recovery request and choose a new password.'
              : 'Click below to complete verification and open your SkillBridge account.'}
          </p>
          <form action={completeConfirmation} className="form">
            <input type="hidden" name="token_hash" value={tokenHash} />
            <input type="hidden" name="type" value={type} />
            <button type="submit">
              {recovery ? 'Continue password reset' : 'Confirm email address'}
            </button>
          </form>
          <p><small>Your link is used only after you press the button.</small></p>
        </>
      ) : (
        <>
          <p className="alert error" role="alert">
            This verification link is missing information or is no longer valid.
            Please request a new email using the account registration or recovery page.
          </p>
          <Link href={recovery ? '/forgot-password' : '/register'} className="button">
            Request a new link
          </Link>
        </>
      )}
      <p><Link className="textlink" href="/login">Back to sign in</Link></p>
    </section>
  );
}
