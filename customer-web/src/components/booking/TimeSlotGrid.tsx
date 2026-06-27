import { useMemo } from "react";
import type { SlotState } from "../../data/types";
import { useBookingFlow } from "../../state/BookingFlowContext";

// Hourly slots 06:00–21:00 (matches the seed schedule). A deterministic subset
// is pre-booked / open-play so the grid looks realistic without a backend.

const HOURS = Array.from({ length: 16 }, (_, i) => 6 + i); // 6..21

function hash(s: string): number {
  let h = 0;
  for (let i = 0; i < s.length; i++) h = (h * 31 + s.charCodeAt(i)) >>> 0;
  return h;
}

function fmt(hour: number): string {
  const h = hour % 24;
  const ampm = h < 12 ? "AM" : "PM";
  const display = h % 12 === 0 ? 12 : h % 12;
  return `${display} ${ampm}`;
}

function pad(hour: number): string {
  return `${String(hour).padStart(2, "0")}:00`;
}

export default function TimeSlotGrid({ courtCount }: { courtCount: number }) {
  const flow = useBookingFlow();
  const courts = Array.from({ length: Math.min(Math.max(courtCount, 1), 8) }, (_, i) => i + 1);

  const now = new Date();
  const isToday = flow.date === now.toISOString().slice(0, 10);

  // Precompute non-available states deterministically.
  const baseState = useMemo(() => {
    const map = new Map<string, SlotState>();
    for (const c of courts) {
      for (const hour of HOURS) {
        const key = `${c}_${hour}`;
        const h = hash(`${flow.court?.id}_${flow.date}_${key}`);
        let state: SlotState = "available";
        if (h % 5 === 0) state = "booked";
        else if (h % 11 === 0) state = "openplay";
        else if (hour >= 21) state = "closing";
        if (isToday && hour <= now.getHours()) state = "past";
        map.set(key, state);
      }
    }
    return map;
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [flow.court?.id, flow.date, courtCount]);

  return (
    <div className="no-scrollbar overflow-x-auto">
      <div className="inline-block min-w-full">
        {/* Header row: court labels */}
        <div className="flex">
          <div className="sticky left-0 z-10 w-14 shrink-0 bg-[#FCFCF9]" />
          {courts.map((c) => (
            <div key={c} className="w-[68px] shrink-0 pb-2 text-center">
              <span className="text-[9px] font-black uppercase tracking-wide text-slate-400">
                Court {c}
              </span>
            </div>
          ))}
        </div>

        {/* Rows */}
        {HOURS.map((hour) => (
          <div key={hour} className="flex items-center">
            <div className="sticky left-0 z-10 w-14 shrink-0 bg-[#FCFCF9] pr-2 text-right">
              <span className="text-[9px] font-black uppercase text-slate-400">{fmt(hour)}</span>
            </div>
            {courts.map((c) => {
              const key = `${c}_${hour}`;
              const selected = flow.isSelected({ court: `Court ${c}`, time: pad(hour) });
              const state: SlotState = selected ? "selected" : baseState.get(key)!;
              return (
                <div key={c} className="w-[68px] shrink-0 p-0.5">
                  <SlotCell
                    state={state}
                    onClick={() => {
                      if (state === "booked" || state === "past" || state === "closing" || state === "openplay")
                        return;
                      flow.toggleSlot({ court: `Court ${c}`, time: pad(hour) });
                    }}
                  />
                </div>
              );
            })}
          </div>
        ))}
      </div>
    </div>
  );
}

const CELL: Record<SlotState, string> = {
  available: "bg-white border-slate-200 text-slate-300 hover:border-primary/40 cursor-pointer",
  selected: "bg-primary border-primary text-white cursor-pointer",
  booked: "bg-booked-bg border-booked text-booked cursor-not-allowed",
  openplay: "bg-purple-bg border-purple text-purple cursor-not-allowed",
  closing: "bg-slate-50 border-slate-200 text-slate-300 cursor-not-allowed",
  past: "bg-slate-50 border-slate-100 text-slate-200 cursor-not-allowed",
};

function SlotCell({ state, onClick }: { state: SlotState; onClick: () => void }) {
  const dot = state === "selected" ? "●" : state === "booked" ? "✕" : "";
  return (
    <button
      onClick={onClick}
      className={`grid h-9 w-full place-items-center rounded-lg border text-[11px] font-black transition ${CELL[state]}`}
    >
      {dot}
    </button>
  );
}
