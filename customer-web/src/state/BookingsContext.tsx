import { createContext, useContext, useMemo, useState, type ReactNode } from "react";
import type { Booking } from "../data/types";
import { SEED_BOOKINGS } from "../data/mockBookings";

// In-memory bookings list. Checkout pushes a new booking here so it shows up
// instantly under My Bookings (no backend).

interface BookingsState {
  bookings: Booking[];
  addBooking: (b: Booking) => void;
  upcoming: Booking[];
  past: Booking[];
  stats: { total: number; hours: number; rating: number };
}

const BookingsContext = createContext<BookingsState | null>(null);

export function BookingsProvider({ children }: { children: ReactNode }) {
  const [bookings, setBookings] = useState<Booking[]>(SEED_BOOKINGS);

  const value = useMemo<BookingsState>(() => {
    const today = new Date().toISOString().slice(0, 10);
    const sorted = [...bookings].sort((a, b) => b.date.localeCompare(a.date));
    const upcoming = sorted
      .filter((b) => b.date >= today && b.status !== "cancelled")
      .sort((a, b) => a.date.localeCompare(b.date));
    const past = sorted.filter((b) => b.date < today || b.status === "completed");
    const totalHours = bookings.reduce((sum, b) => sum + b.slots.length, 0);
    return {
      bookings,
      addBooking: (b) => setBookings((prev) => [b, ...prev]),
      upcoming,
      past,
      stats: { total: bookings.length, hours: totalHours, rating: 4.9 },
    };
  }, [bookings]);

  return <BookingsContext.Provider value={value}>{children}</BookingsContext.Provider>;
}

export function useBookings(): BookingsState {
  const ctx = useContext(BookingsContext);
  if (!ctx) throw new Error("useBookings must be used within BookingsProvider");
  return ctx;
}
