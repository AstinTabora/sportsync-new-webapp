import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { useAuth } from "../state/AuthContext";
import type { SkillLevel } from "../data/types";
import Button from "../components/ui/Button";
import { ArrowLeft } from "../components/ui/Icon";

const SPORTS = ["Badminton", "Pickleball", "Basketball"];
const LEVELS: SkillLevel[] = ["beginner", "intermediate", "advanced", "pro"];

export default function EditProfilePage() {
  const auth = useAuth();
  const navigate = useNavigate();

  const [name, setName] = useState(auth.profile.displayName === "Guest" ? "" : auth.profile.displayName);
  const [email, setEmail] = useState(auth.profile.email);
  const [phone, setPhone] = useState(auth.profile.phone);
  const [sport, setSport] = useState(auth.profile.favoriteSport);
  const [level, setLevel] = useState<SkillLevel>(auth.profile.skillLevel);
  const [saved, setSaved] = useState(false);

  function save() {
    auth.updateProfile({
      displayName: name || "Guest",
      email,
      phone,
      favoriteSport: sport,
      skillLevel: level,
    });
    setSaved(true);
    setTimeout(() => navigate("/profile"), 700);
  }

  return (
    <div className="mx-auto max-w-xl px-4 pb-12 pt-20 md:px-6 md:pt-8">
      <button onClick={() => navigate("/profile")} className="flex items-center gap-1.5 text-slate-400">
        <ArrowLeft size={14} />
        <span className="text-[10px] font-black uppercase tracking-wider">Profile</span>
      </button>

      <h1 className="t-heading mt-3">EDIT PROFILE</h1>

      <div className="mt-5 space-y-4 rounded-3xl border border-slate-100 bg-white p-5 shadow-subtle">
        <Field label="Full name" value={name} onChange={setName} placeholder="Juan dela Cruz" />
        <Field label="Email" value={email} onChange={setEmail} placeholder="you@example.com" type="email" />
        <Field label="Phone" value={phone} onChange={setPhone} placeholder="+63 9XX XXX XXXX" type="tel" />

        <div>
          <span className="t-micro text-slate-500">Favorite sport</span>
          <div className="mt-2 flex flex-wrap gap-2">
            {SPORTS.map((s) => (
              <Pill key={s} label={s} active={sport === s} onClick={() => setSport(s)} />
            ))}
          </div>
        </div>

        <div>
          <span className="t-micro text-slate-500">Skill level</span>
          <div className="mt-2 flex flex-wrap gap-2">
            {LEVELS.map((l) => (
              <Pill key={l} label={l} active={level === l} onClick={() => setLevel(l)} />
            ))}
          </div>
        </div>
      </div>

      <Button full className="mt-5" onClick={save}>
        {saved ? "Saved ✓" : "Save Changes"}
      </Button>
    </div>
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

function Pill({ label, active, onClick }: { label: string; active: boolean; onClick: () => void }) {
  return (
    <button
      onClick={onClick}
      className={`rounded-md border px-3.5 py-2 text-[10px] font-black uppercase tracking-wide transition ${
        active ? "border-primary bg-primary text-white" : "border-slate-200 bg-slate-50 text-slate-400"
      }`}
    >
      {label}
    </button>
  );
}
