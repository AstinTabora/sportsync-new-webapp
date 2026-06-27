"use client";

import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { useEffect, useState } from "react";
import {
  LayoutDashboard,
  Building2,
  Receipt,
  LogOut,
} from "lucide-react";
import { useAuth } from "@/lib/auth/AuthProvider";
import { Button } from "./ui/Button";
import { cn } from "@/lib/utils";

const NAV = [
  { href: "/", label: "Dashboard", icon: LayoutDashboard },
  { href: "/courts", label: "Courts", icon: Building2 },
  { href: "/bookings", label: "Bookings", icon: Receipt },
];

export function AppShell({ children }: { children: React.ReactNode }) {
  const { user, profile, role, loading, signOut } = useAuth();
  const router = useRouter();
  const pathname = usePathname();
  const [mounted, setMounted] = useState(false);

  useEffect(() => setMounted(true), []);

  // Approved owners and super admins get in; everyone else is gated.
  const allowed =
    !!profile && (profile.status === "approved" || role === "superAdmin");

  useEffect(() => {
    if (loading || !mounted) return;
    if (!user) {
      router.replace("/login");
      return;
    }
    // Signed in but no profile yet, or not approved → pending.
    if (!allowed) {
      router.replace("/pending");
    }
  }, [loading, user, allowed, router, mounted]);

  if (loading || !user || !profile || !allowed) {
    return (
      <div className="min-h-screen flex items-center justify-center text-slate-500">
        Loading…
      </div>
    );
  }

  return (
    <div className="min-h-screen flex">
      <aside className="w-60 bg-white border-r border-slate-200 flex flex-col">
        <div className="px-6 py-5 border-b border-slate-200">
          <div className="text-lg font-bold text-brand-700">SportSync</div>
          <div className="text-xs text-slate-500">Owner dashboard</div>
        </div>

        <nav className="flex-1 px-3 py-4 space-y-1">
          {NAV.map(({ href, label, icon: Icon }) => {
            const active =
              href === "/"
                ? pathname === "/"
                : pathname.startsWith(href);
            return (
              <Link
                key={href}
                href={href}
                className={cn(
                  "flex items-center gap-3 px-3 py-2 rounded-md text-sm font-medium transition-colors",
                  active
                    ? "bg-brand-50 text-brand-700"
                    : "text-slate-700 hover:bg-slate-100"
                )}
              >
                <Icon size={18} />
                {label}
              </Link>
            );
          })}
        </nav>

        <div className="px-3 py-3 border-t border-slate-200">
          <div className="px-3 py-2 text-xs text-slate-500">
            {profile.businessName}
          </div>
          <Button
            variant="ghost"
            size="sm"
            className="w-full justify-start"
            onClick={async () => {
              await signOut();
              router.replace("/login");
            }}
          >
            <LogOut size={16} /> Sign out
          </Button>
        </div>
      </aside>

      <div className="flex-1 flex flex-col">
        <header className="h-14 border-b border-slate-200 bg-white px-6 flex items-center justify-end">
          <div className="text-sm text-slate-500">{profile.displayName}</div>
        </header>
        <main className="flex-1 p-6">{children}</main>
      </div>
    </div>
  );
}
