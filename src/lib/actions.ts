'use server';
import { createClient } from '@/lib/supabase/server';
import { requireUser } from '@/lib/auth';
import { revalidatePath } from 'next/cache';
import { z } from 'zod';
export type ActionResult = { error?: string; success?: string; id?: string };
const emailSchema=z.email().max(254); const passwordSchema=z.string().min(10).max(128);
export async function authAction(kind:string, data:Record<string,string>):Promise<ActionResult>{
 const db=await createClient();
 if(kind==='logout'){await db.auth.signOut();revalidatePath('/','layout');return {success:'Signed out'};}
 if(kind==='reset'){if(!passwordSchema.safeParse(data.password).success)return {error:'Use a password of 10–128 characters.'};const {error}=await db.auth.updateUser({password:data.password});return error?{error:'Unable to change password. Request a new recovery code.'}:{success:'Password changed. You can sign in.'};}
 if(!emailSchema.safeParse(data.email).success)return {error:'Enter a valid email address.'};
 if(kind==='verify'||kind==='recover'){
 let result;
 try { const link=new URL(data.token); if(link.origin!==process.env.NEXT_PUBLIC_SUPABASE_URL||link.pathname!=='/auth/v1/verify')return {error:'Use the confirmation link from your SkillBridge email.'}; const token_hash=link.searchParams.get('token');if(!token_hash)return {error:'Invalid confirmation link.'};result=await db.auth.verifyOtp({token_hash,type:kind==='recover'?'recovery':'signup'}); }
 catch {result=await db.auth.verifyOtp({email:data.email,token:data.token,type:kind==='recover'?'recovery':'signup'});}
 return result.error?{error:'The code or link is invalid or expired.'}:{success:'Verified'};
 }
 if(kind==='resend'){const {error}=await db.auth.resend({type:'signup',email:data.email,options:{emailRedirectTo:'https://skillbridge-n55pb9y5s-pirate-apollo.vercel.app/auth/callback'}});return error?{error:error.status===429?'Too many emails requested. Wait before retrying.':'Could not send confirmation email. Check email delivery configuration.'}:{success:'If this account needs confirmation, a new verification email has been requested. Check inbox and spam.'};}
 if(kind==='forgot'){const {error}=await db.auth.resetPasswordForEmail(data.email,{redirectTo:'https://skillbridge-n55pb9y5s-pirate-apollo.vercel.app/auth/callback'});return error?{error:'Recovery email could not be sent. Try again later.'}:{success:'If your account exists, check your email for a recovery code.'};}
 if(!passwordSchema.safeParse(data.password).success)return {error:'Use a password of 10–128 characters.'};
 if(kind==='register'){
 if(data.password!==data.confirm||data.terms!=='true'||!data.full_name?.trim())return {error:'Confirm your password, enter your name, and accept the terms.'};
 const {data:result,error}=await db.auth.signUp({email:data.email,password:data.password,options:{emailRedirectTo:'https://skillbridge-n55pb9y5s-pirate-apollo.vercel.app/auth/callback',data:{full_name:data.full_name.trim().slice(0,100)}}});
 if(error)return {error:'Registration could not be completed. Check your email address or try again later.'};
 return {success:result.session?'Signed in':'Check your email to confirm your account.'};
 }
 const {error}=await db.auth.signInWithPassword({email:data.email,password:data.password});
 if(error)return {error:'Incorrect email or password, or email not yet verified.'};
 revalidatePath('/','layout');return {success:'Signed in'};
}
export async function command(op:string,payload:Record<string,unknown>):Promise<ActionResult>{
 try{
 const {db}=await requireUser();
 if(!z.string().max(40).safeParse(op).success||JSON.stringify(payload).length>16000)return {error:'Invalid request.'};
 const {data,error}=await db.rpc('command',{op,payload});
 if(error){
 const safe=['Sign in','Please wait','Choose','Listing unavailable','Paid sessions','Invalid','Skill must','User unavailable','Exchange unavailable','All exchange','Outside teacher','Daily booking','Book between','Insufficient credits','Booking unavailable','Booking is no','Cancellation closes','Confirm completion','Conversation unavailable','Only completed','Administrator','This listing'];
 if(error.code==='23P01')return {error:'This time overlaps an existing session. Choose another slot.'};
 if(error.code==='23505')return {error:'This action was already recorded.'};
 return {error:safe.some(p=>error.message.startsWith(p))?error.message:'Unable to save. Check the fields and try again.'};
 }
 revalidatePath('/','layout');return {success:'Saved successfully',...data};
 }catch{return {error:'Please sign in with an active account.'};}
}
export async function availableSlots(listing:string,day:string){
 if(!z.uuid().safeParse(listing).success||!/^\d{4}-\d{2}-\d{2}$/.test(day))return {error:'Choose a valid date.',slots:[]};
 try{const {db}=await requireUser();const {data,error}=await db.rpc('available_slots',{listing,day});return error?{error:'Could not load availability.',slots:[]}:{slots:data as {starts_at:string;ends_at:string}[]};}catch{return {error:'Please sign in.',slots:[]};}
}
