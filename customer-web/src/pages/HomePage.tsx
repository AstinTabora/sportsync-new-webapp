import { useEffect, useMemo, useState } from "react";
import { useNavigate } from "react-router-dom";
import { COURTS } from "../data/courts";
import type { Court, SportType } from "../data/types";
import CourtCard from "../components/courts/CourtCard";
import CourtCardCompact from "../components/courts/CourtCardCompact";
import OnboardingSheet from "../components/sheets/OnboardingSheet";
import { useOnboarding } from "../state/OnboardingContext";
import { useBookingFlow } from "../state/BookingFlowContext";
import {
  GridIcon,
  ListIcon,
  PinIcon,
  SearchIcon,
  SlidersIcon,
  SportIcon,
} from "../components/ui/Icon";

type SortMode = "default" | "price" | "courts" | "rating";

export default function HomePage() {
  const navigate = useNavigate();
  const onboarding = useOnboarding();
  const flow = useBookingFlow();

  const [showOnboarding, setShowOnboarding] = useState(false);
  const [query, setQuery] = useState("");
  const [sport, setSport] = useState<SportType | null>(null);
  const [sort, setSort] = useState<SortMode>("default");
  const [view, setView] = useState<"grid" | "list">("grid");
  const [panel, setPanel] = useState<"none" | "search" | "filters">("none");

  // Show the welcome sheet once per session.
  useEffect(() => {
    if (!onboarding.shownThisSession) {
      onboarding.markShown();
      setShowOnboarding(true);
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const courts = useMemo(() => {
    let list = COURTS.filter((c) => c.published);
    if (sport) list = list.filter((c) => c.type === sport);
    if (query.trim()) {
      const q = query.toLowerCase();
      list = list.filter(
        (c) => c.name.toLowerCase().includes(q) || c.location.toLowerCase().includes(q)
      );
    }
    if (sort !== "default") {
      list = [...list].sort((a, b) => {
        if (sort === "price") return a.price - b.price;
        if (sort === "courts") return b.numberOfCourts - a.numberOfCourts;
        return b.rating - a.rating;
      });
    }
    return list;
  }, [query, sport, sort]);

  function book(court: Court) {
    flow.reset(court);
    navigate(`/courts/${court.id}/book`);
  }

  return (
    <div>
      <OnboardingSheet open={showOnboarding} onClose={() => setShowOnboarding(false)} />

      {/* ── Hero ─────────────────────────────────────────────────────── */}
      <section className="relative overflow-hidden md:mx-6 md:mt-6 md:rounded-3xl">
        <img
          src="/images/hero-bg.webp"
          alt=""
          className="absolute inset-0 h-full w-full object-cover"
        />
        <div className="absolute inset-0 bg-gradient-to-br from-[#001F12]/95 via-[#003D1A]/90 to-[#005F02]/80" />
        <div className="relative flex flex-col items-center justify-center px-6 pb-24 pt-28 text-center md:pb-28 md:pt-24">
          <h1 className="text-white" style={{ fontWeight: 900, fontSize: "clamp(40px, 7vw, 64px)", letterSpacing: "-1.6px", lineHeight: 0.9 }}>
            PLAN LESS
            <br />
            PLAY MORE.
          </h1>
          <p className="mt-4 max-w-md text-[13px] font-medium leading-relaxed text-white/85">
            Book premium Badminton and Pickleball courts in a few clicks.
          </p>
        </div>
      </section>

      {/* ── Content container ────────────────────────────────────────── */}
      <div className="mx-auto max-w-content px-4 md:px-6">
        {/* How it works — overlaps hero */}
        <div className="-mt-16 rounded-3xl border border-slate-100 bg-white px-5 py-7 shadow-card">
          <div className="grid grid-cols-3 gap-2">
            <Step icon={<SportIcon type="badminton" size={22} />} label="Pick a sport" />
            <Step icon={<PinIcon size={22} />} label="Choose a court" />
            <Step icon={<GridIcon size={22} />} label="Book your slot" />
          </div>
        </div>

        {/* Search + filters */}
        <div className="mt-5 rounded-2xl border border-primary/10 bg-white px-2 py-1 shadow-subtle">
          <div className="flex items-center">
            <button
              onClick={() => setPanel(panel === "search" ? "none" : "search")}
              className="flex flex-1 items-center gap-2 px-3 py-3.5 text-left"
            >
              <SearchIcon size={18} className={query ? "text-primary" : "text-slate-400"} />
              <span className={`text-[12px] font-semibold ${query ? "text-slate-700" : "text-slate-400"}`}>
                {query || "Search courts"}
              </span>
            </button>
            <div className="h-5 w-px bg-slate-100" />
            <button
              onClick={() => setPanel(panel === "filters" ? "none" : "filters")}
              className="flex items-center gap-1.5 px-3 py-3.5"
            >
              <SlidersIcon size={16} className={sport || sort !== "default" ? "text-primary" : "text-slate-400"} />
              <span className={`t-eyebrow ${sport || sort !== "default" ? "text-primary" : "text-slate-400"}`}>
                Filters
              </span>
            </button>
          </div>

          {panel === "search" && (
            <div className="border-t border-slate-100 p-2">
              <input
                autoFocus
                value={query}
                onChange={(e) => setQuery(e.target.value)}
                placeholder="Search courts or locations"
                className="w-full rounded-md border border-slate-100 bg-slate-50 px-3 py-3 text-[14px] font-semibold text-slate-700 outline-none focus:border-primary/40 focus:bg-white"
              />
            </div>
          )}

          {panel === "filters" && (
            <div className="space-y-4 border-t border-slate-100 p-3">
              <div>
                <p className="t-micro text-slate-300">Sport</p>
                <div className="mt-2 flex flex-wrap gap-2">
                  <Chip label="All" active={sport === null} onClick={() => setSport(null)} />
                  <Chip label="Badminton" active={sport === "badminton"} onClick={() => setSport("badminton")} />
                  <Chip label="Pickleball" active={sport === "pickleball"} onClick={() => setSport("pickleball")} />
                  <Chip label="Basketball" active={sport === "basketball"} onClick={() => setSport("basketball")} />
                </div>
              </div>
              <div>
                <p className="t-micro text-slate-300">Sort</p>
                <div className="mt-2 flex flex-wrap gap-2">
                  <Chip label="Price" active={sort === "price"} onClick={() => setSort(sort === "price" ? "default" : "price")} />
                  <Chip label="Courts" active={sort === "courts"} onClick={() => setSort(sort === "courts" ? "default" : "courts")} />
                  <Chip label="Rating" active={sort === "rating"} onClick={() => setSort(sort === "rating" ? "default" : "rating")} />
                </div>
              </div>
            </div>
          )}
        </div>

        {/* View toggle */}
        <div className="mt-4 flex justify-end">
          <div className="flex items-center gap-0.5 rounded-[10px] border border-slate-100 bg-white p-0.5">
            <ToggleBtn active={view === "grid"} onClick={() => setView("grid")}><GridIcon size={16} /></ToggleBtn>
            <ToggleBtn active={view === "list"} onClick={() => setView("list")}><ListIcon size={16} /></ToggleBtn>
          </div>
        </div>

        {/* Court list */}
        <div className="mt-4 pb-10">
          {courts.length === 0 ? (
            <p className="py-16 text-center text-[12px] font-bold uppercase tracking-wider text-slate-400">
              No venues match your search.
            </p>
          ) : view === "grid" ? (
            <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
              {courts.map((c) => (
                <CourtCard
                  key={c.id}
                  court={c}
                  openToday={c.numberOfCourts * 15}
                  onDetails={() => navigate(`/courts/${c.id}`)}
                  onBook={() => book(c)}
                />
              ))}
            </div>
          ) : (
            <div className="mx-auto flex max-w-2xl flex-col gap-2.5">
              {courts.map((c) => (
                <CourtCardCompact
                  key={c.id}
                  court={c}
                  onDetails={() => navigate(`/courts/${c.id}`)}
                  onBook={() => book(c)}
                />
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

function Step({ icon, label }: { icon: React.ReactNode; label: string }) {
  return (
    <div className="flex flex-col items-center gap-2.5 text-center">
      <div className="grid h-12 w-12 place-items-center rounded-xl bg-primary-xlight text-primary">
        {icon}
      </div>
      <span className="text-[9px] font-black uppercase leading-tight tracking-wide text-primary">
        {label}
      </span>
    </div>
  );
}

function Chip({ label, active, onClick }: { label: string; active: boolean; onClick: () => void }) {
  return (
    <button
      onClick={onClick}
      className={`rounded-md border px-3 py-2 text-[9px] font-black uppercase tracking-wide transition ${
        active ? "border-primary bg-primary text-white" : "border-slate-100 bg-slate-50 text-slate-400"
      }`}
    >
      {label}
    </button>
  );
}

function ToggleBtn({ active, onClick, children }: { active: boolean; onClick: () => void; children: React.ReactNode }) {
  return (
    <button
      onClick={onClick}
      className={`grid h-8 w-8 place-items-center rounded-lg transition ${
        active ? "bg-primary text-white" : "text-slate-400"
      }`}
    >
      {children}
    </button>
  );
}
