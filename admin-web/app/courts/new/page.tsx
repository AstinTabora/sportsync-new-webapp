"use client";

import { useRouter } from "next/navigation";
import {
  doc,
  setDoc,
  collection,
  serverTimestamp,
  writeBatch,
} from "firebase/firestore";
import { db } from "@/lib/firebase/client";
import { useAuth } from "@/lib/auth/AuthProvider";
import { AppShell } from "@/components/AppShell";
import { CourtForm } from "@/components/CourtForm";
import {
  CourtFormValues,
  amenitiesToArray,
} from "@/lib/data/courts";
import { useMemo } from "react";

const DAYS = [
  "monday",
  "tuesday",
  "wednesday",
  "thursday",
  "friday",
  "saturday",
  "sunday",
];

function defaultSlots(price: number) {
  const out = [];
  for (let h = 6; h < 22; h++) {
    out.push({
      time: `${String(h).padStart(2, "0")}:00`,
      durationMins: 60,
      price,
      courtNumbers: [] as string[],
    });
  }
  return out;
}

export default function NewCourtPage() {
  const router = useRouter();
  const { user } = useAuth();

  // Reserve a doc ref up front so the image upload path can use the courtId.
  const courtRef = useMemo(() => doc(collection(db, "courts")), []);

  if (!user) return null;

  async function onSubmit(values: CourtFormValues) {
    const batch = writeBatch(db);
    batch.set(courtRef, {
      ownerId: user!.uid,
      name: values.name,
      type: values.type,
      location: values.location,
      price: values.price,
      rating: values.rating,
      numberOfCourts: values.numberOfCourts,
      amenities: amenitiesToArray(values.amenities),
      image: values.image ?? "",
      images: values.images ?? [],
      description: values.description ?? "",
      phone: values.phone ?? "",
      email: values.email ?? "",
      mapUrl: values.mapUrl ?? "",
      published: values.published,
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    });

    // Seed a default Mon–Sun schedule using the court's base price.
    const slots = defaultSlots(values.price);
    for (const day of DAYS) {
      const sRef = doc(collection(courtRef, "schedule"), day);
      batch.set(sRef, {
        active: true,
        slots,
        updatedAt: serverTimestamp(),
        updatedBy: user!.uid,
      });
    }

    await batch.commit();
    router.replace(`/courts/${courtRef.id}/schedule`);
  }

  return (
    <AppShell>
      <div className="mb-6">
        <h1 className="text-2xl font-bold text-slate-900">New court</h1>
        <p className="text-sm text-slate-500">
          We&apos;ll seed a default 6am–10pm schedule you can customize next.
        </p>
      </div>
      <CourtForm
        ownerId={user.uid}
        courtId={courtRef.id}
        submitLabel="Create court"
        onSubmit={onSubmit}
      />
    </AppShell>
  );
}
