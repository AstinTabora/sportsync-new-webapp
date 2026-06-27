"use client";

import { useEffect, useMemo, useState } from "react";
import Link from "next/link";
import { collection, doc, getDoc, onSnapshot } from "firebase/firestore";
import { ChevronLeft, ChevronRight, Calendar } from "lucide-react";
import { db } from "@/lib/firebase/client";
import { DAYS } from "@/lib/data/schedule";
import type { OwnerCourtLite } from "@/lib/data/ownerCourts";
import { cn, formatPHP } from "@/lib/utils";
import { Card } from "./ui/Card";
import { Button } from "./ui/Button";

export interface GridBooking {
  refCode: string;
  courtId: string;
  dateStr: string;
  status: string;
  totalAmount: number;
  userName: string;
  userEmail: string;
  userPhone: string;
  slots: Array<{ court: string; time: string }>;
}

// Mirrors the mobile booking grid's fixed hourly slots (time_slot_grid.dart).
const CANONICAL_SLOTS = [
  "8am - 9am", "9am - 10am", "10am - 11am", "11am - 12pm",
  "12pm - 1pm", "1pm - 2pm", "2pm - 3pm", "3pm - 4pm",
  "4pm - 5pm", "5pm - 6pm", "6pm - 7pm", "7pm - 8pm",
  "8pm - 9pm", "9pm - 10pm", "10pm - 11pm", "11pm - 12am",
];

const PERIODS: Array<{ name: string; lo: number; hi: number }> = [
  { name: "Morning", lo: 8, hi: 11 },
  { name: "Afternoon", lo: 12, hi: 16 },
  { name: "Evening", lo: 17, hi: 23 },
];

interface ScheduleSlotLite {
  time: string;
  price: number;
}
interface BlockoutLite {
  startDate: string;
  endDate: string;
  slots: string[] | "all";
}

export function BookingGrid({
  courts,
  bookings,
}: {
  courts: OwnerCourtLite[];
  bookings: GridBooking[];
}) {
  const [selectedCourtId, setSelectedCourtId] = useState("");
  const [dateStr, setDateStr] = useState(todayStr);
  const [schedule, setSchedule] = useState<ScheduleSlotLite[]>([]);
  const [blockouts, setBlockouts] = useState<BlockoutLite[]>([]);
  const [hovered, setHovered] = useState<{
    b: GridBooking;
    top: number;
    left: number;
  } | null>(null);

  // Default to the first court once they load.
  useEffect(() => {
    if (!selectedCourtId && courts.length) setSelectedCourtId(courts[0].id);
  }, [courts, selectedCourtId]);

  const court = courts.find((c) => c.id === selectedCourtId) ?? null;
  const weekday = useMemo(() => weekdayOf(dateStr), [dateStr]);

  // Schedule for the selected court + weekday (prices + rate bands).
  useEffect(() => {
    if (!selectedCourtId) return;
    let active = true;
    getDoc(doc(db, "courts", selectedCourtId, "schedule", weekday))
      .then((snap) => {
        if (!active) return;
        setSchedule(
          snap.exists() ? ((snap.data().slots ?? []) as ScheduleSlotLite[]) : []
        );
      })
      .catch(() => active && setSchedule([]));
    return () => {
      active = false;
    };
  }, [selectedCourtId, weekday]);

  // Block-outs for the selected court.
  useEffect(() => {
    if (!selectedCourtId) return;
    const unsub = onSnapshot(
      collection(db, "courts", selectedCourtId, "blockouts"),
      (snap) =>
        setBlockouts(
          snap.docs.map((d) => {
            const x = d.data();
            return {
              startDate: x.startDate,
              endDate: x.endDate,
              slots: x.slots,
            } as BlockoutLite;
          })
        )
    );
    return () => unsub();
  }, [selectedCourtId]);

  const priceByHour = useMemo(() => {
    const m = new Map<number, number>();
    for (const s of schedule) m.set(hhmmToHour(s.time), s.price);
    return m;
  }, [schedule]);

  // "Court N|time" -> confirmed booking.
  const bookedMap = useMemo(() => {
    const m = new Map<string, GridBooking>();
    for (const b of bookings) {
      if (b.courtId !== selectedCourtId || b.dateStr !== dateStr) continue;
      if (b.status !== "paid" && b.status !== "cash") continue;
      for (const s of b.slots) m.set(`${s.court}|${s.time}`, b);
    }
    return m;
  }, [bookings, selectedCourtId, dateStr]);

  const blockedHours = useMemo(() => {
    const set = new Set<number>();
    for (const bo of blockouts) {
      if (dateStr < bo.startDate || dateStr > bo.endDate) continue;
      if (bo.slots === "all") {
        for (const lbl of CANONICAL_SLOTS) set.add(slotStartHour(lbl));
      } else {
        for (const t of bo.slots) set.add(hhmmToHour(t));
      }
    }
    return set;
  }, [blockouts, dateStr]);

  const numCourts = court?.numberOfCourts ?? 0;
  const courtCols = useMemo(
    () => Array.from({ length: numCourts }, (_, i) => `Court ${i + 1}`),
    [numCourts]
  );

  const totalCells = numCourts * CANONICAL_SLOTS.length;
  const bookedCount = bookedMap.size;
  const blockedCells = blockedHours.size * numCourts;
  const openCells = Math.max(0, totalCells - bookedCount - blockedCells);
  const revenue = useMemo(() => {
    const seen = new Set<string>();
    let sum = 0;
    for (const b of bookings) {
      if (b.courtId !== selectedCourtId || b.dateStr !== dateStr) continue;
      if (b.status !== "paid" || seen.has(b.refCode)) continue;
      seen.add(b.refCode);
      sum += b.totalAmount;
    }
    return sum;
  }, [bookings, selectedCourtId, dateStr]);

  const rateBands = useMemo(() => computeRateBands(schedule), [schedule]);

  if (courts.length === 0) {
    return (
      <Card className="p-8 text-center text-sm text-slate-500">
        Create a court to see its availability grid.
      </Card>
    );
  }

  return (
    <div className="space-y-4">
      {/* Court tabs */}
      {courts.length > 1 && (
        <div className="flex flex-wrap gap-2">
          {courts.map((c) => (
            <button
              key={c.id}
              onClick={() => setSelectedCourtId(c.id)}
              className={cn(
                "rounded-lg border px-4 py-2 text-left transition-colors",
                c.id === selectedCourtId
                  ? "border-brand-500 bg-brand-50"
                  : "border-slate-200 bg-white hover:bg-slate-50"
              )}
            >
              <div className="text-sm font-semibold text-slate-900">
                {c.name}
              </div>
              <div className="text-xs text-slate-500">
                from {formatPHP(c.price)}/hr
              </div>
            </button>
          ))}
        </div>
      )}

      {/* Date nav */}
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div className="flex items-center gap-2">
          <Calendar size={18} className="text-brand-600" />
          <span className="text-lg font-bold text-slate-900">
            {fmtDateLabel(dateStr)}
          </span>
        </div>
        <div className="flex items-center gap-2">
          <Button
            size="sm"
            variant="secondary"
            onClick={() => setDateStr(shiftDate(dateStr, -1))}
            title="Previous day"
          >
            <ChevronLeft size={16} />
          </Button>
          <input
            type="date"
            value={dateStr}
            onChange={(e) => e.target.value && setDateStr(e.target.value)}
            className="h-8 rounded-md border border-slate-300 px-2 text-sm"
          />
          <Button
            size="sm"
            variant="secondary"
            onClick={() => setDateStr(shiftDate(dateStr, 1))}
            title="Next day"
          >
            <ChevronRight size={16} />
          </Button>
          <Button size="sm" variant="ghost" onClick={() => setDateStr(todayStr())}>
            Today
          </Button>
        </div>
      </div>

      {/* Rates */}
      <div className="flex flex-wrap items-center gap-3 rounded-lg border border-slate-200 bg-white px-4 py-3">
        <span className="text-sm font-semibold text-slate-700">Rates:</span>
        {rateBands.length > 0 ? (
          rateBands.map((band, i) => (
            <span
              key={i}
              className="flex items-center gap-2 rounded-md border border-slate-200 px-3 py-1.5"
            >
              <span className="text-sm font-bold text-brand-700">
                {formatPHP(band.price)}
              </span>
              <span className="text-xs text-slate-500">{band.label}</span>
            </span>
          ))
        ) : (
          <span className="flex items-center gap-2 rounded-md border border-slate-200 px-3 py-1.5">
            <span className="text-sm font-bold text-brand-700">
              {formatPHP(court?.price ?? 0)}
            </span>
            <span className="text-xs text-slate-500">all day</span>
          </span>
        )}
      </div>

      {/* Day summary + legend */}
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div className="text-sm text-slate-600">
          <span className="font-semibold text-slate-900">{bookedCount}</span> of{" "}
          {totalCells} slots booked · {openCells} open ·{" "}
          <span className="font-semibold text-brand-700">
            {formatPHP(revenue)}
          </span>{" "}
          expected
        </div>
        <div className="flex items-center gap-3 text-xs text-slate-500">
          <Legend className="bg-white border border-slate-200" label="Available" />
          <Legend className="bg-brand-600" label="Booked" />
          <Legend className="bg-red-500" label="Blocked" />
        </div>
      </div>

      {/* Grid */}
      {numCourts === 0 ? (
        <Card className="p-8 text-center text-sm text-slate-500">
          This court has no sub-courts configured.
        </Card>
      ) : (
        <Card className="overflow-x-auto">
          <table className="w-full border-collapse text-sm">
            <thead>
              <tr className="border-b border-slate-200 bg-slate-50">
                <th className="sticky left-0 z-10 bg-slate-50 px-4 py-3 text-left font-medium text-slate-500">
                  Time
                </th>
                {courtCols.map((c) => (
                  <th
                    key={c}
                    className="min-w-[110px] px-3 py-3 text-center font-semibold text-slate-700"
                  >
                    {c}
                    <div className="text-[10px] font-normal text-slate-400">
                      {court?.name}
                    </div>
                  </th>
                ))}
              </tr>
            </thead>
            <tbody>
              {PERIODS.map((period) => {
                const rows = CANONICAL_SLOTS.filter((lbl) => {
                  const h = slotStartHour(lbl);
                  return h >= period.lo && h <= period.hi;
                });
                if (rows.length === 0) return null;
                return (
                  <PeriodSection
                    key={period.name}
                    name={period.name}
                    rows={rows}
                    courtCols={courtCols}
                    colCount={courtCols.length + 1}
                    priceByHour={priceByHour}
                    fallbackPrice={court?.price ?? 0}
                    bookedMap={bookedMap}
                    blockedHours={blockedHours}
                    onHover={setHovered}
                  />
                );
              })}
            </tbody>
          </table>
        </Card>
      )}

      {/* Hover card — fixed so the table's scroll container can't clip it. */}
      {hovered && (
        <div
          className="pointer-events-none fixed z-50 w-60 rounded-lg border border-slate-200 bg-white p-3 shadow-xl"
          style={{ top: hovered.top, left: hovered.left }}
        >
          <div className="text-sm font-semibold text-slate-900">
            {hovered.b.userName || "—"}
          </div>
          <div className="mt-1 space-y-0.5 text-xs text-slate-600">
            <div>📞 {hovered.b.userPhone || "—"}</div>
            <div>✉️ {hovered.b.userEmail || "—"}</div>
            <div className="pt-1 text-slate-500">
              {formatPHP(hovered.b.totalAmount)} · {hovered.b.refCode}
            </div>
          </div>
          <div className="mt-1 text-xs font-medium text-brand-700">
            Click to view booking →
          </div>
        </div>
      )}
    </div>
  );
}

function PeriodSection({
  name,
  rows,
  courtCols,
  colCount,
  priceByHour,
  fallbackPrice,
  bookedMap,
  blockedHours,
  onHover,
}: {
  name: string;
  rows: string[];
  courtCols: string[];
  colCount: number;
  priceByHour: Map<number, number>;
  fallbackPrice: number;
  bookedMap: Map<string, GridBooking>;
  blockedHours: Set<number>;
  onHover: (
    v: { b: GridBooking; top: number; left: number } | null
  ) => void;
}) {
  return (
    <>
      <tr>
        <td
          colSpan={colCount}
          className="bg-slate-100/70 px-4 py-1.5 text-xs font-bold uppercase tracking-wide text-slate-500"
        >
          {name}
        </td>
      </tr>
      {rows.map((label) => {
        const hour = slotStartHour(label);
        const price = priceByHour.get(hour) ?? fallbackPrice;
        const blocked = blockedHours.has(hour);
        return (
          <tr key={label} className="border-b border-slate-100 last:border-0">
            <td className="sticky left-0 z-10 bg-white px-4 py-2 align-top">
              <div className="font-medium text-slate-800">{label}</div>
              <div className="text-xs text-brand-700">{formatPHP(price)}</div>
            </td>
            {courtCols.map((col) => {
              const booking = bookedMap.get(`${col}|${label}`);
              if (booking) {
                return (
                  <td key={col} className="p-1">
                    <Link
                      href={`/bookings/${booking.refCode}`}
                      onMouseEnter={(e) => {
                        const r = e.currentTarget.getBoundingClientRect();
                        onHover({ b: booking, top: r.bottom + 6, left: r.left });
                      }}
                      onMouseLeave={() => onHover(null)}
                      className="flex h-12 items-center justify-center rounded-md bg-brand-600 text-xs font-semibold text-white transition-colors hover:bg-brand-700"
                    >
                      Booked
                    </Link>
                  </td>
                );
              }
              if (blocked) {
                return (
                  <td key={col} className="p-1">
                    <div className="flex h-12 items-center justify-center rounded-md bg-red-50 text-xs font-semibold text-red-600 ring-1 ring-inset ring-red-200">
                      Blocked
                    </div>
                  </td>
                );
              }
              return (
                <td key={col} className="p-1">
                  <div className="h-12 rounded-md bg-slate-50 ring-1 ring-inset ring-slate-100" />
                </td>
              );
            })}
          </tr>
        );
      })}
    </>
  );
}

function Legend({ className, label }: { className: string; label: string }) {
  return (
    <span className="flex items-center gap-1.5">
      <span className={cn("inline-block h-3 w-3 rounded", className)} />
      {label}
    </span>
  );
}

// ─── helpers ────────────────────────────────────────────────────────────────

function slotStartHour(label: string): number {
  const start = label.split(" - ")[0].trim().toLowerCase();
  if (start === "12am") return 0;
  if (start === "12pm") return 12;
  const n = parseInt(start.replace(/[apm]/g, ""), 10) || 0;
  return start.endsWith("pm") ? n + 12 : n;
}

function hhmmToHour(t: string): number {
  return parseInt((t ?? "").split(":")[0], 10) || 0;
}

function fmtHour(h: number): string {
  const ampm = h < 12 ? "AM" : "PM";
  let hr = h % 12;
  if (hr === 0) hr = 12;
  return `${hr} ${ampm}`;
}

function todayStr(): string {
  const d = new Date();
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(
    d.getDate()
  ).padStart(2, "0")}`;
}

function shiftDate(dateStr: string, days: number): string {
  const d = new Date(dateStr + "T00:00:00Z");
  d.setUTCDate(d.getUTCDate() + days);
  return d.toISOString().slice(0, 10);
}

function weekdayOf(dateStr: string): string {
  const d = new Date(dateStr + "T00:00:00Z");
  const idx = (d.getUTCDay() + 6) % 7; // Mon=0 … Sun=6, matches DAYS
  return DAYS[idx];
}

function fmtDateLabel(dateStr: string): string {
  return new Date(dateStr + "T00:00:00Z").toLocaleDateString("en-US", {
    weekday: "short",
    month: "short",
    day: "numeric",
    timeZone: "UTC",
  });
}

function computeRateBands(
  schedule: ScheduleSlotLite[]
): Array<{ price: number; label: string }> {
  if (schedule.length === 0) return [];
  const sorted = [...schedule]
    .map((s) => ({ hour: hhmmToHour(s.time), price: s.price }))
    .sort((a, b) => a.hour - b.hour);
  const bands: Array<{ price: number; start: number; end: number }> = [];
  for (const s of sorted) {
    const last = bands[bands.length - 1];
    if (last && last.price === s.price && s.hour === last.end + 1) {
      last.end = s.hour;
    } else {
      bands.push({ price: s.price, start: s.hour, end: s.hour });
    }
  }
  return bands.map((b) => ({
    price: b.price,
    label: `${fmtHour(b.start)} – ${fmtHour((b.end + 1) % 24)}`,
  }));
}
