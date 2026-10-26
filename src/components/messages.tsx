'use client';
import {useEffect,useState} from 'react';
import {createClient} from '@/lib/supabase/client';
import {command} from '@/lib/actions';
import {Form} from './forms';
export function Messages({initial,conversationId,userId}:{initial:any[];conversationId:string;userId:string}){
 const [messages,setMessages]=useState(initial);const [status,setStatus]=useState('Connecting…');
 useEffect(()=>{setMessages(initial)},[initial]);
 useEffect(()=>{const db=createClient();void command('read_messages',{id:conversationId});const channel=db.channel('messages:'+conversationId).on('postgres_changes',{event:'INSERT',schema:'public',table:'messages',filter:'conversation_id=eq.'+conversationId},e=>{setMessages(m=>m.some(x=>x.id===e.new.id)?m:[...m,e.new]);void command('read_messages',{id:conversationId});}).subscribe(s=>setStatus(s==='SUBSCRIBED'?'Live updates connected':'Reconnecting…'));
 const timer=setInterval(async()=>{const {data,error}=await db.from('messages').select('*').eq('conversation_id',conversationId).order('created_at',{ascending:false}).limit(100);if(!error&&data)setMessages(data.reverse());},15000);
 return()=>{clearInterval(timer);void db.removeChannel(channel);};},[conversationId]);
 return <><small>{status}</small><div className="messages" aria-live="polite">{messages.length?messages.map(m=><div className={'message '+(m.sender_id===userId?'mine':'')} key={m.id}><p>{m.body}</p><small>{new Date(m.created_at).toLocaleString()}</small></div>):<p className="muted">Say hello. Your conversation is private.</p>}</div><Form op="message" hidden={{conversation_id:conversationId}} fields={[{name:'body',label:'Message',type:'textarea',required:true}]} label="Send message"/></>;
}
