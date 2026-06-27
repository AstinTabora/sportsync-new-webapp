import { NavLink, Outlet, useLocation } from "react-router-dom";
import Logo from "../ui/Logo";
import FloatingHeader from "./FloatingHeader";
import { CalendarIcon, HomeIcon, UserIcon } from "../ui/Icon";
import type { ComponentType } from "react";

interface NavDest {
  to: string;
  label: string;
  Icon: ComponentType<{ size?: number }>;
  match: (path: string) => boolean;
}

const DESTS: NavDest[] = [
  { to: "/home", label: "Home", Icon: HomeIcon, match: (p) => p.startsWith("/home") || p.startsWith("/courts") },
  { to: "/bookings", label: "Bookings", Icon: CalendarIcon, match: (p) => p.startsWith("/bookings") },
  { to: "/profile", label: "Profile", Icon: UserIcon, match: (p) => p.startsWith("/profile") },
];

// Responsive chrome: desktop = left sidebar, mobile = floating header + bottom nav.
export default function AppShell() {
  const { pathname } = useLocation();

  return (
    <div className="min-h-screen bg-canvas md:flex">
      {/* ── Desktop sidebar ─────────────────────────────────────────── */}
      <aside className="hidden md:flex md:w-64 md:flex-col md:fixed md:inset-y-0 md:border-r md:border-slate-100 md:bg-white">
        <div className="flex items-center gap-2.5 px-6 py-6">
          <Logo size={36} />
          <span className="t-wordmark text-[18px]">SPORTSYNC</span>
        </div>
        <nav className="flex flex-col gap-1 px-3">
          {DESTS.map(({ to, label, Icon, match }) => {
            const active = match(pathname);
            return (
              <NavLink
                key={to}
                to={to}
                className={`flex items-center gap-3 rounded-xl px-4 py-3 transition ${
                  active
                    ? "bg-primary text-white shadow-cta"
                    : "text-slate-500 hover:bg-slate-50"
                }`}
              >
                <Icon size={20} />
                <span className="text-[12px] font-extrabold uppercase tracking-[1.4px]">
                  {label}
                </span>
              </NavLink>
            );
          })}
        </nav>
        <div className="mt-auto px-6 py-6">
          <p className="t-micro text-slate-300" style={{ letterSpacing: "2px" }}>
            SPORTSYNC v1.0 · DAVAO
          </p>
        </div>
      </aside>

      {/* ── Main content ────────────────────────────────────────────── */}
      <div className="flex-1 md:pl-64">
        <FloatingHeader />
        <main className="min-h-screen pb-24 md:pb-0">
          <Outlet />
        </main>
      </div>

      {/* ── Mobile bottom nav ───────────────────────────────────────── */}
      <nav
        className="md:hidden fixed inset-x-0 bottom-0 z-30 flex border-t border-slate-100 bg-white px-2 pt-2 shadow-nav"
        style={{ paddingBottom: "max(0.75rem, env(safe-area-inset-bottom))" }}
      >
        {DESTS.map(({ to, label, Icon, match }) => {
          const active = match(pathname);
          return (
            <NavLink
              key={to}
              to={to}
              className="flex flex-1 flex-col items-center gap-1 py-1.5"
              style={{ color: active ? "var(--primary)" : "#94A3B8" }}
            >
              <Icon size={22} />
              <span className="text-[9px] font-bold uppercase tracking-[1.4px]">
                {label}
              </span>
            </NavLink>
          );
        })}
      </nav>
    </div>
  );
}
