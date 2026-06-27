import { useState } from "react";
import Modal from "../ui/Modal";
import Button from "../ui/Button";
import { useAuth } from "../../state/AuthContext";

interface Props {
  open: boolean;
  onClose: () => void;
}

// Sign in / create account — mock (no validation beyond required fields).
export default function AuthSheet({ open, onClose }: Props) {
  const auth = useAuth();
  const [mode, setMode] = useState<"signin" | "signup">("signin");
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");

  function submit() {
    if (!email || !password) return;
    if (mode === "signin") auth.signIn(email);
    else auth.signUp(name || "New Member", email);
    onClose();
  }

  function provider(p: "google" | "apple") {
    auth.signInWithProvider(p);
    onClose();
  }

  return (
    <Modal open={open} onClose={onClose} maxWidth="max-w-md">
      <div className="pt-1">
        <h2 className="t-heading">
          {mode === "signin" ? "WELCOME BACK" : "JOIN SPORTSYNC"}
        </h2>
        <p className="t-body-bold mt-1 text-slate-400">
          {mode === "signin"
            ? "Sign in to manage your bookings."
            : "Create an account to save your courts."}
        </p>

        {/* Tabs */}
        <div className="mt-5 flex rounded-md bg-slate-50 p-1">
          {(["signin", "signup"] as const).map((m) => (
            <button
              key={m}
              onClick={() => setMode(m)}
              className={`flex-1 rounded-[8px] py-2 text-[10px] font-black uppercase tracking-wider transition ${
                mode === m ? "bg-white text-primary shadow-subtle" : "text-slate-400"
              }`}
            >
              {m === "signin" ? "Sign In" : "Sign Up"}
            </button>
          ))}
        </div>

        <div className="mt-4 space-y-3">
          {mode === "signup" && (
            <Field label="Full name" value={name} onChange={setName} placeholder="Juan dela Cruz" />
          )}
          <Field label="Email" value={email} onChange={setEmail} placeholder="you@example.com" type="email" />
          <Field label="Password" value={password} onChange={setPassword} placeholder="••••••••" type="password" />
        </div>

        <Button full className="mt-5" onClick={submit}>
          {mode === "signin" ? "Sign In" : "Create Account"}
        </Button>

        <div className="my-4 flex items-center gap-3">
          <div className="h-px flex-1 bg-slate-100" />
          <span className="t-micro">or continue with</span>
          <div className="h-px flex-1 bg-slate-100" />
        </div>

        <div className="grid grid-cols-2 gap-3">
          <button
            onClick={() => provider("google")}
            className="rounded-md border border-slate-200 py-3 text-[11px] font-extrabold text-slate-600 transition hover:bg-slate-50"
          >
            Google
          </button>
          <button
            onClick={() => provider("apple")}
            className="rounded-md border border-slate-200 py-3 text-[11px] font-extrabold text-slate-600 transition hover:bg-slate-50"
          >
            Apple
          </button>
        </div>
      </div>
    </Modal>
  );
}

function Field({
  label,
  value,
  onChange,
  placeholder,
  type = "text",
}: {
  label: string;
  value: string;
  onChange: (v: string) => void;
  placeholder?: string;
  type?: string;
}) {
  return (
    <label className="block">
      <span className="t-micro text-slate-500">{label}</span>
      <input
        type={type}
        value={value}
        placeholder={placeholder}
        onChange={(e) => onChange(e.target.value)}
        className="mt-1.5 w-full rounded-md border border-slate-200 bg-slate-50 px-3 py-3 text-[14px] font-semibold text-slate-700 outline-none transition focus:border-primary/40 focus:bg-white"
      />
    </label>
  );
}
