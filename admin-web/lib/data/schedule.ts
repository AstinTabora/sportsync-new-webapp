import { z } from "zod";

export const DAYS = [
  "monday",
  "tuesday",
  "wednesday",
  "thursday",
  "friday",
  "saturday",
  "sunday",
] as const;
export type DayOfWeek = (typeof DAYS)[number];

export const WEEKDAYS: DayOfWeek[] = [
  "monday",
  "tuesday",
  "wednesday",
  "thursday",
  "friday",
];
export const WEEKEND: DayOfWeek[] = ["saturday", "sunday"];

export const slotSchema = z.object({
  time: z.string().regex(/^\d{2}:\d{2}$/, "Time must be HH:mm"),
  durationMins: z.coerce.number().int().min(15).max(240),
  price: z.coerce.number().min(0),
  courtNumbers: z.array(z.string()),
});

export type ScheduleSlot = z.infer<typeof slotSchema>;

export interface ScheduleDay {
  active: boolean;
  slots: ScheduleSlot[];
}

/**
 * Returns null if no overlaps; otherwise returns a pair of conflicting slot
 * times. Slots are intervals [time, time+durationMins).
 */
export function findOverlap(slots: ScheduleSlot[]): [string, string] | null {
  const intervals = slots
    .map((s) => {
      const [h, m] = s.time.split(":").map(Number);
      const start = h * 60 + m;
      return { start, end: start + s.durationMins, time: s.time };
    })
    .sort((a, b) => a.start - b.start);
  for (let i = 1; i < intervals.length; i++) {
    if (intervals[i].start < intervals[i - 1].end) {
      return [intervals[i - 1].time, intervals[i].time];
    }
  }
  return null;
}

export function defaultSlots(price: number): ScheduleSlot[] {
  const out: ScheduleSlot[] = [];
  for (let h = 6; h < 22; h++) {
    out.push({
      time: `${String(h).padStart(2, "0")}:00`,
      durationMins: 60,
      price,
      courtNumbers: [],
    });
  }
  return out;
}
