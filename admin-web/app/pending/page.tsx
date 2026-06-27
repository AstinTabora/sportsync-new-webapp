"use client";

import { useRouter } from "next/navigation";
import { useEffect } from "react";
import { useAuth } from "@/lib/auth/AuthProvider";
import { Button } from "@/components/ui/Button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/Card";

export default function PendingPage() {
  const router = useRouter();
  const { profile, role, signOut, loading, user } = useAuth();

  useEffect(() => {
    if (loading) return;
    if (!user) {
      router.replace("/login");
      return;
    }
    // Approved owners and super admins belong in the app, not here.
    if (profile?.status === "approved" || role === "superAdmin") {
      router.replace("/");
    }
  }, [loading, user, profile, role, router]);

  return (
    <div className="min-h-screen flex items-center justify-center bg-slate-50 px-4">
      <Card className="w-full max-w-md">
        <CardHeader>
          <CardTitle>Account pending approval</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <p className="text-sm text-slate-600">
            Thanks for signing up. We&apos;re reviewing your request — you&apos;ll be
            able to manage your courts once an admin approves your account.
          </p>
          {profile?.status === "suspended" && (
            <div className="text-sm text-red-600 bg-red-50 px-3 py-2 rounded-md">
              Your account is suspended. Contact support for help.
            </div>
          )}
          <Button
            variant="secondary"
            onClick={async () => {
              await signOut();
              router.replace("/login");
            }}
            className="w-full"
          >
            Sign out
          </Button>
        </CardContent>
      </Card>
    </div>
  );
}
