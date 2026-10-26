import 'server-only';
import { createServerClient } from '@supabase/ssr';
import { cookies } from 'next/headers';
import { supabaseConfig } from '@/config/env';
export async function createClient() {
 const config = supabaseConfig();
 const jar = await cookies();
 return createServerClient(config.url, config.publishableKey, { cookies: {
  getAll: () => jar.getAll(),
  setAll(values) { try { values.forEach(({ name, value, options }) => jar.set(name, value, options)); }
   catch { /* Server Components cannot set cookies; proxy handles refresh. */ } },
 } });
}
