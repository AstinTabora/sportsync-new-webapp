"use client";

import { useMemo, useState } from "react";
import { formatPHP } from "@/lib/utils";

export interface HeatmapEntry {
  dateStr: string; // YYYY-MM-DD (local)
  amount: number; // ₱ for this paid booking
}

type Metric = "bookings" | "revenue";

const WEEKS = 26; // trailing ~6 months
// Level 0 = empty, 1–4 = increasing brand-green intensity.
const LEVEL_COLORS = ["#EBEDF0", "#D6F0DB", "#7FCE92", "#33A04F", "#1F6633"];
const MONTHS = [
  "Jan", "Feb", "Mar", "Apr", "May", "Jun",
  "Jul", "Aug", "Sep", "Oct", "Nov", "Dec",
];

export function BookingHeatmap({ entries }: { entries: HeatmapEntry[] }) {
  const [metric, setMetric] = useState<Metric>("bookings");

  // Per-day aggregates.
  const byDay = useMemo(() => {
    const m = new Map<string, { count: number; revenue: number }>();
    for (const e of entries) {
      const cur = m.get(e.dateStr) ?? { count: 0, revenue: 0 };
      cur.count += 1;
      cur.revenue += e.amount;
      m.set(e.dateStr, cur);
    }
    return m;
  }, [entries]);

  // Build the trailing grid of weeks (columns) × 7 days (rows, Sun–Sat).
  const { columns, maxValue } = useMemo(() => {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    // Start on the Sunday that begins the window.
    const start = new Date(today);
    start.setDate(start.getDate() - (WEEKS * 7 - 1));
    start.setDate(start.getDate() - start.getDay()); // back up to Sunday

    const cols: Array<Array<{ dateStr: string; value: number; future: boolean } | null>> = [];
    const cursor = new Date(start);
    let max = 0;
    for (let w = 0; w < WEEKS + 1; w++) {
      const col: Array<{ dateStr: string; value: number; future: boolean } | null> = [];
      for (let d = 0; d < 7; d++) {
        const ds = ymd(cursor);
        const future = cursor.getTime() > today.getTime();
        const agg = byDay.get(ds);
        const value =
          !agg ? 0 : metric === "bookings" ? agg.count : agg.revenue;
        if (value > max) max = value;
        col.push({ dateStr: ds, value, future });
        cursor.setDate(cursor.getDate() + 1);
      }
      cols.push(col);
    }
    return { columns: cols, maxValue: max };
  }, [byDay, metric]);

  function level(v: number): number {
    if (v <= 0 || maxValue <= 0) return 0;
    return Math.min(4, Math.ceil((v / maxValue) * 4));
  }

  return (
    <div>
      <div className="mb-3 flex items-center justify-between">
        <div className="inline-flex rounded-md border border-slate-200 p-0.5 text-xs">
          <button
            onClick={() => setMetric("bookings")}
            className={
              "rounded px-3 py-1 font-medium " +
              (metric === "bookings"
                ? "bg-brand-600 text-white"
                : "text-slate-600 hover:bg-slate-50")
            }
          >
            Bookings
          </button>
          <button
            onClick={() => setMetric("revenue")}
            className={
              "rounded px-3 py-1 font-medium " +
              (metric === "revenue"
                ? "bg-brand-600 text-white"
                : "text-slate-600 hover:bg-slate-50")
            }
          >
            Revenue
          </button>
        </div>
      </div>

      <div className="overflow-x-auto">
        {/* Month labels */}
        <div className="mb-1 flex gap-[3px] pl-0">
          {columns.map((col, i) => {
            const first = col[0];
            const showMonth =
              first &&
              (i === 0 ||
                monthOf(first.dateStr) !==
                  monthOf(columns[i - 1][0]?.dateStr ?? ""));
            return (
              <div key={i} className="w-[13px] text-[9px] text-slate-400">
                {showMonth ? MONTHS[Number(first!.dateStr.slice(5, 7)) - 1] : ""}
              </div>
            );
          })}
        </div>

        {/* Grid: rows are days, columns are weeks */}
        <div className="flex gap-[3px]">
          {columns.map((col, ci) => (
            <div key={ci} className="flex flex-col gap-[3px]">
              {col.map((cell, ri) => {
                if (!cell || cell.future) {
                  return <div key={ri} className="h-[13px] w-[13px]" />;
                }
                const lvl = level(cell.value);
                const label =
                  metric === "bookings"
                    ? `${cell.value} booking${cell.value === 1 ? "" : "s"}`
                    : formatPHP(cell.value);
                return (
                  <div
                    key={ri}
                    title={`${cell.dateStr} · ${label}`}
                    className="h-[13px] w-[13px] rounded-[3px]"
                    style={{ backgroundColor: LEVEL_COLORS[lvl] }}
                  />
                );
              })}
            </div>
          ))}
        </div>
      </div>

      {/* Legend */}
      <div className="mt-3 flex items-center justify-end gap-1.5 text-xs text-slate-400">
        <span>Less</span>
        {LEVEL_COLORS.map((c, i) => (
          <span
            key={i}
            className="h-[13px] w-[13px] rounded-[3px]"
            style={{ backgroundColor: c }}
          />
        ))}
        <span>More</span>
      </div>
    </div>
  );
}

function ymd(d: Date): string {
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(
    d.getDate()
  ).padStart(2, "0")}`;
}

function monthOf(dateStr: string): string {
  return dateStr.slice(0, 7);
}
