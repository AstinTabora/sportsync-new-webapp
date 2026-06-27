import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { useAuth } from "../state/AuthContext";
import { useBookings } from "../state/BookingsContext";
import AuthSheet from "../components/sheets/AuthSheet";
import {
  BoltIcon,
  CalendarIcon,
  ChevronRight,
  ClockIcon,
  EditIcon,
  LoginIcon,
  LogoutIcon,
  StarIcon,
  UserIcon,
} from "../components/ui/Icon";

const MENU = [
  { label: "Saved Courts", trail: "5", route: null },
  { label: "Payment Methods", trail: "QR Ph", route: null },
  { label: "Notifications", trail: "On", route: null },
  { label: "Help & Support", trail: "About", route: "/profile/about" },
];

export default function ProfilePage() {
  const auth = useAuth();
  const { stats } = useBookings();
  const navigate = useNavigate();
  const [showAuth, setShowAuth] = useState(false);

  return (
    <div className="min-h-screen bg-surface">
      <div className="mx-auto max-w-2xl px-4 pb-12 pt-20 md:px-6 md:pt-8">
        {/* Identity */}
        <div className="flex items-center gap-4 rounded-3xl border border-slate-100 bg-white p-5 shadow-subtle">
          <div className="grid h-20 w-20 shrink-0 place-items-center rounded-2xl bg-primary text-white shadow-cta">
            <UserIcon size={40} />
          </div>
          <div className="min-w-0 flex-1">
            <span className="t-eyebrow">MEMBER SINCE {auth.profile.memberSince}</span>
            <h1 className="t-card-title mt-0.5 truncate">{auth.profile.displayName}</h1>
            {auth.profile.email && (
              <p className="truncate text-[13px] font-semibold text-slate-500">{auth.profile.email}</p>
            )}
          </div>
          <button
            onClick={() => navigate("/profile/edit")}
            className="grid h-9 w-9 place-items-center rounded-md border border-slate-100 bg-slate-50 text-primary"
            aria-label="Edit profile"
          >
            <EditIcon size={14} />
          </button>
        </div>

        {/* Stats */}
        <div className="mt-4 grid grid-cols-3 gap-2">
          <StatTile icon={<CalendarIcon size={16} />} value={`${stats.total}`} label="Bookings" />
          <StatTile icon={<ClockIcon size={16} />} value={`${stats.hours}h`} label="Played" />
          <StatTile icon={<StarIcon size={16} />} value={stats.rating.toFixed(1)} label="Rating" />
        </div>

        {/* Favorite sport */}
        <div className="mt-4 flex items-center gap-3 rounded-3xl bg-primary p-4 shadow-cta">
          <span className="grid h-12 w-12 place-items-center rounded-md bg-white/15 text-white">
            <BoltIcon size={22} />
          </span>
          <div className="flex-1">
            <span className="t-eyebrow text-white/60">FAVORITE SPORT</span>
            <p className="t-page-title text-white">{auth.profile.favoriteSport.toUpperCase()}</p>
          </div>
          <button
            onClick={() => navigate("/profile/edit")}
            className="rounded-sm bg-white/15 px-2.5 py-1.5 text-[9px] font-black uppercase tracking-[1.8px] text-white"
          >
            Change
          </button>
        </div>

        {/* Menu */}
        <div className="mt-4 overflow-hidden rounded-3xl border border-slate-100 bg-white">
          {MENU.map((m, i) => (
            <button
              key={m.label}
              onClick={() => (m.route ? navigate(m.route) : undefined)}
              className={`flex w-full items-center gap-3 px-4 py-3.5 text-left ${
                i !== MENU.length - 1 ? "border-b border-slate-100" : ""
              }`}
            >
              <span className="t-pill flex-1">{m.label}</span>
              <span className="t-eyebrow">{m.trail}</span>
              <ChevronRight size={16} className="text-slate-300" />
            </button>
          ))}
        </div>

        {/* Account & auth */}
        {auth.signedIn && (
          <button
            onClick={() => navigate("/profile/account")}
            className="mt-4 flex w-full items-center gap-3 rounded-3xl border border-slate-100 bg-white px-4 py-3.5"
          >
            <span className="t-pill flex-1 text-left">Account & Security</span>
            <ChevronRight size={16} className="text-slate-300" />
          </button>
        )}

        <button
          onClick={() => (auth.signedIn ? auth.signOut() : setShowAuth(true))}
          className={`mt-4 flex w-full items-center justify-center gap-2 rounded-xl py-4 transition ${
            auth.signedIn
              ? "border border-slate-100 bg-white text-slate-400"
              : "bg-primary text-white shadow-cta"
          }`}
        >
          {auth.signedIn ? <LogoutIcon size={14} /> : <LoginIcon size={14} />}
          <span className="text-[10px] font-black uppercase tracking-[2px]">
            {auth.signedIn ? "Sign Out" : "Sign In / Create Account"}
          </span>
        </button>

        <p className="mt-5 text-center text-[8px] font-bold uppercase tracking-[3.6px] text-slate-300">
          SPORTSYNC v1.0 · DAVAO
        </p>
      </div>

      <AuthSheet open={showAuth} onClose={() => setShowAuth(false)} />
    </div>
  );
}

function StatTile({ icon, value, label }: { icon: React.ReactNode; value: string; label: string }) {
  return (
    <div className="flex flex-col items-center gap-1 rounded-xl border border-slate-100 bg-white py-3">
      <span className="text-primary">{icon}</span>
      <span className="t-stat">{value}</span>
      <span className="t-micro">{label}</span>
    </div>
  );
}
