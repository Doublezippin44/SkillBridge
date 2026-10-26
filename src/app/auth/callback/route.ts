import {NextRequest,NextResponse} from 'next/server';
import {createClient} from '@/lib/supabase/server';
export async function GET(req:NextRequest){const db=await createClient();const code=req.nextUrl.searchParams.get('code');if(code){const {error}=await db.auth.exchangeCodeForSession(code);if(!error)return NextResponse.redirect(new URL('/dashboard',req.url));}return NextResponse.redirect(new URL('/login',req.url));}
