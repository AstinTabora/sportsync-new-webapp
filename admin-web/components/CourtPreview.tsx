"use client";

import {
  Star,
  MapPin,
  Image as ImageIcon,
  Phone,
  Mail,
  Clock,
} from "lucide-react";
import { amenitiesToArray, type CourtFormValues } from "@/lib/data/courts";

// Mobile app palette (mirrors lib/features/courts/*).
const PRIMARY = "#005F02";
const PRIMARY_XLIGHT = "#E6F0E6";
const SLATE50 = "#F8FAFC";
const SLATE100 = "#F1F5F9";
const SLATE400 = "#94A3B8";
const SLATE500 = "#64748B";
const SLATE600 = "#475569";
const SLATE_BORDER = "#E2E8F0";
const EMERALD = "#10B981";

const TYPE_LABEL: Record<string, string> = {
  badminton: "BADMINTON",
  pickleball: "PICKLEBALL",
  basketball: "BASKETBALL",
};

interface PreviewProps {
  values: Partial<CourtFormValues>;
  images: string[];
}

function read(values: Partial<CourtFormValues>, images: string[]) {
  const name = values.name?.trim() || "Your court name";
  const type = (values.type as string) || "badminton";
  const typeLabel = TYPE_LABEL[type] ?? type.toUpperCase();
  const location = values.location?.trim() || "Court location";
  // Watched form values come through as strings, so coerce with Number()
  // (Number.isFinite on a string is always false → everything fell back to 0).
  const priceNum = Number(values.price);
  const price = Number.isFinite(priceNum) ? Math.round(priceNum) : 0;
  const ratingNum = Number(values.rating);
  const rating = Number.isFinite(ratingNum) ? ratingNum : 0;
  const courtsNum = Number(values.numberOfCourts);
  const numberOfCourts =
    Number.isFinite(courtsNum) && courtsNum > 0 ? courtsNum : 1;
  const amenities = amenitiesToArray(values.amenities);
  const cover = images[0] ?? "";
  return { name, type, typeLabel, location, price, rating, numberOfCourts, amenities, cover };
}

// ─── Browse card ──────────────────────────────────────────────────────────────

export function CourtCardPreview({ values, images }: PreviewProps) {
  const v = read(values, images);
  const openToday = v.numberOfCourts * 15;

  return (
    <div
      className="w-[300px] overflow-hidden rounded-3xl bg-white"
      style={{ border: `1px solid ${SLATE100}`, boxShadow: "0 2px 12px rgba(0,0,0,0.06)" }}
    >
      <div className="relative h-40 w-full">
        <Cover src={v.cover} />
        <div className="absolute left-3 top-3 flex gap-1.5">
          <Badge bg={PRIMARY} color="#fff">{v.typeLabel}</Badge>
          <Badge bg="rgba(255,255,255,0.95)" color={PRIMARY}>
            {v.numberOfCourts} COURTS
          </Badge>
        </div>
        <div className="absolute bottom-2.5 right-2.5">
          <Badge bg={EMERALD} color="#fff">{openToday} OPEN TODAY</Badge>
        </div>
      </div>

      <div className="p-5">
        <div className="flex items-start gap-2">
          <h3 className="flex-1 text-base font-extrabold leading-tight text-slate-900">
            {v.name}
          </h3>
          <div className="flex items-center gap-1 rounded-lg px-2 py-1" style={{ backgroundColor: PRIMARY_XLIGHT }}>
            <Star size={11} style={{ color: PRIMARY }} fill={PRIMARY} />
            <span className="text-[10px] font-extrabold" style={{ color: PRIMARY }}>
              {v.rating.toFixed(1)}
            </span>
          </div>
        </div>

        <div className="mt-2.5 flex items-start gap-1">
          <MapPin size={12} style={{ color: PRIMARY }} className="mt-0.5 shrink-0" />
          <span className="text-[9px] font-bold uppercase leading-snug tracking-wide" style={{ color: SLATE400 }}>
            {v.location}
          </span>
        </div>

        {v.amenities.length > 0 && (
          <div className="mt-3 flex flex-wrap gap-1.5">
            {v.amenities.slice(0, 3).map((a, i) => (
              <Chip key={i}>{a}</Chip>
            ))}
          </div>
        )}

        <div className="my-4 h-px" style={{ backgroundColor: SLATE100 }} />

        <div className="flex items-center">
          <div className="flex-1">
            <span className="text-xl font-extrabold" style={{ color: PRIMARY }}>₱{v.price}</span>
            <span className="text-[10px] font-extrabold tracking-wide" style={{ color: SLATE400 }}>/hr</span>
          </div>
          <div className="flex gap-2">
            <span className="rounded-xl border px-3 py-2 text-[10px] font-extrabold tracking-wider" style={{ color: PRIMARY, borderColor: "#CBD5E1" }}>
              DETAILS
            </span>
            <span className="rounded-xl px-4 py-2 text-[10px] font-extrabold tracking-wider text-white" style={{ backgroundColor: PRIMARY }}>
              BOOK
            </span>
          </div>
        </div>
      </div>
    </div>
  );
}

// ─── Detail page ──────────────────────────────────────────────────────────────

export function CourtDetailPreview({ values, images }: PreviewProps) {
  const v = read(values, images);
  const mapUrl = (values.mapUrl ?? "").trim();
  const isEmbed = mapUrl.includes("/maps/embed");
  const desc = values.description?.trim();
  const descr = desc
    ? `${desc} ${v.numberOfCourts} courts available daily 8am–11pm.`
    : `${v.numberOfCourts} courts available daily 8am–11pm.`;

  return (
    <div
      className="flex w-[320px] flex-col overflow-hidden rounded-[1.75rem] bg-white"
      style={{ border: `1px solid ${SLATE_BORDER}`, boxShadow: "0 4px 16px rgba(0,0,0,0.08)" }}
    >
      <div className="max-h-[600px] overflow-y-auto">
        {/* Photo header */}
        <div className="relative h-44 w-full">
          <Cover src={v.cover} />
          <div
            className="absolute inset-0"
            style={{ background: "linear-gradient(to bottom, rgba(0,0,0,0.30), transparent 40%, rgba(0,0,0,0.40))" }}
          />
        </div>

        {/* Title card */}
        <div className="relative z-10 px-3">
          <div
            className="-mt-6 rounded-2xl bg-white p-4"
            style={{ border: `1px solid ${SLATE100}`, boxShadow: "0 4px 12px rgba(0,0,0,0.06)" }}
          >
            <div className="flex flex-wrap items-center gap-1.5">
              <Pill fg={PRIMARY} bg={PRIMARY_XLIGHT}>{v.typeLabel}</Pill>
              <Pill fg={PRIMARY} bg={SLATE50}>★ {v.rating.toFixed(1)}</Pill>
              <Pill fg={EMERALD} bg="#ECFDF5">OPEN NOW</Pill>
            </div>
            <h3 className="mt-3 text-lg font-extrabold text-slate-900">{v.name}</h3>
            <div className="mt-2 flex items-start gap-1.5">
              <MapPin size={13} style={{ color: PRIMARY }} className="mt-0.5 shrink-0" />
              <span className="text-xs font-semibold" style={{ color: SLATE500 }}>{v.location}</span>
            </div>
          </div>
        </div>

        {/* Description + amenities */}
        <div className="px-4 pt-4">
          <p className="text-sm leading-relaxed" style={{ color: SLATE600 }}>{descr}</p>
          {v.amenities.length > 0 && (
            <div className="mt-3 flex flex-wrap gap-1.5">
              {v.amenities.map((a, i) => (
                <Chip key={i}>{a}</Chip>
              ))}
            </div>
          )}
        </div>

        {/* Location */}
        <div className="px-4 pt-5">
          <SectionHeader label="LOCATION" />
          <div
            className="mt-2 h-36 overflow-hidden rounded-2xl"
            style={{ backgroundColor: SLATE50, border: `1px solid ${SLATE100}` }}
          >
            {isEmbed ? (
              <iframe
                src={mapUrl}
                className="h-full w-full border-0"
                loading="lazy"
                referrerPolicy="no-referrer-when-downgrade"
                title="Map preview"
              />
            ) : (
              <div
                className="flex h-full w-full items-center justify-center"
                style={{ background: "linear-gradient(135deg,#E8EFE6,#D4E2D1)" }}
              >
                <MapPin size={28} style={{ color: PRIMARY }} />
              </div>
            )}
          </div>
        </div>

        {/* Gallery */}
        <div className="pt-5">
          <div className="px-4">
            <SectionHeader label={`GALLERY${images.length ? ` (${images.length})` : ""}`} />
          </div>
          <div className="mt-2 flex gap-2 overflow-x-auto px-4 pb-1">
            {images.length > 0 ? (
              images.map((src, i) => (
                <div key={i} className="h-20 w-28 shrink-0 overflow-hidden rounded-xl">
                  {/* eslint-disable-next-line @next/next/no-img-element */}
                  <img src={src} alt="" className="h-full w-full object-cover" />
                </div>
              ))
            ) : (
              <div
                className="flex h-20 w-28 shrink-0 items-center justify-center rounded-xl"
                style={{ backgroundColor: PRIMARY_XLIGHT }}
              >
                <ImageIcon size={22} style={{ color: PRIMARY }} />
              </div>
            )}
          </div>
        </div>

        {/* Pricing */}
        <div className="px-4 pt-5">
          <SectionHeader label="PRICING" />
          <div
            className="mt-2 flex items-center rounded-2xl p-4"
            style={{ border: `1px solid ${SLATE100}` }}
          >
            <div className="flex-1">
              <div className="text-[10px] font-bold uppercase tracking-wide" style={{ color: SLATE400 }}>
                Hourly rate
              </div>
              <div className="mt-1">
                <span className="text-2xl font-extrabold" style={{ color: PRIMARY }}>₱{v.price}</span>
                <span className="text-xs font-bold" style={{ color: SLATE400 }}> /hr</span>
              </div>
              <div className="mt-1 text-xs" style={{ color: SLATE400 }}>Per court · No commitment</div>
            </div>
            <div
              className="flex h-11 w-11 items-center justify-center rounded-lg"
              style={{ backgroundColor: PRIMARY_XLIGHT }}
            >
              <Star size={20} style={{ color: PRIMARY }} />
            </div>
          </div>
        </div>

        {/* Contact */}
        <div className="px-4 py-5">
          <SectionHeader label="CONTACT" />
          <div className="mt-2 overflow-hidden rounded-2xl" style={{ border: `1px solid ${SLATE100}` }}>
            <ContactRow icon={<Phone size={14} style={{ color: PRIMARY }} />} text={values.phone?.trim() || "—"} trail="CALL" />
            <div className="h-px" style={{ backgroundColor: SLATE100 }} />
            <ContactRow icon={<Mail size={14} style={{ color: PRIMARY }} />} text={values.email?.trim() || "—"} trail="EMAIL" />
            <div className="h-px" style={{ backgroundColor: SLATE100 }} />
            <ContactRow icon={<Clock size={14} style={{ color: PRIMARY }} />} text="Daily · 8 AM – 11 PM" trail="OPEN" trailColor={EMERALD} />
          </div>
        </div>
      </div>

      {/* Book bar */}
      <div className="flex items-center justify-between border-t px-4 py-3" style={{ borderColor: SLATE100 }}>
        <div>
          <span className="text-lg font-extrabold" style={{ color: PRIMARY }}>₱{v.price}</span>
          <span className="text-xs font-bold" style={{ color: SLATE400 }}>/hr</span>
        </div>
        <span className="rounded-xl px-6 py-2.5 text-xs font-extrabold tracking-wider text-white" style={{ backgroundColor: PRIMARY }}>
          BOOK NOW
        </span>
      </div>
    </div>
  );
}

// ─── shared bits ──────────────────────────────────────────────────────────────

function Cover({ src }: { src: string }) {
  if (src) {
    // eslint-disable-next-line @next/next/no-img-element
    return <img src={src} alt="Court cover" className="h-full w-full object-cover" />;
  }
  return (
    <div className="flex h-full w-full flex-col items-center justify-center gap-1" style={{ backgroundColor: PRIMARY_XLIGHT }}>
      <ImageIcon size={28} style={{ color: PRIMARY }} />
      <span className="text-[10px] font-bold tracking-wide" style={{ color: PRIMARY }}>Cover image</span>
    </div>
  );
}

function Badge({ children, bg, color }: { children: React.ReactNode; bg: string; color: string }) {
  return (
    <span className="rounded-lg px-2 py-1 text-[8px] font-extrabold tracking-wide shadow" style={{ backgroundColor: bg, color }}>
      {children}
    </span>
  );
}

function Chip({ children }: { children: React.ReactNode }) {
  return (
    <span
      className="rounded-lg px-2 py-1 text-[8px] font-extrabold uppercase tracking-wide"
      style={{ backgroundColor: SLATE100, color: SLATE400, border: `1px solid ${SLATE_BORDER}` }}
    >
      {children}
    </span>
  );
}

function Pill({ children, fg, bg }: { children: React.ReactNode; fg: string; bg: string }) {
  return (
    <span
      className="rounded-md px-2 py-1 text-[9px] font-extrabold tracking-wider"
      style={{ color: fg, backgroundColor: bg, border: `1px solid ${fg}1a` }}
    >
      {children}
    </span>
  );
}

function SectionHeader({ label }: { label: string }) {
  return (
    <div className="text-[10px] font-extrabold uppercase tracking-widest" style={{ color: SLATE400 }}>
      {label}
    </div>
  );
}

function ContactRow({
  icon,
  text,
  trail,
  trailColor = PRIMARY,
}: {
  icon: React.ReactNode;
  text: string;
  trail: string;
  trailColor?: string;
}) {
  return (
    <div className="flex items-center gap-3 px-4 py-3">
      {icon}
      <span className="flex-1 truncate text-xs font-medium text-slate-700">{text}</span>
      <span className="text-[9px] font-extrabold tracking-wider" style={{ color: trailColor }}>{trail}</span>
    </div>
  );
}
