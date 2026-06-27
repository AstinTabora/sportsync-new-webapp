import type { Court } from "../../data/types";
import { PinIcon, SportIcon, StarIcon } from "../ui/Icon";

interface Props {
  court: Court;
  openToday: number;
  onDetails: () => void;
  onBook: () => void;
}

// Full court card — mirrors lib/features/courts/widgets/court_card.dart.
export default function CourtCard({ court, openToday, onDetails, onBook }: Props) {
  return (
    <div className="overflow-hidden rounded-[28px] border border-slate-100 bg-white shadow-subtle transition hover:shadow-card">
      {/* Image header */}
      <div className="relative h-52">
        <img
          src={court.image}
          alt={court.name}
          className="h-full w-full object-cover"
          loading="lazy"
        />
        <div className="absolute inset-0 bg-gradient-to-b from-transparent to-black/20" />
        {/* Sport + court count badges */}
        <div className="absolute left-4 top-4 flex items-center gap-1.5">
          <span className="grid place-items-center rounded-[10px] bg-primary px-2.5 py-1.5 text-white shadow-md">
            <SportIcon type={court.type} size={13} />
          </span>
          <span className="flex items-center gap-1 rounded-[10px] bg-white/95 px-2.5 py-1.5 shadow-md">
            <span className="text-[10px] font-black tracking-wide text-primary">
              {court.numberOfCourts}
            </span>
            <span className="text-[9px] font-black uppercase text-primary">Courts</span>
          </span>
        </div>
        {/* Availability badge */}
        <span
          className={`absolute bottom-3 right-3 rounded-[10px] px-2.5 py-1.5 text-[9px] font-black tracking-wide text-white shadow-md ${
            openToday > 0 ? "bg-emerald" : "bg-slate-800/80"
          }`}
        >
          {openToday > 0 ? `${openToday} open today` : "Full today"}
        </span>
      </div>

      {/* Body */}
      <div className="p-6">
        <div className="flex items-start gap-2">
          <h3 className="t-card-title flex-1">{court.name}</h3>
          <span className="flex items-center gap-1 rounded-md border border-primary/10 bg-primary-xlight px-2 py-1">
            <StarIcon size={11} className="text-primary" />
            <span className="text-[10px] font-black text-primary">{court.rating}</span>
          </span>
        </div>

        <div className="mt-2.5 flex items-start gap-1">
          <PinIcon size={12} className="mt-0.5 shrink-0 text-primary" />
          <span className="text-[9px] font-extrabold uppercase leading-relaxed tracking-wide text-slate-400">
            {court.location}
          </span>
        </div>

        <div className="mt-3 flex flex-wrap gap-1.5">
          {court.amenities.slice(0, 3).map((a) => (
            <span
              key={a}
              className="rounded-md border border-slate-200 bg-slate-100 px-2 py-1 text-[8px] font-black uppercase tracking-wide text-slate-400"
            >
              {a}
            </span>
          ))}
        </div>

        <div className="my-4 h-px bg-slate-100" />

        <div className="flex items-center justify-between">
          <p className="t-price">
            ₱{court.price}
            <span className="text-[10px] font-black tracking-wide text-slate-400">/hr</span>
          </p>
          <div className="flex items-center gap-2">
            <button
              onClick={onDetails}
              className="rounded-[14px] border border-slate-300 px-3.5 py-3 text-[10px] font-black uppercase tracking-wider text-primary transition hover:border-primary/40"
            >
              Details
            </button>
            <button
              onClick={onBook}
              className="rounded-[14px] bg-primary px-5 py-3 text-[10px] font-black uppercase tracking-wider text-white shadow-cta transition hover:bg-primary-dark"
            >
              Book
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
