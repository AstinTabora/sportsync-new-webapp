import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { useBookings } from "../state/BookingsContext";
import type { Booking } from "../data/types";
import { SPORT_LABELS } from "../data/courts";
import { CalendarIcon, ClockIcon, PinIcon, SportIcon } from "../components/ui/Icon";

export default function MyBookingsPage() {
  const { upcoming, past } = useBookings();
  const [tab, setTab] = useState<"upcoming" | "past">("upcoming");
  const navigate = useNavigate();
  const list = tab === "upcoming" ? upcoming : past;

  return (
    <div className="mx-auto max-w-content px-4 pb-12 pt-20 md:px-6 md:pt-8">
      <h1 className="t-heading">MY BOOKINGS</h1>
      <p className="t-body-bold mt-1 text-slate-400">Manage your court reservations.</p>

      {/* Tabs */}
      <div className="mt-5 flex max-w-xs rounded-md bg-slate-100 p-1">
        {(["upcoming", "past"] as const).map((t) => (
          <button
            key={t}
            onClick={() => setTab(t)}
            className={`flex-1 rounded-[8px] py-2.5 text-[10px] font-black uppercase tracking-wider transition ${
              tab === t ? "bg-white text-primary shadow-subtle" : "text-slate-400"
            }`}
          >
            {t} ({t === "upcoming" ? upcoming.length : past.length})
          </button>
        ))}
      </div>

      {list.length === 0 ? (
        <div className="mt-10 rounded-3xl border border-dashed border-slate-200 py-16 text-center">
          <div className="mx-auto grid h-14 w-14 place-items-center rounded-2xl bg-primary-xlight text-primary">
            <CalendarIcon size={26} />
          </div>
          <p className="mt-4 text-[12px] font-black uppercase tracking-wider text-slate-400">
            No {tab} bookings
          </p>
          <button
            onClick={() => navigate("/home")}
            className="mt-4 rounded-md bg-primary px-5 py-3 text-[10px] font-black uppercase tracking-wider text-white shadow-cta"
          >
            Find a court
          </button>
        </div>
      ) : (
        <div className="mt-6 grid gap-4 md:grid-cols-2">
          {list.map((b) => (
            <BookingCard key={b.id} booking={b} />
          ))}
        </div>
      )}
    </div>
  );
}

const STATUS_STYLE: Record<string, string> = {
  paid: "bg-emerald-bg text-emerald",
  pending: "bg-amber-bg text-amber",
  completed: "bg-info-bg text-info",
  cancelled: "bg-slate-100 text-slate-400",
};

function BookingCard({ booking }: { booking: Booking }) {
  const dateLabel = new Date(booking.date + "T00:00:00").toLocaleDateString("en", {
    weekday: "short",
    month: "short",
    day: "numeric",
  });
  const times = booking.slots.map((s) => s.time).sort();

  return (
    <div className="rounded-3xl border border-slate-100 bg-white p-5 shadow-subtle">
      <div className="flex items-start justify-between gap-3">
        <div className="flex items-center gap-3">
          <span className="grid h-11 w-11 place-items-center rounded-xl bg-primary-xlight text-primary">
            <SportIcon type={booking.courtType} size={20} />
          </span>
          <div>
            <h3 className="t-card-title text-[16px]">{booking.courtName}</h3>
            <span className="t-micro">{SPORT_LABELS[booking.courtType]}</span>
          </div>
        </div>
        <span className={`rounded-pill px-2.5 py-1 text-[9px] font-black uppercase tracking-wide ${STATUS_STYLE[booking.status]}`}>
          {booking.status}
        </span>
      </div>

      <div className="my-4 h-px bg-slate-100" />

      <div className="space-y-2">
        <InfoRow icon={<CalendarIcon size={13} />} text={dateLabel} />
        <InfoRow icon={<ClockIcon size={13} />} text={times.join(", ")} />
        <InfoRow icon={<PinIcon size={13} />} text={booking.location} />
      </div>

      <div className="mt-4 flex items-center justify-between">
        <span className="font-mono text-[10px] font-bold tracking-wider text-slate-400">
          {booking.refCode}
        </span>
        <span className="t-price text-[18px]">₱{booking.totalAmount}</span>
      </div>
    </div>
  );
}

function InfoRow({ icon, text }: { icon: React.ReactNode; text: string }) {
  return (
    <div className="flex items-center gap-2 text-slate-500">
      <span className="text-primary">{icon}</span>
      <span className="text-[12px] font-semibold">{text}</span>
    </div>
  );
}
