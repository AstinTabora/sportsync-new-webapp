import { useNavigate, useParams } from "react-router-dom";
import { courtById, SPORT_LABELS } from "../data/courts";
import { useBookingFlow } from "../state/BookingFlowContext";
import {
  ArrowLeft,
  PinIcon,
  SportIcon,
  StarIcon,
} from "../components/ui/Icon";

export default function CourtDetailPage() {
  const { id } = useParams();
  const navigate = useNavigate();
  const flow = useBookingFlow();
  const court = courtById(id);

  if (!court) {
    return (
      <div className="grid min-h-screen place-items-center px-6 text-center">
        <div>
          <p className="t-page-title">Court not found</p>
          <button onClick={() => navigate("/home")} className="mt-3 text-[11px] font-black uppercase tracking-wider text-primary">
            Back to home
          </button>
        </div>
      </div>
    );
  }

  function startBooking() {
    flow.reset(court!);
    navigate(`/courts/${court!.id}/book`);
  }

  // Mock reviews
  const reviews = [
    { name: "Maria L.", rating: 5, text: "Clean courts and great lighting. Will book again!" },
    { name: "Josh R.", rating: 4, text: "Friendly staff, easy to find. Slots fill up fast on weekends." },
  ];

  return (
    <div className="pb-28 md:pb-12">
      {/* Hero image */}
      <div className="relative h-72 md:mx-6 md:mt-6 md:h-96 md:rounded-3xl md:overflow-hidden">
        <img src={court.image} alt={court.name} className="h-full w-full object-cover" />
        <div className="absolute inset-0 bg-gradient-to-t from-black/60 via-transparent to-black/20" />
        <button
          onClick={() => navigate(-1)}
          className="absolute left-4 top-4 flex items-center gap-1.5 rounded-pill bg-white/90 px-3 py-2 text-[10px] font-black uppercase tracking-wider text-primary shadow-md backdrop-blur"
          style={{ top: "max(1rem, env(safe-area-inset-top))" }}
        >
          <ArrowLeft size={14} /> Back
        </button>
        <div className="absolute bottom-4 left-4 right-4 flex items-end justify-between">
          <div>
            <span className="inline-flex items-center gap-1.5 rounded-md bg-primary px-2.5 py-1 text-[9px] font-black uppercase tracking-wide text-white">
              <SportIcon type={court.type} size={11} /> {SPORT_LABELS[court.type]}
            </span>
            <h1 className="mt-2 text-2xl font-black tracking-tight text-white">{court.name}</h1>
          </div>
        </div>
      </div>

      <div className="mx-auto max-w-content px-4 md:px-6">
        <div className="mt-5 grid gap-6 lg:grid-cols-[1fr_360px]">
          {/* Left column */}
          <div className="space-y-6">
            <div className="flex flex-wrap gap-3">
              <Stat icon={<StarIcon size={14} />} value={court.rating.toFixed(1)} label="Rating" />
              <Stat icon={<SportIcon type={court.type} size={14} />} value={`${court.numberOfCourts}`} label="Courts" />
              <Stat icon={<PinIcon size={14} />} value="Davao" label="City" />
            </div>

            <section>
              <h2 className="t-micro text-slate-500">About</h2>
              <p className="t-body mt-2">{court.description}</p>
            </section>

            <section>
              <h2 className="t-micro text-slate-500">Amenities</h2>
              <div className="mt-2 flex flex-wrap gap-2">
                {court.amenities.map((a) => (
                  <span key={a} className="rounded-md border border-slate-200 bg-slate-50 px-3 py-1.5 text-[10px] font-black uppercase tracking-wide text-slate-500">
                    {a}
                  </span>
                ))}
              </div>
            </section>

            <section>
              <h2 className="t-micro text-slate-500">Location</h2>
              <div className="mt-2 flex items-start gap-1.5">
                <PinIcon size={14} className="mt-0.5 text-primary" />
                <p className="t-body-bold text-slate-600">{court.location}</p>
              </div>
              <div className="mt-3 overflow-hidden rounded-2xl border border-slate-100">
                <iframe
                  title={`Map of ${court.name}`}
                  src={court.mapUrl}
                  className="h-64 w-full"
                  loading="lazy"
                  referrerPolicy="no-referrer-when-downgrade"
                />
              </div>
            </section>

            <section>
              <h2 className="t-micro text-slate-500">Reviews</h2>
              <div className="mt-2 space-y-2">
                {reviews.map((r) => (
                  <div key={r.name} className="rounded-2xl border border-slate-100 bg-white p-4">
                    <div className="flex items-center justify-between">
                      <span className="text-[13px] font-extrabold text-primary">{r.name}</span>
                      <span className="flex items-center gap-0.5 text-primary">
                        {Array.from({ length: r.rating }).map((_, i) => (
                          <StarIcon key={i} size={11} />
                        ))}
                      </span>
                    </div>
                    <p className="t-body mt-1">{r.text}</p>
                  </div>
                ))}
              </div>
            </section>
          </div>

          {/* Right column — sticky booking CTA (desktop) */}
          <aside className="hidden lg:block">
            <div className="sticky top-6 rounded-3xl border border-slate-100 bg-white p-6 shadow-card">
              <p className="t-eyebrow">Starting at</p>
              <p className="t-price-mega mt-1">
                ₱{court.price}
                <span className="text-[12px] font-black text-slate-400">/hr</span>
              </p>
              <button
                onClick={startBooking}
                className="mt-5 w-full rounded-md bg-primary py-4 text-[12px] font-extrabold uppercase tracking-wider text-white shadow-cta transition hover:bg-primary-dark"
              >
                Book Now
              </button>
              <div className="mt-4 space-y-1.5 text-[11px] font-semibold text-slate-500">
                <p>📞 {court.phone}</p>
                <p>✉️ {court.email}</p>
              </div>
            </div>
          </aside>
        </div>
      </div>

      {/* Mobile sticky book bar */}
      <div
        className="fixed inset-x-0 bottom-0 z-20 border-t border-slate-100 bg-white/95 px-4 py-3 backdrop-blur lg:hidden"
        style={{ paddingBottom: "max(0.75rem, calc(env(safe-area-inset-bottom) + 4.5rem))" }}
      >
        <div className="mx-auto flex max-w-content items-center justify-between gap-4">
          <p className="t-price-mega">
            ₱{court.price}
            <span className="text-[11px] font-black text-slate-400">/hr</span>
          </p>
          <button
            onClick={startBooking}
            className="flex-1 rounded-md bg-primary py-3.5 text-[12px] font-extrabold uppercase tracking-wider text-white shadow-cta"
          >
            Book Now
          </button>
        </div>
      </div>
    </div>
  );
}

function Stat({ icon, value, label }: { icon: React.ReactNode; value: string; label: string }) {
  return (
    <div className="flex flex-1 flex-col items-center gap-1 rounded-xl border border-slate-100 bg-white py-3">
      <span className="text-primary">{icon}</span>
      <span className="t-stat">{value}</span>
      <span className="t-micro">{label}</span>
    </div>
  );
}
