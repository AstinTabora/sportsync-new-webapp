import type { Court } from "../../data/types";
import { PinIcon, StarIcon } from "../ui/Icon";

interface Props {
  court: Court;
  onDetails: () => void;
  onBook: () => void;
}

// Compact horizontal row — mirrors court_card_compact.dart.
export default function CourtCardCompact({ court, onDetails, onBook }: Props) {
  return (
    <button
      onClick={onDetails}
      className="flex w-full items-center gap-3 rounded-xl border border-slate-100 bg-white p-3 text-left shadow-subtle transition hover:shadow-card"
    >
      <img
        src={court.image}
        alt={court.name}
        className="h-20 w-20 shrink-0 rounded-lg object-cover"
        loading="lazy"
      />
      <div className="min-w-0 flex-1">
        <div className="flex items-center justify-between gap-2">
          <h3 className="truncate text-[15px] font-extrabold tracking-[-0.3px] text-primary">
            {court.name}
          </h3>
          <span className="flex shrink-0 items-center gap-0.5 text-primary">
            <StarIcon size={11} />
            <span className="text-[10px] font-black">{court.rating}</span>
          </span>
        </div>
        <div className="mt-1 flex items-center gap-1">
          <PinIcon size={11} className="text-slate-400" />
          <span className="truncate text-[9px] font-extrabold uppercase tracking-wide text-slate-400">
            {court.location}
          </span>
        </div>
        <div className="mt-2 flex items-center justify-between">
          <p className="text-[16px] font-extrabold text-primary">
            ₱{court.price}
            <span className="text-[9px] font-black text-slate-400">/hr</span>
          </p>
          <span
            onClick={(e) => {
              e.stopPropagation();
              onBook();
            }}
            className="rounded-lg bg-primary px-4 py-2 text-[10px] font-black uppercase tracking-wider text-white"
          >
            Book
          </span>
        </div>
      </div>
    </button>
  );
}
