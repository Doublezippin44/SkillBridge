import { createBrowserClient } from '@supabase/ssr';
import { supabaseConfig } from '@/config/env';
export function createClient() {
 const config = supabaseConfig();
 return createBrowserClient(config.url, config.publishableKey);
}
