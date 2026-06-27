import {
  createContext,
  useCallback,
  useContext,
  useMemo,
  useState,
  type ReactNode,
} from "react";
import type { BookingSlot, Court, PaymentMethod } from "../data/types";

// Holds the in-progress booking selection across the multi-step flow.

export type BookingStep = "calendar" | "payment" | "confirmation";

interface UserDetails {
  name: string;
  email: string;
  phone: string;
}

interface BookingFlowState {
  court: Court | null;
  setCourt: (c: Court | null) => void;
  date: string; // yyyy-MM-dd
  setDate: (d: string) => void;
  slots: BookingSlot[];
  toggleSlot: (slot: BookingSlot) => void;
  clearSlots: () => void;
  isSelected: (slot: BookingSlot) => boolean;
  total: number;
  step: BookingStep;
  setStep: (s: BookingStep) => void;
  payment: PaymentMethod | null;
  setPayment: (p: PaymentMethod | null) => void;
  refCode: string;
  details: UserDetails;
  setDetails: (d: UserDetails) => void;
  reset: (court: Court) => void;
}

const BookingFlowContext = createContext<BookingFlowState | null>(null);

function genRefCode(courtId: string): string {
  const n = Math.floor(1000 + Math.random() * 9000);
  return `SS-${courtId.toUpperCase()}-${n}`;
}

function todayIso(): string {
  return new Date().toISOString().slice(0, 10);
}

function slotKey(s: BookingSlot): string {
  return `${s.court}__${s.time}`;
}

export function BookingFlowProvider({ children }: { children: ReactNode }) {
  const [court, setCourt] = useState<Court | null>(null);
  const [date, setDate] = useState<string>(todayIso());
  const [slots, setSlots] = useState<BookingSlot[]>([]);
  const [step, setStep] = useState<BookingStep>("calendar");
  const [payment, setPayment] = useState<PaymentMethod | null>(null);
  const [refCode, setRefCode] = useState<string>("");
  const [details, setDetails] = useState<UserDetails>({
    name: "",
    email: "",
    phone: "",
  });

  const toggleSlot = useCallback((slot: BookingSlot) => {
    setSlots((prev) => {
      const exists = prev.some((s) => slotKey(s) === slotKey(slot));
      return exists
        ? prev.filter((s) => slotKey(s) !== slotKey(slot))
        : [...prev, slot];
    });
  }, []);

  const reset = useCallback((c: Court) => {
    setCourt(c);
    setDate(todayIso());
    setSlots([]);
    setStep("calendar");
    setPayment(null);
    setRefCode(genRefCode(c.id));
    setDetails({ name: "", email: "", phone: "" });
  }, []);

  const total = useMemo(
    () => (court ? slots.length * court.price : 0),
    [court, slots]
  );

  const value = useMemo<BookingFlowState>(
    () => ({
      court,
      setCourt,
      date,
      setDate,
      slots,
      toggleSlot,
      clearSlots: () => setSlots([]),
      isSelected: (slot) => slots.some((s) => slotKey(s) === slotKey(slot)),
      total,
      step,
      setStep,
      payment,
      setPayment,
      refCode,
      details,
      setDetails,
      reset,
    }),
    [court, date, slots, toggleSlot, total, step, payment, refCode, details, reset]
  );

  return (
    <BookingFlowContext.Provider value={value}>
      {children}
    </BookingFlowContext.Provider>
  );
}

export function useBookingFlow(): BookingFlowState {
  const ctx = useContext(BookingFlowContext);
  if (!ctx) throw new Error("useBookingFlow must be used within BookingFlowProvider");
  return ctx;
}
