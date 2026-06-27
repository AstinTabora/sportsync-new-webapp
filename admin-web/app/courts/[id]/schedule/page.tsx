"use client";

import { useEffect, useState } from "react";
import {
  doc,
  collection,
  getDoc,
  getDocs,
  writeBatch,
  serverTimestamp,
} from "firebase/firestore";
import { Plus, Trash2, Copy } from "lucide-react";
import { db } from "@/lib/firebase/client";
import { useAuth } from "@/lib/auth/AuthProvider";
import { AppShell } from "@/components/AppShell";
import { Button } from "@/components/ui/Button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/Card";
import { Input } from "@/components/ui/Input";
import { Label } from "@/components/ui/Label";
import { Select } from "@/components/ui/Select";
import {
  DAYS,
  DayOfWeek,
  ScheduleDay,
  ScheduleSlot,
  WEEKDAYS,
  WEEKEND,
  defaultSlots,
  findOverlap,
} from "@/lib/data/schedule";

type DaysMap = Record<DayOfWeek, ScheduleDay>;

function blank(): DaysMap {
  const out = {} as DaysMap;
  for (const d of DAYS) out[d] = { active: true, slots: [] };
  return out;
}

export default function SchedulePage({ params }: { params: { id: string } }) {
  const { user } = useAuth();
  const [courtName, setCourtName] = useState("");
  const [basePrice, setBasePrice] = useState(300);
  const [days, setDays] = useState<DaysMap>(blank());
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);

  useEffect(() => {
    (async () => {
      const courtSnap = await getDoc(doc(db, "courts", params.id));
      if (courtSnap.exists()) {
        const c = courtSnap.data() as { name?: string; price?: number };
        setCourtName(c.name ?? "");
        setBasePrice(c.price ?? 300);
      }
      const schedSnap = await getDocs(
        collection(db, "courts", params.id, "schedule")
      );
      const map = blank();
      schedSnap.docs.forEach((d) => {
        const data = d.data() as ScheduleDay;
        if (DAYS.includes(d.id as DayOfWeek)) {
          map[d.id as DayOfWeek] = {
            active: data.active ?? true,
            slots: data.slots ?? [],
          };
        }
      });
      setDays(map);
      setLoading(false);
    })();
  }, [params.id]);

  function patchDay(day: DayOfWeek, patch: Partial<ScheduleDay>) {
    setDays((prev) => ({ ...prev, [day]: { ...prev[day], ...patch } }));
    setSuccess(null);
  }

  function patchSlot(day: DayOfWeek, idx: number, patch: Partial<ScheduleSlot>) {
    setDays((prev) => {
      const slots = [...prev[day].slots];
      slots[idx] = { ...slots[idx], ...patch };
      return { ...prev, [day]: { ...prev[day], slots } };
    });
    setSuccess(null);
  }

  function addSlot(day: DayOfWeek) {
    const last = days[day].slots[days[day].slots.length - 1];
    const nextTime = last ? nextHourFromSlot(last) : "06:00";
    patchDay(day, {
      slots: [
        ...days[day].slots,
        {
          time: nextTime,
          durationMins: 60,
          price: basePrice,
          courtNumbers: [],
        },
      ],
    });
  }

  function removeSlot(day: DayOfWeek, idx: number) {
    const slots = days[day].slots.filter((_, i) => i !== idx);
    patchDay(day, { slots });
  }

  function copyDay(from: DayOfWeek, to: DayOfWeek[]) {
    setDays((prev) => {
      const next = { ...prev };
      for (const d of to) {
        if (d === from) continue;
        next[d] = { ...next[d], slots: prev[from].slots.map((s) => ({ ...s })) };
      }
      return next;
    });
    setSuccess(null);
  }

  function resetWithDefaults() {
    if (!confirm("Replace all days with the default 6am–10pm hourly schedule?"))
      return;
    const slots = defaultSlots(basePrice);
    const next = blank();
    for (const d of DAYS) next[d] = { active: true, slots: [...slots] };
    setDays(next);
    setSuccess(null);
  }

  async function save() {
    setError(null);
    setSuccess(null);
    for (const d of DAYS) {
      const overlap = findOverlap(days[d].slots);
      if (overlap) {
        setError(
          `Overlapping slots on ${d}: ${overlap[0]} and ${overlap[1]} collide.`
        );
        return;
      }
    }
    setSaving(true);
    try {
      const batch = writeBatch(db);
      for (const d of DAYS) {
        const ref = doc(db, "courts", params.id, "schedule", d);
        batch.set(ref, {
          active: days[d].active,
          slots: days[d].slots,
          updatedAt: serverTimestamp(),
          updatedBy: user!.uid,
        });
      }
      await batch.commit();
      setSuccess("Schedule saved.");
    } catch (err) {
      setError((err as Error).message);
    } finally {
      setSaving(false);
    }
  }

  if (loading)
    return (
      <AppShell>
        <p className="text-slate-500 text-sm">Loading schedule…</p>
      </AppShell>
    );

  return (
    <AppShell>
      <div className="flex items-start justify-between mb-6 gap-4 flex-wrap">
        <div>
          <h1 className="text-2xl font-bold text-slate-900">
            Schedule — {courtName}
          </h1>
          <p className="text-sm text-slate-500">
            Configure weekly slots. Bookings use these times and prices.
          </p>
        </div>
        <div className="flex gap-2">
          <Button variant="secondary" onClick={resetWithDefaults}>
            Reset to 6am–10pm
          </Button>
          <Button onClick={save} disabled={saving}>
            {saving ? "Saving…" : "Save schedule"}
          </Button>
        </div>
      </div>

      {error && (
        <div className="text-sm text-red-600 bg-red-50 px-3 py-2 rounded-md mb-4">
          {error}
        </div>
      )}
      {success && (
        <div className="text-sm text-green-700 bg-green-50 px-3 py-2 rounded-md mb-4">
          {success}
        </div>
      )}

      <div className="space-y-4">
        {DAYS.map((d) => (
          <Card key={d}>
            <CardHeader className="flex items-center justify-between flex-wrap gap-2">
              <div className="flex items-center gap-3">
                <input
                  type="checkbox"
                  className="h-4 w-4"
                  checked={days[d].active}
                  onChange={(e) => patchDay(d, { active: e.target.checked })}
                />
                <CardTitle className="capitalize">{d}</CardTitle>
                <span className="text-xs text-slate-500">
                  {days[d].slots.length} slot
                  {days[d].slots.length === 1 ? "" : "s"}
                </span>
              </div>
              <div className="flex items-center gap-2">
                {d === "monday" && (
                  <Button
                    size="sm"
                    variant="ghost"
                    onClick={() => copyDay(d, WEEKDAYS)}
                    title="Copy to all weekdays"
                  >
                    <Copy size={14} /> Apply to weekdays
                  </Button>
                )}
                {d === "saturday" && (
                  <Button
                    size="sm"
                    variant="ghost"
                    onClick={() => copyDay(d, WEEKEND)}
                    title="Copy to both weekend days"
                  >
                    <Copy size={14} /> Apply to weekend
                  </Button>
                )}
                <Button
                  size="sm"
                  variant="ghost"
                  onClick={() => copyDay(d, [...DAYS])}
                  title="Copy to all 7 days"
                >
                  <Copy size={14} /> Apply to all
                </Button>
                <Button size="sm" onClick={() => addSlot(d)}>
                  <Plus size={14} /> Add slot
                </Button>
              </div>
            </CardHeader>
            <CardContent>
              {days[d].slots.length === 0 ? (
                <p className="text-sm text-slate-400 italic">No slots.</p>
              ) : (
                <div className="space-y-2">
                  {days[d].slots.map((slot, idx) => (
                    <div
                      key={idx}
                      className="grid grid-cols-12 gap-3 items-end"
                    >
                      <div className="col-span-3">
                        {idx === 0 && <Label>Start time</Label>}
                        <Input
                          type="time"
                          value={slot.time}
                          onChange={(e) =>
                            patchSlot(d, idx, { time: e.target.value })
                          }
                        />
                      </div>
                      <div className="col-span-3">
                        {idx === 0 && <Label>Duration (mins)</Label>}
                        <Select
                          value={slot.durationMins}
                          onChange={(e) =>
                            patchSlot(d, idx, {
                              durationMins: Number(e.target.value),
                            })
                          }
                        >
                          <option value={30}>30</option>
                          <option value={45}>45</option>
                          <option value={60}>60</option>
                          <option value={90}>90</option>
                          <option value={120}>120</option>
                        </Select>
                      </div>
                      <div className="col-span-3">
                        {idx === 0 && <Label>Price (₱)</Label>}
                        <Input
                          type="number"
                          step="1"
                          min={0}
                          value={slot.price}
                          onChange={(e) =>
                            patchSlot(d, idx, {
                              price: Number(e.target.value),
                            })
                          }
                        />
                      </div>
                      <div className="col-span-2">
                        {idx === 0 && <Label>Courts (csv)</Label>}
                        <Input
                          placeholder="Court 1, Court 2"
                          value={slot.courtNumbers.join(", ")}
                          onChange={(e) =>
                            patchSlot(d, idx, {
                              courtNumbers: e.target.value
                                .split(",")
                                .map((s) => s.trim())
                                .filter(Boolean),
                            })
                          }
                        />
                      </div>
                      <div className="col-span-1 flex justify-end">
                        <Button
                          size="sm"
                          variant="ghost"
                          onClick={() => removeSlot(d, idx)}
                          title="Remove slot"
                        >
                          <Trash2 size={14} className="text-red-600" />
                        </Button>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </CardContent>
          </Card>
        ))}
      </div>
    </AppShell>
  );
}

function nextHourFromSlot(s: ScheduleSlot): string {
  const [h, m] = s.time.split(":").map(Number);
  const totalMins = h * 60 + m + s.durationMins;
  const nh = Math.floor(totalMins / 60) % 24;
  const nm = totalMins % 60;
  return `${String(nh).padStart(2, "0")}:${String(nm).padStart(2, "0")}`;
}
