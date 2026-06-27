"use client";

import {
  createContext,
  useContext,
  useEffect,
  useState,
  ReactNode,
} from "react";
import {
  onAuthStateChanged,
  signOut as fbSignOut,
  User,
} from "firebase/auth";
import { doc, onSnapshot } from "firebase/firestore";
import { auth, db } from "../firebase/client";

export type OwnerStatus = "pending" | "approved" | "suspended";
export type OwnerRole = "courtOwner" | "superAdmin";

export interface OwnerProfile {
  email: string;
  displayName: string;
  businessName: string;
  status: OwnerStatus;
  role?: OwnerRole;
  courtIds?: string[];
}

interface AuthContextValue {
  user: User | null;
  profile: OwnerProfile | null;
  role: OwnerRole | null;
  loading: boolean;
  signOut: () => Promise<void>;
}

const AuthContext = createContext<AuthContextValue>({
  user: null,
  profile: null,
  role: null,
  loading: true,
  signOut: async () => {},
});

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [profile, setProfile] = useState<OwnerProfile | null>(null);
  // Two-stage loading: auth must resolve, AND (when signed in) the profile doc
  // must come back from Firestore before consumers decide anything. Otherwise a
  // full page load briefly looks like "signed in, no profile" and gating code
  // wrongly redirects to /pending before the profile arrives.
  const [authLoading, setAuthLoading] = useState(true);
  const [profileLoading, setProfileLoading] = useState(true);

  useEffect(() => {
    const unsub = onAuthStateChanged(auth, (u) => {
      setUser(u);
      if (!u) {
        setProfile(null);
        setProfileLoading(false);
        setAuthLoading(false);
        return;
      }
      // Signed in — the profile is not known yet; keep loading until the
      // snapshot below resolves. Routing/gating is done entirely on the
      // client (AppShell + the pages), so there's no auth cookie to set.
      setProfileLoading(true);
      setAuthLoading(false);
    });
    return () => unsub();
  }, []);

  useEffect(() => {
    if (!user) return;
    const ref = doc(db, "ownerProfiles", user.uid);
    const unsub = onSnapshot(
      ref,
      (snap) => {
        setProfile(snap.exists() ? (snap.data() as OwnerProfile) : null);
        setProfileLoading(false);
      },
      () => setProfileLoading(false)
    );
    return () => unsub();
  }, [user]);

  return (
    <AuthContext.Provider
      value={{
        user,
        profile,
        // Role is a field on the profile doc, not a token claim.
        role: profile?.role ?? null,
        loading: authLoading || profileLoading,
        signOut: async () => {
          await fbSignOut(auth);
        },
      }}
    >
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  return useContext(AuthContext);
}
