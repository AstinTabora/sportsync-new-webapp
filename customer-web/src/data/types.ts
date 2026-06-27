// Domain types — ported from the Flutter models (lib/core/models/court.dart,
// lib/features/bookings/models/booking.dart, etc.). Backend is stubbed, so these
// are plain client-side shapes.

export type SportType = "badminton" | "pickleball" | "basketball";

export interface Court {
  id: string;
  name: string;
  type: SportType;
  image: string; // public path, e.g. /images/SMASHVILLE.png
  price: number; // pesos per hour
  rating: number;
  location: string;
  amenities: string[];
  description: string;
  phone: string;
  email: string;
  numberOfCourts: number;
  latitude: number;
  longitude: number;
  mapUrl: string; // Google Maps embed iframe src
  published: boolean;
}

export interface BookingSlot {
  court: string; // court number label, e.g. "Court 1"
  time: string; // "08:00"
}

export type PaymentMethod = "gcash" | "card" | "qrph" | "cash";

export type BookingStatus =
  | "pending"
  | "paid"
  | "completed"
  | "cancelled";

export interface Booking {
  id: string;
  refCode: string;
  courtId: string;
  courtName: string;
  courtType: SportType;
  location: string;
  date: string; // ISO yyyy-MM-dd
  slots: BookingSlot[];
  totalAmount: number;
  payment: PaymentMethod;
  status: BookingStatus;
  userName: string;
  userEmail: string;
  userPhone: string;
  createdAt: string; // ISO datetime
}

export type SkillLevel = "beginner" | "intermediate" | "advanced" | "pro";

export interface UserProfile {
  displayName: string;
  email: string;
  phone: string;
  favoriteSport: string;
  skillLevel: SkillLevel;
  memberSince: number; // year
}

// ── Slot-state model used by the booking time grid ────────────────────────
export type SlotState =
  | "available"
  | "selected"
  | "booked"
  | "openplay"
  | "closing"
  | "past";
