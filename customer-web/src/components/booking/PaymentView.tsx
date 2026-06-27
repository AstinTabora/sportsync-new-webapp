import { useState } from "react";
import { useBookingFlow } from "../../state/BookingFlowContext";
import { useBookings } from "../../state/BookingsContext";
import type { Booking, PaymentMethod } from "../../data/types";
import UserFormModal from "./UserFormModal";
import { ArrowLeft, CardIcon, CashIcon, QrIcon } from "../ui/Icon";

const METHODS: {
  id: PaymentMethod;
  title: string;
  subtitle: string;
  Icon: typeof QrIcon;
}[] = [
  { id: "qrph", title: "Pay Now", subtitle: "QR Ph · Scan to pay · Instant confirmation", Icon: QrIcon },
  { id: "card", title: "Card", subtitle: "Visa / Mastercard · Secure checkout", Icon: CardIcon },
  { id: "cash", title: "Pay at Venue", subtitle: "Reserve now, pay cash on arrival", Icon: CashIcon },
];

// Step 3 — choose payment, capture details, simulate a charge.
export default function PaymentView() {
  const flow = useBookingFlow();
  const { addBooking } = useBookings();
  const court = flow.court!;

  const [showForm, setShowForm] = useState(false);
  const [pending, setPending] = useState<PaymentMethod | null>(null);
  const [processing, setProcessing] = useState(false);

  const dateLabel = new Date(flow.date + "T00:00:00").toLocaleDateString("en", {
    weekday: "short",
    month: "short",
    day: "numeric",
  });

  function choose(method: PaymentMethod) {
    setPending(method);
    flow.setPayment(method);
    setShowForm(true);
  }

  function onDetailsSubmitted() {
    setShowForm(false);
    setProcessing(true);
    // Simulate a payment round-trip.
    setTimeout(() => {
      const booking: Booking = {
        id: flow.refCode,
        refCode: flow.refCode,
        courtId: court.id,
        courtName: court.name,
        courtType: court.type,
        location: court.location,
        date: flow.date,
        slots: flow.slots,
        totalAmount: flow.total,
        payment: pending ?? "qrph",
        status: pending === "cash" ? "pending" : "paid",
        userName: flow.details.name,
        userEmail: flow.details.email,
        userPhone: flow.details.phone,
        createdAt: new Date().toISOString(),
      };
      addBooking(booking);
      setProcessing(false);
      flow.setStep("confirmation");
    }, 1600);
  }

  return (
    <div className="min-h-screen bg-canvas pb-28 md:pb-12">
      <div className="mx-auto max-w-xl px-4 pt-20 md:px-6 md:pt-8">
        <button
          onClick={() => flow.setStep("calendar")}
          className="flex items-center gap-1.5 text-slate-400"
        >
          <ArrowLeft size={14} />
          <span className="text-[10px] font-black uppercase tracking-wider">Back</span>
        </button>

        <div className="mt-4 rounded-3xl border border-slate-100 bg-white p-6 shadow-subtle">
          <div className="text-center">
            <span className="t-eyebrow">Step 3 of 4</span>
            <h1 className="t-heading mt-1">CHOOSE PAYMENT</h1>
            <p className="t-body-bold mt-1 text-slate-500">
              Confirm your booking and pay securely.
            </p>
          </div>

          {/* Summary */}
          <div className="mt-5 rounded-xl border border-slate-100 bg-slate-50 p-4">
            <SummaryRow label="Venue" value={court.name} />
            <SummaryRow label="Date" value={dateLabel} />
            <SummaryRow label="Slots" value={`${flow.slots.length} × 1hr`} />
            <div className="my-2 h-px bg-slate-200" />
            <div className="flex items-center justify-between">
              <span className="t-eyebrow">Total</span>
              <span className="t-price-mega">₱{flow.total}</span>
            </div>
          </div>

          {/* Methods */}
          <div className="mt-5 space-y-3">
            {METHODS.map((m, i) => {
              const highlighted = i === 0;
              return (
                <button
                  key={m.id}
                  onClick={() => choose(m.id)}
                  className={`flex w-full items-center gap-3 rounded-2xl border p-4 text-left transition hover:border-primary/50 ${
                    highlighted ? "border-2 border-primary shadow-card" : "border-slate-200"
                  }`}
                >
                  <span className="grid h-12 w-12 shrink-0 place-items-center rounded-md bg-primary text-white">
                    <m.Icon size={26} />
                  </span>
                  <span className="flex-1">
                    <span className="block t-page-title">{m.title}</span>
                    <span className="block text-[11px] font-semibold text-slate-400">{m.subtitle}</span>
                  </span>
                </button>
              );
            })}
          </div>

          <p className="mt-4 text-center text-[9px] font-bold uppercase tracking-[1.6px] text-slate-300">
            Secured by SportSync
          </p>
        </div>
      </div>

      <UserFormModal open={showForm} onClose={() => setShowForm(false)} onSubmit={onDetailsSubmitted} />

      {/* Processing overlay */}
      {processing && (
        <div className="fixed inset-0 z-50 grid place-items-center bg-black/50">
          <div className="flex flex-col items-center gap-4 rounded-3xl bg-white px-10 py-8 shadow-hero">
            <div className="h-10 w-10 animate-spin rounded-full border-4 border-slate-200 border-t-primary" />
            <p className="t-page-title">Processing payment…</p>
          </div>
        </div>
      )}
    </div>
  );
}

function SummaryRow({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex items-center justify-between py-1">
      <span className="t-eyebrow">{label}</span>
      <span className="t-eyebrow text-primary">{value}</span>
    </div>
  );
}
