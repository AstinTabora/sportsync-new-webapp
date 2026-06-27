"use client";

import Link from "next/link";
import { useEffect, useState } from "react";
import {
  collection,
  query,
  where,
  onSnapshot,
  doc,
  deleteDoc,
} from "firebase/firestore";
import { Plus, Pencil, Calendar, Ban, Trash } from "lucide-react";
import { db } from "@/lib/firebase/client";
import { useAuth } from "@/lib/auth/AuthProvider";
import { AppShell } from "@/components/AppShell";
import { Button } from "@/components/ui/Button";
import { Card, CardContent } from "@/components/ui/Card";
import { formatPHP } from "@/lib/utils";

interface CourtRow {
  id: string;
  name: string;
  type: string;
  location: string;
  price: number;
  numberOfCourts: number;
  published: boolean;
}

export default function CourtsListPage() {
  const { user } = useAuth();
  const [rows, setRows] = useState<CourtRow[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!user) return;
    const q = query(collection(db, "courts"), where("ownerId", "==", user.uid));
    const unsub = onSnapshot(q, (snap) => {
      const items = snap.docs.map((d) => {
        const data = d.data() as Omit<CourtRow, "id">;
        return { id: d.id, ...data };
      });
      items.sort((a, b) => a.name.localeCompare(b.name));
      setRows(items);
      setLoading(false);
    });
    return () => unsub();
  }, [user]);

  async function onDelete(id: string, name: string) {
    if (!confirm(`Delete "${name}"? This can't be undone.`)) return;
    await deleteDoc(doc(db, "courts", id));
  }

  return (
    <AppShell>
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-bold text-slate-900">Courts</h1>
          <p className="text-sm text-slate-500">
            {rows.length} court{rows.length === 1 ? "" : "s"}
          </p>
        </div>
        <Link href="/courts/new">
          <Button>
            <Plus size={16} /> New court
          </Button>
        </Link>
      </div>

      {loading ? (
        <p className="text-sm text-slate-500">Loading…</p>
      ) : rows.length === 0 ? (
        <Card>
          <CardContent className="py-12 text-center text-slate-600">
            No courts yet. Click <strong>New court</strong> to add your first one.
          </CardContent>
        </Card>
      ) : (
        <Card>
          <table className="w-full text-sm">
            <thead className="bg-slate-50 border-b border-slate-200">
              <tr className="text-left text-slate-500">
                <th className="px-4 py-3 font-medium">Name</th>
                <th className="px-4 py-3 font-medium">Sport</th>
                <th className="px-4 py-3 font-medium">Location</th>
                <th className="px-4 py-3 font-medium">Price</th>
                <th className="px-4 py-3 font-medium">Status</th>
                <th className="px-4 py-3 font-medium text-right">Actions</th>
              </tr>
            </thead>
            <tbody>
              {rows.map((r) => (
                <tr key={r.id} className="border-b border-slate-100 last:border-0">
                  <td className="px-4 py-3 font-medium text-slate-900">{r.name}</td>
                  <td className="px-4 py-3 capitalize">{r.type}</td>
                  <td className="px-4 py-3 text-slate-600">{r.location}</td>
                  <td className="px-4 py-3">{formatPHP(r.price)}</td>
                  <td className="px-4 py-3">
                    <span
                      className={
                        r.published
                          ? "inline-flex px-2 py-0.5 rounded-full bg-green-100 text-green-700 text-xs font-medium"
                          : "inline-flex px-2 py-0.5 rounded-full bg-slate-100 text-slate-600 text-xs font-medium"
                      }
                    >
                      {r.published ? "Published" : "Draft"}
                    </span>
                  </td>
                  <td className="px-4 py-3 text-right space-x-1">
                    <Link href={`/courts/${r.id}/edit`}>
                      <Button size="sm" variant="ghost" title="Edit">
                        <Pencil size={14} />
                      </Button>
                    </Link>
                    <Link href={`/courts/${r.id}/schedule`}>
                      <Button size="sm" variant="ghost" title="Schedule">
                        <Calendar size={14} />
                      </Button>
                    </Link>
                    <Link href={`/courts/${r.id}/blockouts`}>
                      <Button size="sm" variant="ghost" title="Block-outs">
                        <Ban size={14} />
                      </Button>
                    </Link>
                    <Button
                      size="sm"
                      variant="ghost"
                      title="Delete"
                      onClick={() => onDelete(r.id, r.name)}
                    >
                      <Trash size={14} className="text-red-600" />
                    </Button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </Card>
      )}
    </AppShell>
  );
}
