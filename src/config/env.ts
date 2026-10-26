import { z } from 'zod';
const schema = z.object({ url: z.url(), publishableKey: z.string().min(1) });
export function supabaseConfig() {
 const parsed = schema.safeParse({ url: process.env.NEXT_PUBLIC_SUPABASE_URL, publishableKey: process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY });
 if (!parsed.success) throw new Error('Supabase is not configured. See .env.example.');
 return parsed.data;
}
