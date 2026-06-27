"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { doc, getDoc, Timestamp } from "firebase/firestore";
import { db } from "@/lib/firebase/client";
import { AppShell } from "@/components/AppShell";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/Card";
import { formatPHP } from "@/lib/utils";

interface BookingDoc {
  courtId: string;
  courtName: string;
  date: Timestamp;
  slots: Array<{ court: string; time: string }>;
  status: string;
  totalAmount: number;
  amountCents: number;
  userName: string;
  userEmail: string;
  userPhone: string;
  payment: string;
  paymongoCheckoutSessionId?: string;
  paymongoPaymentId?: string;
  refCode: string;
  createdAt?: Timestamp;
  paidAt?: Timestamp;
}

export default function BookingDetailPage({
  params,
}: {
  params: { refCode: string };
}) {
  const [booking, setBooking] = useState<BookingDoc | null>(null);
  const [notFound, setNotFound] = useState(false);

  useEffect(() => {
    (async () => {
      const snap = await getDoc(doc(db, "bookings", params.refCode));
      if (!snap.exists()) setNotFound(true);
      else setBooking(snap.data() as BookingDoc);
    })();
  }, [params.refCode]);

  if (notFound)
    return (
      <AppShell>
        <p className="text-slate-600">Booking not found.</p>
      </AppShell>
    );
  if (!booking)
    return (
      <AppShell>
        <p className="text-sm text-slate-500">Loading…</p>
      </AppShell>
    );

  return (
    <AppShell>
      <div className="mb-6">
        <Link href="/bookings" className="text-sm text-brand-700 hover:underline">
          ← Back to bookings
        </Link>
        <h1 className="text-2xl font-bold text-slate-900 mt-2">
          Booking {params.refCode}
        </h1>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
        <Card>
          <CardHeader>
            <CardTitle>Status</CardTitle>
          </CardHeader>
          <CardContent>
            <span
              className={`inline-flex px-2 py-0.5 rounded-full text-xs font-medium ${
                booking.status === "paid"
                  ? "bg-green-100 text-green-700"
                  : booking.status === "pendingPayment"
                  ? "bg-amber-100 text-amber-800"
                  : "bg-red-100 text-red-700"
              }`}
            >
              {booking.status}
            </span>
            {booking.paidAt && (
              <p className="text-xs text-slate-500 mt-2">
                Paid {booking.paidAt.toDate().toLocaleString()}
              </p>
            )}
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Booking</CardTitle>
          </CardHeader>
          <CardContent className="space-y-2 text-sm">
            <Row label="Court" value={booking.courtName} />
            <Row label="Date" value={booking.date.toDate().toDateString()} />
            <Row
              label="Slots"
              value={booking.slots
                .map((s) => `${s.court} @ ${s.time}`)
                .join(", ")}
            />
            <Row label="Total" value={formatPHP(booking.totalAmount)} />
            <Row label="Payment method" value={booking.payment} />
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Customer</CardTitle>
          </CardHeader>
          <CardContent className="space-y-2 text-sm">
            <Row label="Name" value={booking.userName} />
            <Row label="Email" value={booking.userEmail} />
            <Row label="Phone" value={booking.userPhone || "—"} />
          </CardContent>
        </Card>

        <Card className="lg:col-span-3">
          <CardHeader>
            <CardTitle>PayMongo</CardTitle>
          </CardHeader>
          <CardContent className="space-y-2 text-sm">
            <Row
              label="Checkout session"
              value={booking.paymongoCheckoutSessionId ?? "—"}
            />
            <Row
              label="Payment id"
              value={booking.paymongoPaymentId ?? "—"}
            />
          </CardContent>
        </Card>
      </div>
    </AppShell>
  );
}

function Row({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex justify-between gap-4">
      <span className="text-slate-500">{label}</span>
      <span className="text-slate-900 text-right">{value}</span>
    </div>
  );
}
