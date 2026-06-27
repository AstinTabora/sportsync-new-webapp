"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { doc, getDoc, setDoc, serverTimestamp } from "firebase/firestore";
import { db } from "@/lib/firebase/client";
import { useAuth } from "@/lib/auth/AuthProvider";
import { AppShell } from "@/components/AppShell";
import { CourtForm } from "@/components/CourtForm";
import {
  CourtFormValues,
  amenitiesToArray,
} from "@/lib/data/courts";

export default function EditCourtPage({ params }: { params: { id: string } }) {
  const router = useRouter();
  const { user } = useAuth();
  const [initial, setInitial] = useState<
    (Partial<CourtFormValues> & { amenities?: string[] }) | null
  >(null);
  const [notFound, setNotFound] = useState(false);

  useEffect(() => {
    (async () => {
      const snap = await getDoc(doc(db, "courts", params.id));
      if (!snap.exists()) {
        setNotFound(true);
        return;
      }
      const data = snap.data() as Partial<CourtFormValues> & {
        ownerId: string;
        amenities?: string[];
      };
      setInitial(data);
    })();
  }, [params.id]);

  if (!user) return null;
  if (notFound)
    return (
      <AppShell>
        <p className="text-slate-600">Court not found.</p>
      </AppShell>
    );
  if (!initial)
    return (
      <AppShell>
        <p className="text-slate-500 text-sm">Loading…</p>
      </AppShell>
    );

  async function onSubmit(values: CourtFormValues) {
    await setDoc(
      doc(db, "courts", params.id),
      {
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
        updatedAt: serverTimestamp(),
      },
      { merge: true }
    );
    router.replace("/courts");
  }

  return (
    <AppShell>
      <div className="mb-6">
        <h1 className="text-2xl font-bold text-slate-900">Edit court</h1>
      </div>
      <CourtForm
        ownerId={user.uid}
        courtId={params.id}
        initial={initial}
        initialAmenities={initial.amenities}
        submitLabel="Save changes"
        onSubmit={onSubmit}
      />
    </AppShell>
  );
}
