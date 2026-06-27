"use client";

import Link from "next/link";
import { useEffect, useMemo, useState } from "react";
import {
  collection,
  query,
  where,
  onSnapshot,
  Timestamp,
} from "firebase/firestore";
import { db } from "@/lib/firebase/client";
import { useAuth } from "@/lib/auth/AuthProvider";
import { useOwnerCourtIds } from "@/lib/data/ownerCourts";
import { AppShell } from "@/components/AppShell";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/Card";
import { Select } from "@/components/ui/Select";
import { BookingHeatmap, type HeatmapEntry } from "@/components/BookingHeatmap";
import { formatPHP } from "@/lib/utils";

interface BookingLite {
  refCode: string;
  courtId: string;
  status: string;
  totalAmount: number;
  date: Timestamp;
  courtName: string;
  userName: string;
}

export default function DashboardPage() {
  const { profile } = useAuth();
  const { courtIds, courts } = useOwnerCourtIds();
  const [bookings, setBookings] = useState<BookingLite[]>([]);
  const [courtFilter, setCourtFilter] = useState<"all" | string>("all");

  useEffect(() => {
    if (!courtIds.length) {
      setBookings([]);
      return;
    }
    const q = query(
      collection(db, "bookings"),
      where("courtId", "in", courtIds.slice(0, 30))
    );
    const unsub = onSnapshot(q, (snap) => {
      const out: BookingLite[] = snap.docs.map((d) => {
        const data = d.data() as BookingLite;
        return { ...data, refCode: d.id };
      });
      setBookings(out);
    });
    return () => unsub();
  }, [courtIds]);

  // Scope everything to the selected court.
  const scoped = useMemo(
    () =>
      courtFilter === "all"
        ? bookings
        : bookings.filter((b) => b.courtId === courtFilter),
    [bookings, courtFilter]
  );

  const paid = scoped.filter((b) => b.status === "paid");
  const pending = scoped.filter((b) => b.status === "pendingPayment");
  const now = Date.now();
  const todayStart = new Date();
  todayStart.setHours(0, 0, 0, 0);
  const todayPaid = paid.filter((b) => b.date.toMillis() >= todayStart.getTime());
  const upcomingPaid = paid.filter((b) => b.date.toMillis() >= now);
  const revenue = paid.reduce((sum, b) => sum + (b.totalAmount ?? 0), 0);

  const heatmapEntries = useMemo<HeatmapEntry[]>(
    () =>
      paid.map((b) => ({
        dateStr: ymd(b.date.toDate()),
        amount: b.totalAmount ?? 0,
      })),
    [paid]
  );

  return (
    <AppShell>
      <div className="mb-6 flex flex-wrap items-end justify-between gap-3">
        <div>
          <h1 className="text-2xl font-bold text-slate-900">Dashboard</h1>
          <p className="text-sm text-slate-500">
            Welcome back, {profile?.displayName}.
          </p>
        </div>
        {courts.length > 0 && (
          <div>
            <label className="mb-1 block text-xs font-medium text-slate-500">
              Court
            </label>
            <Select
              value={courtFilter}
              onChange={(e) => setCourtFilter(e.target.value)}
              className="max-w-[260px]"
            >
              <option value="all">All courts</option>
              {courts.map((c) => (
                <option key={c.id} value={c.id}>
                  {c.name}
                </option>
              ))}
            </Select>
          </div>
        )}
      </div>

      {courtIds.length === 0 ? (
        <Card>
          <CardContent className="py-12 text-center">
            <p className="mb-4 text-slate-600">
              You don&apos;t have any courts yet.
            </p>
            <Link
              href="/courts/new"
              className="font-medium text-brand-700 hover:underline"
            >
              Create your first court →
            </Link>
          </CardContent>
        </Card>
      ) : (
        <div className="grid grid-cols-1 gap-4 md:grid-cols-3">
          <StatCard label="Paid bookings (today)" value={todayPaid.length} />
          <StatCard label="Upcoming paid" value={upcomingPaid.length} />
          <StatCard label="Pending payment" value={pending.length} />

          <Card className="md:col-span-3">
            <CardHeader>
              <CardTitle>Revenue (all time, paid)</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="text-3xl font-bold text-brand-700">
                {formatPHP(revenue)}
              </div>
              <p className="mt-1 text-sm text-slate-500">
                Across {paid.length} paid booking{paid.length === 1 ? "" : "s"}
                {courtFilter !== "all" ? " for this court" : ""}.
              </p>
            </CardContent>
          </Card>

          <Card className="md:col-span-3">
            <CardHeader>
              <CardTitle>Activity heatmap</CardTitle>
            </CardHeader>
            <CardContent>
              <BookingHeatmap entries={heatmapEntries} />
            </CardContent>
          </Card>
        </div>
      )}
    </AppShell>
  );
}

function StatCard({ label, value }: { label: string; value: number }) {
  return (
    <Card>
      <CardContent className="py-5">
        <div className="text-sm text-slate-500">{label}</div>
        <div className="mt-1 text-3xl font-bold text-slate-900">{value}</div>
      </CardContent>
    </Card>
  );
}

function ymd(d: Date): string {
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(
    d.getDate()
  ).padStart(2, "0")}`;
}
