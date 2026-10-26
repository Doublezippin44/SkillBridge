import { ArrowLeftRight, Database, ShieldCheck, Layers3 } from 'lucide-react';
export default function Home() {
 return <main id="main" className="shell">
  <header><span className="brand"><ArrowLeftRight aria-hidden="true" /> SkillBridge</span><span className="badge">Phase 1 · Engineering foundation</span></header>
  <section className="hero"><p className="eyebrow">EXCHANGE KNOWLEDGE. UNLOCK POTENTIAL.</p><h1>Your skills are<br /><span>worth sharing.</span></h1><p className="intro">A place to teach what you know and learn what comes next.</p><p className="notice">Development foundation. Registration, exchanges, and bookings are not available yet. This page does not represent a launched platform.</p></section>
  <section aria-label="Architecture" className="grid">
   <article><Layers3 aria-hidden="true"/><h2>One coherent platform</h2><p>Next.js App Router, TypeScript, and a server-side domain layer.</p></article>
   <article><Database aria-hidden="true"/><h2>Data with integrity</h2><p>PostgreSQL constraints, persistent records, and transactional workflow design.</p></article>
   <article><ShieldCheck aria-hidden="true"/><h2>Private by default</h2><p>Row-level access policies and separate public and private account data.</p></article>
  </section><footer>SkillBridge / Software Engineering Project <span>Architecture → Core platform → Verified workflows</span></footer>
 </main>;
}
