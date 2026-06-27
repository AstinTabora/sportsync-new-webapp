import { useNavigate } from "react-router-dom";
import { useAuth } from "../state/AuthContext";
import { ArrowLeft, ChevronRight } from "../components/ui/Icon";

const ROWS = [
  { label: "Change Password", desc: "Update your account password" },
  { label: "Email Verification", desc: "Verified" },
  { label: "Connected Accounts", desc: "Google, Apple" },
  { label: "Privacy", desc: "Manage your data" },
];

export default function AccountPage() {
  const navigate = useNavigate();
  const auth = useAuth();

  return (
    <div className="mx-auto max-w-xl px-4 pb-12 pt-20 md:px-6 md:pt-8">
      <button onClick={() => navigate("/profile")} className="flex items-center gap-1.5 text-slate-400">
        <ArrowLeft size={14} />
        <span className="text-[10px] font-black uppercase tracking-wider">Profile</span>
      </button>

      <h1 className="t-heading mt-3">ACCOUNT & SECURITY</h1>

      <div className="mt-5 overflow-hidden rounded-3xl border border-slate-100 bg-white">
        {ROWS.map((r, i) => (
          <div
            key={r.label}
            className={`flex items-center gap-3 px-4 py-4 ${i !== ROWS.length - 1 ? "border-b border-slate-100" : ""}`}
          >
            <div className="flex-1">
              <p className="t-pill">{r.label}</p>
              <p className="mt-0.5 text-[11px] font-semibold text-slate-400">{r.desc}</p>
            </div>
            <ChevronRight size={16} className="text-slate-300" />
          </div>
        ))}
      </div>

      <button
        onClick={() => {
          auth.signOut();
          navigate("/profile");
        }}
        className="mt-5 w-full rounded-xl border border-red-100 bg-red-50 py-4 text-[10px] font-black uppercase tracking-[2px] text-red-500"
      >
        Delete Account
      </button>
    </div>
  );
}
