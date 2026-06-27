import type { Booking } from "./types";

// A couple of seeded bookings so My Bookings isn't empty on first load.
// One upcoming, one past.
function isoDay(offsetDays: number): string {
  const d = new Date();
  d.setDate(d.getDate() + offsetDays);
  return d.toISOString().slice(0, 10);
}

export const SEED_BOOKINGS: Booking[] = [
  {
    id: "seed-1",
    refCode: "SS-C1-2048",
    courtId: "c1",
    courtName: "Smash Ville Fitness Center",
    courtType: "badminton",
    location: "31 T.Monteverde St, Poblacion District, Davao City",
    date: isoDay(3),
    slots: [
      { court: "Court 1", time: "18:00" },
      { court: "Court 1", time: "19:00" },
    ],
    totalAmount: 700,
    payment: "qrph",
    status: "paid",
    userName: "Alex Santos",
    userEmail: "alex@example.com",
    userPhone: "+63 917 000 0000",
    createdAt: new Date().toISOString(),
  },
  {
    id: "seed-2",
    refCode: "SS-C3-1180",
    courtId: "c3",
    courtName: "Evergold Recreation Center",
    courtType: "basketball",
    location: "Iñigo St, Obrero, Davao City",
    date: isoDay(-9),
    slots: [{ court: "Court 2", time: "20:00" }],
    totalAmount: 400,
    payment: "cash",
    status: "completed",
    userName: "Alex Santos",
    userEmail: "alex@example.com",
    userPhone: "+63 917 000 0000",
    createdAt: new Date(Date.now() - 9 * 86400000).toISOString(),
  },
];
