import { createContext, useContext, useMemo, useState, type ReactNode } from "react";
import type { UserProfile } from "../data/types";

// Mock auth. No Firebase — "signing in" just sets a fake profile in memory.
// Signed-out users browse as guests (mirrors the app's anonymous-auth model).

interface AuthState {
  signedIn: boolean;
  profile: UserProfile;
  signIn: (email: string, name?: string) => void;
  signUp: (name: string, email: string) => void;
  signInWithProvider: (provider: "google" | "apple") => void;
  signOut: () => void;
  updateProfile: (patch: Partial<UserProfile>) => void;
}

const GUEST_PROFILE: UserProfile = {
  displayName: "Guest",
  email: "",
  phone: "",
  favoriteSport: "Badminton",
  skillLevel: "intermediate",
  memberSince: new Date().getFullYear(),
};

const AuthContext = createContext<AuthState | null>(null);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [signedIn, setSignedIn] = useState(false);
  const [profile, setProfile] = useState<UserProfile>(GUEST_PROFILE);

  const value = useMemo<AuthState>(
    () => ({
      signedIn,
      profile,
      signIn: (email, name) => {
        setSignedIn(true);
        setProfile((p) => ({
          ...p,
          email,
          displayName: name || deriveName(email),
        }));
      },
      signUp: (name, email) => {
        setSignedIn(true);
        setProfile((p) => ({ ...p, displayName: name, email }));
      },
      signInWithProvider: (provider) => {
        setSignedIn(true);
        setProfile((p) => ({
          ...p,
          displayName: provider === "google" ? "Alex Santos" : "Apple User",
          email: provider === "google" ? "alex@gmail.com" : "user@icloud.com",
        }));
      },
      signOut: () => {
        setSignedIn(false);
        setProfile(GUEST_PROFILE);
      },
      updateProfile: (patch) => setProfile((p) => ({ ...p, ...patch })),
    }),
    [signedIn, profile]
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

function deriveName(email: string): string {
  const handle = email.split("@")[0] || "Player";
  return handle.charAt(0).toUpperCase() + handle.slice(1);
}

export function useAuth(): AuthState {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error("useAuth must be used within AuthProvider");
  return ctx;
}
