import type { Metadata } from 'next';
import './globals.css';
export const metadata: Metadata = { title: 'SkillBridge · Foundation', description: 'Exchange Knowledge. Unlock Potential.', robots: { index: false, follow: false } };
export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
 return <html lang="en"><body><a className="skip" href="#main">Skip to content</a>{children}</body></html>;
}
