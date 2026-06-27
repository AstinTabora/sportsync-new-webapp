import { createContext, useContext, useMemo, useState, type ReactNode } from "react";
import type { SportType } from "../data/types";

// Onboarding filters chosen in the welcome sheet, consumed by Recommendations.

interface OnboardingState {
  sport: SportType | null;
  date: string;
  time: string | null;
  shownThisSession: boolean;
  apply: (v: { sport: SportType | null; date: string; time: string | null }) => void;
  markShown: () => void;
}

const OnboardingContext = createContext<OnboardingState | null>(null);

export function OnboardingProvider({ children }: { children: ReactNode }) {
  const [sport, setSport] = useState<SportType | null>(null);
  const [date, setDate] = useState<string>(new Date().toISOString().slice(0, 10));
  const [time, setTime] = useState<string | null>(null);
  const [shownThisSession, setShown] = useState(false);

  const value = useMemo<OnboardingState>(
    () => ({
      sport,
      date,
      time,
      shownThisSession,
      apply: (v) => {
        setSport(v.sport);
        setDate(v.date);
        setTime(v.time);
      },
      markShown: () => setShown(true),
    }),
    [sport, date, time, shownThisSession]
  );

  return (
    <OnboardingContext.Provider value={value}>{children}</OnboardingContext.Provider>
  );
}

export function useOnboarding(): OnboardingState {
  const ctx = useContext(OnboardingContext);
  if (!ctx) throw new Error("useOnboarding must be used within OnboardingProvider");
  return ctx;
}
