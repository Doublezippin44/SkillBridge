import type { Metadata } from 'next';
import Link from 'next/link';
import { createClient } from '@/lib/supabase/server';
import './globals.css';
export const metadata:Metadata={title:'SkillBridge · Exchange Knowledge. Unlock Potential.',description:'Learn something new by teaching what you know. Connect, exchange skills, and grow together.'};
export default async function RootLayout({children}:{children:React.ReactNode}){
 let signedIn=false;try{const db=await createClient();const {data}=await db.auth.getUser();signedIn=!!data.user;}catch{}
 return <html lang="en"><body><a className="skip" href="#main">Skip to content</a><header className="header"><nav className="nav"><Link className="brand" href="/"><span className="mark">⇄</span>SkillBridge<span style={{color:'#6250df'}}>.</span></Link><div className="navlinks"><Link href="/explore">Explore skills</Link><Link className="desktop" href="/how-it-works">How it works</Link><Link className="desktop" href="/about">Community</Link><Link className="button" href={signedIn?'/dashboard':'/register'}>{signedIn?'Dashboard':'Get started ↗'}</Link></div></nav></header><main id="main">{children}</main><footer className="footer"><div><span><strong>SkillBridge.</strong><br/>Exchange Knowledge. Unlock Potential.</span><div className="row"><Link href="/about">About</Link><Link href="/contact">Contact</Link><Link href="/privacy">Privacy</Link><Link href="/terms">Terms</Link></div><small>Built for curious minds.</small></div></footer></body></html>
}
