import { useMemo } from "react";
import { useNavigate } from "react-router-dom";
import { COURTS, SPORT_LABELS } from "../data/courts";
import type { Court } from "../data/types";
import CourtCard from "../components/courts/CourtCard";
import { useOnboarding } from "../state/OnboardingContext";
import { useBookingFlow } from "../state/BookingFlowContext";
import { ArrowLeft } from "../components/ui/Icon";

export default function RecommendationsPage() {
  const navigate = useNavigate();
  const onboarding = useOnboarding();
  const flow = useBookingFlow();

  const courts = useMemo(() => {
    let list = COURTS.filter((c) => c.published);
    if (onboarding.sport) list = list.filter((c) => c.type === onboarding.sport);
    return list.sort((a, b) => b.rating - a.rating);
  }, [onboarding.sport]);

  function book(court: Court) {
    flow.reset(court);
    navigate(`/courts/${court.id}/book`);
  }

  const dateLabel = new Date(onboarding.date + "T00:00:00").toLocaleDateString("en", {
    weekday: "long",
    month: "short",
    day: "numeric",
  });

  return (
    <div className="mx-auto max-w-content px-4 pb-12 pt-20 md:px-6 md:pt-8">
      <button
        onClick={() => navigate("/home")}
        className="flex items-center gap-1.5 text-slate-400"
      >
        <ArrowLeft size={14} />
        <span className="text-[10px] font-black uppercase tracking-wider">Home</span>
      </button>

      <div className="mt-3">
        <span className="t-eyebrow text-primary">RECOMMENDED FOR YOU</span>
        <h1 className="t-heading mt-1">
          {onboarding.sport ? SPORT_LABELS[onboarding.sport].toUpperCase() : "ALL"} COURTS
        </h1>
        <p className="t-body-bold mt-1 text-slate-400">
          {dateLabel}
          {onboarding.time ? ` · ${onboarding.time}` : ""} · {courts.length} venues
        </p>
      </div>

      <div className="mt-6 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
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
    </div>
  );
}
