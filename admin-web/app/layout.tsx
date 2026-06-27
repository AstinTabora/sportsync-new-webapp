import type { Metadata } from "next";
import "./globals.css";
import { AuthProvider } from "@/lib/auth/AuthProvider";

// Every page is auth-gated and Firebase-driven — there's nothing useful to
// pre-render at build time. Opting the whole app out of SSG keeps the
// Firebase client init safe (it would otherwise run with empty env vars and
// crash with auth/invalid-api-key during `next build`).
export const dynamic = "force-dynamic";

export const metadata: Metadata = {
  title: "SportSync Admin",
  description: "Court owner dashboard for SportSync",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body className="font-sans">
        <AuthProvider>{children}</AuthProvider>
      </body>
    </html>
  );
}
