"use client";
export default function ErrorPage({reset}:{reset:()=>void}) {return <main id="main" className="shell"><h1>Something went wrong.</h1><p>Please try again.</p><button onClick={reset}>Try again</button></main>;}
