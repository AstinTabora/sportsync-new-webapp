"use client";

import { useEffect, useMemo, useState } from "react";
import { collection, onSnapshot, query, where } from "firebase/firestore";
import { db } from "@/lib/firebase/client";
import { useAuth } from "@/lib/auth/AuthProvider";

export interface OwnerCourtLite {
  id: string;
  name: string;
  numberOfCourts: number;
  price: number;
}

/**
 * Streams the courts owned by the signed-in user. Replaces the old
 * `ownerProfiles.courtIds` denormalization (which was kept in sync by a Cloud
 * Function) — we derive the owner's court IDs straight from the courts
 * collection instead, so no backend trigger is required.
 */
export function useOwnerCourtIds(): {
  courtIds: string[];
  courts: OwnerCourtLite[];
  loading: boolean;
} {
  const { user } = useAuth();
  const [courts, setCourts] = useState<OwnerCourtLite[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!user) {
      setCourts([]);
      setLoading(false);
      return;
    }
    setLoading(true);
    const q = query(collection(db, "courts"), where("ownerId", "==", user.uid));
    const unsub = onSnapshot(q, (snap) => {
      const items = snap.docs.map((d) => {
        const data = d.data();
        return {
          id: d.id,
          name: (data.name as string) ?? d.id,
          numberOfCourts: (data.numberOfCourts as number) ?? 1,
          price: (data.price as number) ?? 0,
        };
      });
      items.sort((a, b) => a.name.localeCompare(b.name));
      setCourts(items);
      setLoading(false);
    });
    return () => unsub();
  }, [user]);

  // Memoize so `courtIds` keeps a stable identity between renders — otherwise
  // a fresh array each render makes `useEffect([courtIds])` in consumers fire
  // every render (→ setState → re-render → infinite loop).
  const courtIds = useMemo(() => courts.map((c) => c.id), [courts]);

  return { courtIds, courts, loading };
}
