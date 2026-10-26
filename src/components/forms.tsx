'use client';
import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { command,authAction } from '@/lib/actions';
import { createClient } from '@/lib/supabase/client';
export type Field={name:string;label:string;type?:string;required?:boolean;value?:string|number;options?:{value:string;label:string}[];hint?:string};
export function Form({op,fields=[],hidden={},redirect,label='Save',auth=false}:{op:string;fields?:Field[];hidden?:Record<string,unknown>;redirect?:string;label?:string;auth?:boolean}){
 const [error,setError]=useState('');const [success,setSuccess]=useState('');const [busy,setBusy]=useState(false);const router=useRouter();
 return <form className="form" onSubmit={async e=>{e.preventDefault();setBusy(true);setError('');setSuccess('');const fd=new FormData(e.currentTarget);const values:Record<string,unknown>={...hidden};for(const f of fields){const v=String(fd.get(f.name)??'');values[f.name]=f.type==='list'?v.split(',').map(s=>s.trim()).filter(Boolean):f.type==='checkbox'?fd.has(f.name)?'true':'false':v;}
 if(op==='message')values.nonce=crypto.randomUUID();
 const r=auth?await authAction(op,values as Record<string,string>):await command(op,values);setBusy(false);if(r.error)setError(r.error);else {setSuccess(r.success??'Saved');if(redirect)router.push(redirect.replace(':id',r.id??''));router.refresh();}
 }}>
 {fields.map(f=><label key={f.name}>{f.label}{f.type==='textarea'?<textarea name={f.name} defaultValue={f.value} required={f.required} maxLength={5000} rows={5}/>:f.options?<select name={f.name} defaultValue={f.value} required={f.required}>{f.options.map(o=><option value={o.value} key={o.value}>{o.label}</option>)}</select>:<input name={f.name} type={f.type==='list'?'text':f.type??'text'} defaultValue={f.value} required={f.required} maxLength={f.type==='password'?128:4000} min={f.type==='number'?1:undefined}/>} {f.hint&&<small>{f.hint}</small>}</label>)}
 {error&&<p className="alert error" role="alert">{error}</p>}{success&&<p className="alert" role="status">{success}</p>}<button disabled={busy} type="submit">{busy?'Saving…':label}</button>
 </form>;
}
export function AuthForm({kind}:{kind:string}){
 const [mode,setMode]=useState(kind);
 const [oauthError,setOauthError]=useState('');const [oauthBusy,setOauthBusy]=useState(false);
 async function googleSignIn(){setOauthBusy(true);setOauthError('');try{const {data,error}=await createClient().auth.signInWithOAuth({provider:'google',options:{redirectTo:`${window.location.origin}/auth/callback`}});if(error)throw error;if(!data.url)throw new Error('Google login URL unavailable');window.location.assign(data.url);}catch{setOauthError('Google sign-in is not configured yet. The site administrator must enable Google in Supabase Authentication providers.');setOauthBusy(false);}}
 const base:Field[]=[{name:'email',label:'Email address',type:'email',required:true}];
 if(mode==='register')base.unshift({name:'full_name',label:'Full name',required:true});
 if(['register','login','reset'].includes(mode))base.push({name:'password',label:'Password',type:'password',required:true,hint:'At least 10 characters'});
 if(mode==='register')base.push({name:'confirm',label:'Confirm password',type:'password',required:true},{name:'terms',label:'I accept the Terms and Privacy Policy',type:'checkbox',required:true});
 if(mode==='verify'||mode==='recover')base.push({name:'token',label:'Email code or confirmation link',required:true});
 return <>{['login','register'].includes(mode)&&<div className="form"><button type="button" className="secondary" onClick={googleSignIn} disabled={oauthBusy}>{oauthBusy?'Connecting to Google…':'Continue with Google'}</button>{oauthError&&<p className="alert error" role="alert">{oauthError}</p>}<p className="muted">Use your Google account to sign in or create a SkillBridge account without email confirmation.</p></div>}<Form key={mode} auth op={mode} fields={mode==='reset'?base.filter(f=>f.name==='password'):base} label={{register:'Create account',login:'Sign in',forgot:'Send recovery email',resend:'Resend confirmation email',verify:'Verify email',recover:'Verify recovery code',reset:'Set new password'}[mode]} redirect={mode==='login'?'/dashboard':mode==='verify'?'/onboarding':mode==='recover'?'/reset-password':undefined}/>
 {['register','login','verify'].includes(mode)&&<button className="secondary" type="button" onClick={()=>setMode('resend')}>Resend confirmation email</button>}{mode==='resend'&&<button className="secondary" type="button" onClick={()=>setMode('login')}>Back to sign in</button>}
 {mode==='register'&&<button className="secondary" onClick={()=>setMode('verify')}>Enter email code or paste confirmation link</button>}{mode==='forgot'&&<button className="secondary" onClick={()=>setMode('recover')}>Enter recovery code or paste recovery link</button>}</>;
}
