import { useState } from "react";
import { useNavigate } from "react-router-dom";
import Modal from "../ui/Modal";
import Button from "../ui/Button";
import { SportIcon } from "../ui/Icon";
import type { SportType } from "../../data/types";
import { useOnboarding } from "../../state/OnboardingContext";

interface Props {
  open: boolean;
  onClose: () => void;
}

const SPORTS: { type: SportType; label: string }[] = [
  { type: "badminton", label: "Badminton" },
  { type: "pickleball", label: "Pickleball" },
  { type: "basketball", label: "Basketball" },
];

const TIMES = ["Morning", "Afternoon", "Evening"];

function next7Days() {
  return Array.from({ length: 7 }, (_, i) => {
    const d = new Date();
    d.setDate(d.getDate() + i);
    return d;
  });
}

// Welcome sheet — pick sport / date / time, then show recommendations.
export default function OnboardingSheet({ open, onClose }: Props) {
  const onboarding = useOnboarding();
  const navigate = useNavigate();
  const [sport, setSport] = useState<SportType | null>(null);
  const [date, setDate] = useState<string>(new Date().toISOString().slice(0, 10));
  const [time, setTime] = useState<string | null>(null);

  function findCourts() {
    onboarding.apply({ sport, date, time });
    onClose();
    navigate("/home/recommendations");
  }

  return (
    <Modal open={open} onClose={onClose} maxWidth="max-w-lg">
      <div className="pt-1">
        <span className="t-eyebrow text-primary">LET'S GET YOU PLAYING</span>
        <h2 className="t-heading mt-1">FIND YOUR COURT</h2>
        <p className="t-body-bold mt-1 text-slate-400">
          Tell us what you're into — we'll match you with the best venues.
        </p>

        {/* Sport */}
        <p className="t-micro mt-5 text-slate-500">Pick a sport</p>
        <div className="mt-2 grid grid-cols-3 gap-2">
          {SPORTS.map((s) => {
            const active = sport === s.type;
            return (
              <button
                key={s.type}
                onClick={() => setSport(active ? null : s.type)}
                className={`flex flex-col items-center gap-2 rounded-xl border p-3 transition ${
                  active
                    ? "border-primary bg-primary text-white shadow-cta"
                    : "border-slate-200 bg-white text-slate-500 hover:border-primary/30"
                }`}
              >
                <SportIcon type={s.type} size={22} />
                <span className="text-[10px] font-black uppercase tracking-wide">
                  {s.label}
                </span>
              </button>
            );
          })}
        </div>

        {/* Date */}
        <p className="t-micro mt-5 text-slate-500">When</p>
        <div className="no-scrollbar mt-2 flex gap-2 overflow-x-auto pb-1">
          {next7Days().map((d, i) => {
            const iso = d.toISOString().slice(0, 10);
            const active = iso === date;
            const label = i === 0 ? "TODAY" : d.toLocaleDateString("en", { weekday: "short" }).toUpperCase();
            return (
              <button
                key={iso}
                onClick={() => setDate(iso)}
                className={`flex shrink-0 flex-col items-center rounded-[14px] border px-3.5 py-2.5 transition ${
                  active ? "border-primary bg-primary text-white" : "border-slate-200 bg-white"
                }`}
              >
                <span className={`text-[9px] font-black tracking-wide ${active ? "text-white" : "text-slate-400"}`}>
                  {label}
                </span>
                <span className={`text-[16px] font-black ${active ? "text-white" : "text-primary"}`}>
                  {d.getDate()}
                </span>
              </button>
            );
          })}
        </div>

        {/* Time */}
        <p className="t-micro mt-5 text-slate-500">Time of day</p>
        <div className="mt-2 grid grid-cols-3 gap-2">
          {TIMES.map((t) => {
            const active = time === t;
            return (
              <button
                key={t}
                onClick={() => setTime(active ? null : t)}
                className={`rounded-xl border py-2.5 text-[10px] font-black uppercase tracking-wide transition ${
                  active ? "border-primary bg-primary text-white" : "border-slate-200 bg-white text-slate-500"
                }`}
              >
                {t}
              </button>
            );
          })}
        </div>

        <Button full className="mt-6" onClick={findCourts}>
          Show me courts
        </Button>
        <button
          onClick={onClose}
          className="mt-2 w-full py-2 text-[10px] font-black uppercase tracking-wider text-slate-400"
        >
          Skip for now
        </button>
      </div>
    </Modal>
  );
}
