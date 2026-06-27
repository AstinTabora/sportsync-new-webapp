import { useNavigate } from "react-router-dom";
import { useBookingFlow } from "../../state/BookingFlowContext";
import TimeSlotGrid from "./TimeSlotGrid";
import { ArrowLeft, CloseIcon } from "../ui/Icon";

const LEGEND: { label: string; cls: string }[] = [
  { label: "Available", cls: "bg-white border-slate-200" },
  { label: "Selected", cls: "bg-primary border-primary" },
  { label: "Booked", cls: "bg-booked-bg border-booked" },
  { label: "Open-Play", cls: "bg-purple-bg border-purple" },
  { label: "Closing", cls: "bg-slate-50 border-slate-200" },
];

// Step 1 — pick date + time slots.
export default function CalendarView() {
  const flow = useBookingFlow();
  const navigate = useNavigate();
  const court = flow.court!;

  const days = Array.from({ length: 7 }, (_, i) => {
    const d = new Date();
    d.setDate(d.getDate() + i);
    return d;
  });
  const todayIso = new Date().toISOString().slice(0, 10);

  return (
    <div className="relative min-h-screen bg-[#FCFCF9] pb-32">
      <div className="mx-auto max-w-content px-5 pt-20 md:pt-8">
        <button
          onClick={() => navigate(`/courts/${court.id}`)}
          className="flex items-center gap-1.5 text-slate-400"
        >
          <ArrowLeft size={14} />
          <span className="text-[10px] font-black uppercase tracking-wider">Back</span>
        </button>

        <h1 className="mt-3 text-2xl font-black tracking-tight text-primary">
          Book {court.name}
        </h1>
        <p className="t-body-bold mt-1 text-slate-400">
          Select a date and time to reserve your slot.
        </p>

        {/* Date selector */}
        <div className="no-scrollbar mt-5 flex gap-2 overflow-x-auto pb-1">
          {days.map((d) => {
            const iso = d.toISOString().slice(0, 10);
            const active = iso === flow.date;
            const label = iso === todayIso ? "TODAY" : d.toLocaleDateString("en", { weekday: "short" }).toUpperCase();
            return (
              <button
                key={iso}
                onClick={() => {
                  flow.clearSlots();
                  flow.setDate(iso);
                }}
                className={`flex shrink-0 flex-col items-center rounded-[14px] border px-4 py-2.5 transition ${
                  active ? "border-primary bg-primary text-white shadow-cta" : "border-slate-200 bg-white"
                }`}
              >
                <span className={`text-[9px] font-black tracking-wide ${active ? "text-white" : "text-slate-400"}`}>
                  {label}
                </span>
                <span className={`mt-0.5 text-[16px] font-black ${active ? "text-white" : "text-primary"}`}>
                  {d.getDate()}
                </span>
              </button>
            );
          })}
        </div>

        {/* Legend */}
        <div className="mt-6 flex flex-wrap gap-x-4 gap-y-2">
          {LEGEND.map((l) => (
            <div key={l.label} className="flex items-center gap-1.5">
              <span className={`h-3 w-3 rounded-[3px] border ${l.cls}`} />
              <span className="text-[10px] font-bold text-slate-400">{l.label}</span>
            </div>
          ))}
        </div>

        {/* Slot grid */}
        <div className="mt-5 rounded-2xl border border-slate-100 bg-white p-4">
          <TimeSlotGrid courtCount={court.numberOfCourts} />
        </div>
      </div>

      {/* Floating proceed bar */}
      {flow.slots.length > 0 && (
        <div className="fixed inset-x-0 bottom-0 z-20 px-5 pb-24 md:pb-6">
          <div className="mx-auto flex max-w-content items-center gap-3 rounded-xl border border-slate-200 bg-white px-5 py-4 shadow-pill">
            <div className="flex-1">
              <p className="text-[10px] font-extrabold uppercase tracking-wide text-slate-400">
                {flow.slots.length} slot{flow.slots.length > 1 ? "s" : ""} selected
              </p>
              <p className="text-[22px] font-black tracking-tight text-primary">₱{flow.total} total</p>
            </div>
            <button
              onClick={flow.clearSlots}
              className="grid h-9 w-9 place-items-center rounded-lg text-slate-400 hover:bg-slate-50"
              aria-label="Clear"
            >
              <CloseIcon size={18} />
            </button>
            <button
              onClick={() => flow.setStep("payment")}
              className="rounded-[14px] bg-primary px-5 py-3.5 text-[11px] font-black uppercase tracking-wider text-white shadow-cta"
            >
              Proceed to Pay
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
