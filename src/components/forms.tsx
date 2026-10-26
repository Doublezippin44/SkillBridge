'use client';
import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { command,authAction } from '@/lib/actions';
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
 const base:Field[]=[{name:'email',label:'Email address',type:'email',required:true}];
 if(mode==='register')base.unshift({name:'full_name',label:'Full name',required:true});
 if(['register','login','reset'].includes(mode))base.push({name:'password',label:'Password',type:'password',required:true,hint:'At least 10 characters'});
 if(mode==='register')base.push({name:'confirm',label:'Confirm password',type:'password',required:true},{name:'terms',label:'I accept the Terms and Privacy Policy',type:'checkbox',required:true});
 if(mode==='verify'||mode==='recover')base.push({name:'token',label:'Email code or confirmation link',required:true});
 return <><Form key={mode} auth op={mode} fields={mode==='reset'?base.filter(f=>f.name==='password'):base} label={{register:'Create account',login:'Sign in',forgot:'Send recovery email',verify:'Verify email',recover:'Verify recovery code',reset:'Set new password'}[mode]} redirect={mode==='login'?'/dashboard':mode==='verify'?'/onboarding':mode==='recover'?'/reset-password':undefined}/>
 {mode==='register'&&<button className="secondary" onClick={()=>setMode('verify')}>Enter email code or paste confirmation link</button>}{mode==='forgot'&&<button className="secondary" onClick={()=>setMode('recover')}>Enter recovery code or paste recovery link</button>}</>;
}
