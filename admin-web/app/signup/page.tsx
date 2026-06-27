"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import {
  createUserWithEmailAndPassword,
  signInWithEmailAndPassword,
  updateProfile,
  type UserCredential,
} from "firebase/auth";
import { doc, serverTimestamp, setDoc } from "firebase/firestore";
import { auth, db } from "@/lib/firebase/client";
import { Button } from "@/components/ui/Button";
import { Input } from "@/components/ui/Input";
import { Label } from "@/components/ui/Label";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/Card";

export default function SignupPage() {
  const router = useRouter();
  const [displayName, setDisplayName] = useState("");
  const [businessName, setBusinessName] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError(null);
    if (password.length < 8) {
      setError("Password must be at least 8 characters.");
      return;
    }
    setBusy(true);
    try {
      // Create the account; if it already exists (e.g. a previous attempt
      // created the Auth user but not the profile doc), sign in instead to
      // recover it. Either way we end up signed in and write the profile.
      let cred: UserCredential;
      try {
        cred = await createUserWithEmailAndPassword(auth, email, password);
      } catch (err) {
        if ((err as { code?: string }).code === "auth/email-already-in-use") {
          cred = await signInWithEmailAndPassword(auth, email, password);
        } else {
          throw err;
        }
      }

      if (displayName && cred.user.displayName !== displayName) {
        await updateProfile(cred.user, { displayName });
      }

      // Write the owner profile directly. Security rules permit a user to
      // create their own doc only as `status: 'pending'` — approval happens
      // out-of-band (Firebase Console / a super admin).
      await setDoc(
        doc(db, "ownerProfiles", cred.user.uid),
        {
          email,
          displayName,
          businessName,
          status: "pending",
          role: "courtOwner",
          courtIds: [],
          requestedAt: serverTimestamp(),
        },
        { merge: true }
      );

      router.replace("/pending");
    } catch (err) {
      setError((err as Error).message);
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-slate-50 px-4 py-10">
      <Card className="w-full max-w-md">
        <CardHeader>
          <CardTitle>Request owner access</CardTitle>
          <p className="text-sm text-slate-500 mt-1">
            We&apos;ll review your request and approve your account shortly.
          </p>
        </CardHeader>
        <CardContent>
          <form onSubmit={onSubmit} className="space-y-4">
            <div>
              <Label htmlFor="displayName">Your name</Label>
              <Input
                id="displayName"
                value={displayName}
                onChange={(e) => setDisplayName(e.target.value)}
                required
              />
            </div>
            <div>
              <Label htmlFor="businessName">Facility / business name</Label>
              <Input
                id="businessName"
                value={businessName}
                onChange={(e) => setBusinessName(e.target.value)}
                required
              />
            </div>
            <div>
              <Label htmlFor="email">Email</Label>
              <Input
                id="email"
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
                autoComplete="email"
              />
            </div>
            <div>
              <Label htmlFor="password">Password (min 8 chars)</Label>
              <Input
                id="password"
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
                autoComplete="new-password"
                minLength={8}
              />
            </div>
            {error && (
              <div className="text-sm text-red-600 bg-red-50 px-3 py-2 rounded-md">
                {error}
              </div>
            )}
            <Button type="submit" disabled={busy} className="w-full">
              {busy ? "Submitting…" : "Request access"}
            </Button>
          </form>
          <p className="text-sm text-slate-500 text-center mt-6">
            Already have an account?{" "}
            <Link className="text-brand-700 font-medium hover:underline" href="/login">
              Sign in
            </Link>
          </p>
        </CardContent>
      </Card>
    </div>
  );
}
