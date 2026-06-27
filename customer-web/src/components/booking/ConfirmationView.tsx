import { useNavigate } from "react-router-dom";
import { useBookingFlow } from "../../state/BookingFlowContext";
import { CheckIcon } from "../ui/Icon";

// Step 4 — booking confirmed.
export default function ConfirmationView() {
  const flow = useBookingFlow();
  const navigate = useNavigate();
  const court = flow.court!;

  const dateLabel = new Date(flow.date + "T00:00:00").toLocaleDateString("en", {
    weekday: "long",
    month: "long",
    day: "numeric",
  });
  const times = flow.slots.map((s) => s.time).sort();

  return (
    <div className="grid min-h-screen place-items-center bg-canvas px-4 py-20">
      <div className="w-full max-w-md rounded-3xl border border-slate-100 bg-white p-7 text-center shadow-card">
        <div className="mx-auto grid h-16 w-16 place-items-center rounded-full bg-emerald-bg text-emerald">
          <CheckIcon size={32} />
        </div>
        <span className="t-eyebrow mt-5 block text-emerald">Booking Confirmed</span>
        <h1 className="t-heading mt-1">YOU'RE ALL SET!</h1>
        <p className="t-body-bold mt-1 text-slate-400">
          {flow.payment === "cash"
            ? "Your slot is reserved. Pay cash on arrival."
            : "A confirmation has been sent to your email."}
        </p>

        <div className="mt-5 rounded-2xl border border-slate-100 bg-slate-50 p-4 text-left">
          <Row label="Ref Code" value={flow.refCode} mono />
          <Row label="Venue" value={court.name} />
          <Row label="Date" value={dateLabel} />
          <Row label="Time" value={times.join(", ")} />
          <Row label="Slots" value={`${flow.slots.length} × 1hr`} />
          <div className="my-2 h-px bg-slate-200" />
          <div className="flex items-center justify-between">
            <span className="t-eyebrow">Total Paid</span>
            <span className="t-price-mega">₱{flow.total}</span>
          </div>
        </div>

        <button
          onClick={() => navigate("/bookings")}
          className="mt-5 w-full rounded-md bg-primary py-4 text-[12px] font-extrabold uppercase tracking-wider text-white shadow-cta transition hover:bg-primary-dark"
        >
          View My Bookings
        </button>
        <button
          onClick={() => navigate("/home")}
          className="mt-2 w-full py-2.5 text-[10px] font-black uppercase tracking-wider text-slate-400"
        >
          Back to Home
        </button>
      </div>
    </div>
  );
}

function Row({ label, value, mono }: { label: string; value: string; mono?: boolean }) {
  return (
    <div className="flex items-center justify-between gap-3 py-1">
      <span className="t-eyebrow">{label}</span>
      <span className={`text-[11px] font-extrabold text-primary ${mono ? "font-mono tracking-wider" : ""}`}>
        {value}
      </span>
    </div>
  );
}
