"use client";

import { useEffect, useMemo, useState } from "react";
import Link from "next/link";
import {
  collection,
  onSnapshot,
  query,
  Timestamp,
  where,
} from "firebase/firestore";
import {
  flexRender,
  getCoreRowModel,
  getFilteredRowModel,
  getSortedRowModel,
  SortingState,
  useReactTable,
  type ColumnDef,
} from "@tanstack/react-table";
import { Download } from "lucide-react";
import { db } from "@/lib/firebase/client";
import { useOwnerCourtIds } from "@/lib/data/ownerCourts";
import { AppShell } from "@/components/AppShell";
import { BookingGrid } from "@/components/BookingGrid";
import { Button } from "@/components/ui/Button";
import { Card } from "@/components/ui/Card";
import { Input } from "@/components/ui/Input";
import { Select } from "@/components/ui/Select";
import { formatPHP } from "@/lib/utils";

interface BookingRow {
  refCode: string;
  courtId: string;
  courtName: string;
  date: Timestamp;
  dateStr: string;
  slots: Array<{ court: string; time: string }>;
  slotsText: string;
  status: "paid" | "pendingPayment" | "paymentFailed" | string;
  totalAmount: number;
  userName: string;
  userEmail: string;
  userPhone: string;
}

export default function BookingsPage() {
  const { courtIds, courts } = useOwnerCourtIds();
  const [rows, setRows] = useState<BookingRow[]>([]);
  const [statusFilter, setStatusFilter] = useState<"all" | string>("all");
  const [courtFilter, setCourtFilter] = useState<"all" | string>("all");
  const [search, setSearch] = useState("");
  const [sorting, setSorting] = useState<SortingState>([
    { id: "date", desc: true },
  ]);

  useEffect(() => {
    if (!courtIds.length) {
      setRows([]);
      return;
    }
    const q = query(
      collection(db, "bookings"),
      where("courtId", "in", courtIds.slice(0, 30))
    );
    const unsub = onSnapshot(q, (snap) => {
      const out: BookingRow[] = snap.docs.map((d) => {
        const data = d.data();
        const date = data.date as Timestamp;
        const slots = (data.slots ?? []) as Array<{
          court: string;
          time: string;
        }>;
        return {
          refCode: d.id,
          courtId: data.courtId,
          courtName: data.courtName ?? "",
          date,
          dateStr: date?.toDate().toISOString().slice(0, 10) ?? "",
          slots,
          slotsText: slots.map((s) => `${s.court}@${s.time}`).join(", "),
          status: data.status,
          totalAmount: data.totalAmount ?? 0,
          userName: data.userName ?? "",
          userEmail: data.userEmail ?? "",
          userPhone: data.userPhone ?? "",
        };
      });
      setRows(out);
    });
    return () => unsub();
  }, [courtIds]);

  const courtOptions = useMemo(() => {
    const map = new Map<string, string>();
    rows.forEach((r) => map.set(r.courtId, r.courtName));
    return Array.from(map.entries());
  }, [rows]);

  const filtered = useMemo(() => {
    const q = search.trim().toLowerCase();
    return rows.filter((r) => {
      if (statusFilter !== "all" && r.status !== statusFilter) return false;
      if (courtFilter !== "all" && r.courtId !== courtFilter) return false;
      if (
        q &&
        ![r.userName, r.userEmail, r.refCode]
          .filter(Boolean)
          .some((v) => v.toLowerCase().includes(q))
      )
        return false;
      return true;
    });
  }, [rows, statusFilter, courtFilter, search]);

  const columns = useMemo<ColumnDef<BookingRow>[]>(
    () => [
      {
        accessorKey: "date",
        header: "Date",
        sortingFn: (a, b) =>
          a.original.date.toMillis() - b.original.date.toMillis(),
        cell: (info) => <span>{info.row.original.dateStr}</span>,
      },
      { accessorKey: "courtName", header: "Court" },
      {
        accessorKey: "slotsText",
        header: "Slots",
        cell: (info) => (
          <span className="text-xs text-slate-600">{info.getValue<string>()}</span>
        ),
      },
      {
        accessorKey: "userName",
        header: "Customer",
        cell: (info) => (
          <div>
            <div className="text-slate-900">{info.row.original.userName}</div>
            <div className="text-xs text-slate-500">
              {info.row.original.userEmail}
            </div>
          </div>
        ),
      },
      {
        accessorKey: "totalAmount",
        header: "Amount",
        cell: (info) => formatPHP(info.getValue<number>()),
      },
      {
        accessorKey: "status",
        header: "Status",
        cell: (info) => {
          const s = info.getValue<string>();
          const cls =
            s === "paid"
              ? "bg-green-100 text-green-700"
              : s === "pendingPayment"
              ? "bg-amber-100 text-amber-800"
              : "bg-red-100 text-red-700";
          return (
            <span
              className={`inline-flex px-2 py-0.5 rounded-full text-xs font-medium ${cls}`}
            >
              {s}
            </span>
          );
        },
      },
      {
        id: "actions",
        header: "",
        cell: (info) => (
          <Link
            href={`/bookings/${info.row.original.refCode}`}
            className="text-brand-700 text-sm font-medium hover:underline"
          >
            View
          </Link>
        ),
      },
    ],
    []
  );

  const table = useReactTable({
    data: filtered,
    columns,
    state: { sorting },
    onSortingChange: setSorting,
    getCoreRowModel: getCoreRowModel(),
    getSortedRowModel: getSortedRowModel(),
    getFilteredRowModel: getFilteredRowModel(),
  });

  function exportCsv() {
    const headers = [
      "refCode",
      "date",
      "court",
      "slots",
      "customerName",
      "customerEmail",
      "customerPhone",
      "amount",
      "status",
    ];
    const lines = [headers.join(",")];
    for (const r of filtered) {
      lines.push(
        [
          r.refCode,
          r.dateStr,
          escape(r.courtName),
          escape(r.slotsText),
          escape(r.userName),
          escape(r.userEmail),
          escape(r.userPhone),
          r.totalAmount,
          r.status,
        ].join(",")
      );
    }
    const blob = new Blob([lines.join("\n")], { type: "text/csv" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = `bookings-${new Date().toISOString().slice(0, 10)}.csv`;
    a.click();
    URL.revokeObjectURL(url);
  }

  return (
    <AppShell>
      <div className="flex items-center justify-between mb-6 flex-wrap gap-3">
        <div>
          <h1 className="text-2xl font-bold text-slate-900">Bookings</h1>
          <p className="text-sm text-slate-500">
            {filtered.length} of {rows.length} booking
            {rows.length === 1 ? "" : "s"}
          </p>
        </div>
        <Button variant="secondary" onClick={exportCsv} disabled={filtered.length === 0}>
          <Download size={14} /> Export CSV
        </Button>
      </div>

      <div className="flex gap-3 mb-4 flex-wrap">
        <Input
          placeholder="Search name / email / ref code"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          className="max-w-xs"
        />
        <Select
          value={statusFilter}
          onChange={(e) => setStatusFilter(e.target.value)}
          className="max-w-[200px]"
        >
          <option value="all">All statuses</option>
          <option value="paid">Paid</option>
          <option value="pendingPayment">Pending</option>
          <option value="paymentFailed">Failed</option>
        </Select>
        <Select
          value={courtFilter}
          onChange={(e) => setCourtFilter(e.target.value)}
          className="max-w-[240px]"
        >
          <option value="all">All courts</option>
          {courtOptions.map(([id, name]) => (
            <option key={id} value={id}>
              {name}
            </option>
          ))}
        </Select>
      </div>

      <Card>
        <table className="w-full text-sm">
          <thead className="bg-slate-50 border-b border-slate-200">
            {table.getHeaderGroups().map((hg) => (
              <tr key={hg.id} className="text-left text-slate-500">
                {hg.headers.map((h) => (
                  <th
                    key={h.id}
                    className="px-4 py-3 font-medium cursor-pointer select-none"
                    onClick={h.column.getToggleSortingHandler()}
                  >
                    {flexRender(h.column.columnDef.header, h.getContext())}
                    {h.column.getIsSorted() === "asc" && " ↑"}
                    {h.column.getIsSorted() === "desc" && " ↓"}
                  </th>
                ))}
              </tr>
            ))}
          </thead>
          <tbody>
            {table.getRowModel().rows.length === 0 ? (
              <tr>
                <td
                  colSpan={columns.length}
                  className="px-4 py-12 text-center text-slate-500"
                >
                  No bookings match these filters.
                </td>
              </tr>
            ) : (
              table.getRowModel().rows.map((row) => (
                <tr
                  key={row.id}
                  className="border-b border-slate-100 last:border-0"
                >
                  {row.getVisibleCells().map((cell) => (
                    <td key={cell.id} className="px-4 py-3 align-top">
                      {flexRender(
                        cell.column.columnDef.cell,
                        cell.getContext()
                      )}
                    </td>
                  ))}
                </tr>
              ))
            )}
          </tbody>
        </table>
      </Card>

      <div className="mt-10 mb-4">
        <h2 className="text-xl font-bold text-slate-900">Availability</h2>
        <p className="text-sm text-slate-500">
          Day view of every court — hover a booked slot for the customer&apos;s
          details, click to open the booking.
        </p>
      </div>
      <BookingGrid courts={courts} bookings={rows} />
    </AppShell>
  );
}

function escape(v: string): string {
  if (/[",\n]/.test(v)) return `"${v.replace(/"/g, '""')}"`;
  return v;
}
