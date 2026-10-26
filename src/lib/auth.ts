import 'server-only';
import { createClient } from '@/lib/supabase/server';
export async function requireUser() {
 const db = await createClient();
 const { data: { user }, error } = await db.auth.getUser();
 if (error || !user) throw new Error('Authentication required');
 const { data: account, error: accountError } = await db.from('account_settings').select('status').eq('user_id', user.id).single();
 if (accountError || account?.status !== 'active') throw new Error('Account unavailable');
 return { db, user };
}
export async function requireAdmin() {
 const context = await requireUser();
 const { data, error } = await context.db.from('user_roles').select('role').eq('user_id', context.user.id).single();
 if (error || data?.role !== 'admin') throw new Error('Administrator access required');
 return context;
}
