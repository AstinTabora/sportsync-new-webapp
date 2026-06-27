"use client";

import { useEffect, useMemo, useState } from "react";
import {
  addDoc,
  collection,
  deleteDoc,
  doc,
  getDoc,
  onSnapshot,
  serverTimestamp,
  Timestamp,
} from "firebase/firestore";
import { Trash2, Calendar as CalendarIcon } from "lucide-react";
import { db } from "@/lib/firebase/client";
import { useAuth } from "@/lib/auth/AuthProvider";
import {
  enumerateDateRange,
  findBookedConflicts,
  type ConflictItem,
} from "@/lib/data/blockouts";
import { AppShell } from "@/components/AppShell";
import { Button } from "@/components/ui/Button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/Card";
import { Input } from "@/components/ui/Input";
import { Label } from "@/components/ui/Label";

interface BlockoutDoc {
  id: string;
  startDate: string;
  endDate: string;
  slots: string[] | "all";
  reason: string;
  createdAt?: Timestamp;
}

export default function BlockoutsPage({ params }: { params: { id: string } }) {
  const courtId = params.id;
  const { user } = useAuth();
  const [courtName, setCourtName] = useState("");
  const [items, setItems] = useState<BlockoutDoc[]>([]);
  const [startDate, setStartDate] = useState(todayStr());
  const [endDate, setEndDate] = useState(todayStr());
  const [scope, setScope] = useState<"all" | "specific">("all");
  const [slotsInput, setSlotsInput] = useState("");
  const [reason, setReason] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [conflicts, setConflicts] = useState<ConflictItem[]>([]);
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    (async () => {
      const snap = await getDoc(doc(db, "courts", courtId));
      if (snap.exists()) setCourtName((snap.data().name as string) ?? "");
    })();
  }, [courtId]);

  useEffect(() => {
    const unsub = onSnapshot(
      collection(db, "courts", courtId, "blockouts"),
      (snap) => {
        const out = snap.docs.map((d) => ({
          id: d.id,
          ...(d.data() as Omit<BlockoutDoc, "id">),
        }));
        out.sort((a, b) => a.startDate.localeCompare(b.startDate));
        setItems(out);
      }
    );
    return () => unsub();
  }, [courtId]);

  async function onCreate(e: React.FormEvent) {
    e.preventDefault();
    setError(null);
    setConflicts([]);
    if (endDate < startDate) {
      setError("End date is before start date.");
      return;
    }
    const slots: string[] | "all" =
      scope === "all"
        ? "all"
        : slotsInput
            .split(",")
            .map((s) => s.trim())
            .filter(Boolean);
    if (slots !== "all" && slots.length === 0) {
      setError("Add at least one slot time, or block the whole day.");
      return;
    }
    setBusy(true);
    try {
      // Refuse to block any slot that already has a paid booking — same rule
      // the old Cloud Function enforced, now checked client-side.
      const dates = enumerateDateRange(startDate, endDate);
      const found = await findBookedConflicts(courtId, dates, slots);
      if (found.length > 0) {
        setConflicts(found);
        setError(`Cannot block: ${found.length} slot(s) already booked.`);
        return;
      }
      await addDoc(collection(db, "courts", courtId, "blockouts"), {
        startDate,
        endDate,
        slots,
        reason,
        createdBy: user?.uid ?? "",
        createdAt: serverTimestamp(),
      });
      setReason("");
      setSlotsInput("");
    } catch (err) {
      setError((err as Error).message);
    } finally {
      setBusy(false);
    }
  }

  async function onDelete(blockoutId: string) {
    if (!confirm("Delete this block-out?")) return;
    await deleteDoc(doc(db, "courts", courtId, "blockouts", blockoutId));
  }

  function blockWeekend() {
    const s = new Date();
    const day = s.getDay();
    const sat = new Date(s);
    sat.setDate(s.getDate() + ((6 - day + 7) % 7));
    const sun = new Date(sat);
    sun.setDate(sat.getDate() + 1);
    setStartDate(formatYmd(sat));
    setEndDate(formatYmd(sun));
    setScope("all");
  }

  const upcoming = useMemo(
    () => items.filter((b) => b.endDate >= todayStr()),
    [items]
  );
  const past = useMemo(
    () => items.filter((b) => b.endDate < todayStr()),
    [items]
  );

  return (
    <AppShell>
      <div className="mb-6">
        <h1 className="text-2xl font-bold text-slate-900">
          Block-outs — {courtName}
        </h1>
        <p className="text-sm text-slate-500">
          Mark dates or specific slots as unavailable. Already-booked slots are protected.
        </p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <Card className="lg:col-span-1">
          <CardHeader>
            <CardTitle>New block-out</CardTitle>
          </CardHeader>
          <CardContent>
            <form onSubmit={onCreate} className="space-y-3">
              <div>
                <Label htmlFor="start">Start date</Label>
                <Input
                  id="start"
                  type="date"
                  value={startDate}
                  onChange={(e) => setStartDate(e.target.value)}
                  required
                />
              </div>
              <div>
                <Label htmlFor="end">End date</Label>
                <Input
                  id="end"
                  type="date"
                  value={endDate}
                  onChange={(e) => setEndDate(e.target.value)}
                  required
                />
              </div>
              <div>
                <Label>Scope</Label>
                <div className="flex items-center gap-4 text-sm">
                  <label className="flex items-center gap-2">
                    <input
                      type="radio"
                      checked={scope === "all"}
                      onChange={() => setScope("all")}
                    />
                    Whole day
                  </label>
                  <label className="flex items-center gap-2">
                    <input
                      type="radio"
                      checked={scope === "specific"}
                      onChange={() => setScope("specific")}
                    />
                    Specific slots
                  </label>
                </div>
              </div>
              {scope === "specific" && (
                <div>
                  <Label htmlFor="slots">Slot times (csv, HH:mm)</Label>
                  <Input
                    id="slots"
                    placeholder="06:00, 07:00, 18:00"
                    value={slotsInput}
                    onChange={(e) => setSlotsInput(e.target.value)}
                  />
                </div>
              )}
              <div>
                <Label htmlFor="reason">Reason (optional)</Label>
                <Input
                  id="reason"
                  value={reason}
                  onChange={(e) => setReason(e.target.value)}
                  placeholder="Maintenance, holiday, private event"
                />
              </div>
              {error && (
                <div className="text-sm text-red-600 bg-red-50 px-3 py-2 rounded-md">
                  {error}
                </div>
              )}
              {conflicts.length > 0 && (
                <div className="text-xs bg-amber-50 text-amber-800 px-3 py-2 rounded-md">
                  Conflicts:
                  <ul className="list-disc list-inside mt-1">
                    {conflicts.slice(0, 6).map((c, i) => (
                      <li key={i}>
                        {c.date} @ {c.time} (ref {c.refCode})
                      </li>
                    ))}
                    {conflicts.length > 6 && (
                      <li>+{conflicts.length - 6} more</li>
                    )}
                  </ul>
                </div>
              )}
              <Button type="submit" disabled={busy} className="w-full">
                {busy ? "Creating…" : "Create block-out"}
              </Button>
            </form>
            <div className="mt-4 pt-4 border-t border-slate-200">
              <p className="text-xs text-slate-500 mb-2">Quick actions:</p>
              <Button variant="secondary" size="sm" onClick={blockWeekend}>
                <CalendarIcon size={14} /> Set this weekend
              </Button>
            </div>
          </CardContent>
        </Card>

        <Card className="lg:col-span-2">
          <CardHeader>
            <CardTitle>Active &amp; upcoming</CardTitle>
          </CardHeader>
          <CardContent>
            {upcoming.length === 0 ? (
              <p className="text-sm text-slate-500">None.</p>
            ) : (
              <table className="w-full text-sm">
                <thead className="text-xs text-slate-500 uppercase">
                  <tr>
                    <th className="text-left py-2">Range</th>
                    <th className="text-left py-2">Scope</th>
                    <th className="text-left py-2">Reason</th>
                    <th className="text-right py-2"></th>
                  </tr>
                </thead>
                <tbody>
                  {upcoming.map((b) => (
                    <tr key={b.id} className="border-t border-slate-100">
                      <td className="py-2 text-slate-900">
                        {b.startDate}
                        {b.startDate !== b.endDate && ` → ${b.endDate}`}
                      </td>
                      <td className="py-2 text-slate-600">
                        {b.slots === "all" ? "Whole day" : b.slots.join(", ")}
                      </td>
                      <td className="py-2 text-slate-600">{b.reason || "—"}</td>
                      <td className="py-2 text-right">
                        <Button
                          size="sm"
                          variant="ghost"
                          onClick={() => onDelete(b.id)}
                          title="Delete"
                        >
                          <Trash2 size={14} className="text-red-600" />
                        </Button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}

            {past.length > 0 && (
              <details className="mt-6">
                <summary className="text-sm text-slate-500 cursor-pointer">
                  Past block-outs ({past.length})
                </summary>
                <table className="w-full text-sm mt-2">
                  <tbody>
                    {past.map((b) => (
                      <tr key={b.id} className="border-t border-slate-100">
                        <td className="py-2 text-slate-500">
                          {b.startDate}
                          {b.startDate !== b.endDate && ` → ${b.endDate}`}
                        </td>
                        <td className="py-2 text-slate-500">
                          {b.slots === "all" ? "Whole day" : b.slots.join(", ")}
                        </td>
                        <td className="py-2 text-slate-500">{b.reason || "—"}</td>
                        <td className="py-2 text-right">
                          <Button
                            size="sm"
                            variant="ghost"
                            onClick={() => onDelete(b.id)}
                          >
                            <Trash2 size={14} className="text-red-600" />
                          </Button>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </details>
            )}
          </CardContent>
        </Card>
      </div>
    </AppShell>
  );
}

function todayStr(): string {
  return formatYmd(new Date());
}

function formatYmd(d: Date): string {
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, "0");
  const day = String(d.getDate()).padStart(2, "0");
  return `${y}-${m}-${day}`;
}
