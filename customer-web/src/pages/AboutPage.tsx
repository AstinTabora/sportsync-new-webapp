import { useNavigate } from "react-router-dom";
import Logo from "../components/ui/Logo";
import { ArrowLeft } from "../components/ui/Icon";

export default function AboutPage() {
  const navigate = useNavigate();

  return (
    <div className="mx-auto max-w-xl px-4 pb-12 pt-20 md:px-6 md:pt-8">
      <button onClick={() => navigate("/profile")} className="flex items-center gap-1.5 text-slate-400">
        <ArrowLeft size={14} />
        <span className="text-[10px] font-black uppercase tracking-wider">Profile</span>
      </button>

      <h1 className="t-heading mt-3">ABOUT SPORTSYNC</h1>

      <div className="mt-5 flex flex-col items-center rounded-3xl border border-slate-100 bg-white p-8 text-center shadow-subtle">
        <Logo size={64} />
        <span className="t-wordmark mt-3 text-[20px]">SPORTSYNC</span>
        <p className="t-body mt-3 max-w-sm">
          Book premium Badminton, Pickleball, and Basketball courts across Davao City
          in a few clicks. Plan less, play more.
        </p>
        <span className="t-micro mt-4">Version 1.0 · Davao</span>
      </div>

      <div className="mt-4 space-y-2">
        {["Terms of Service", "Privacy Policy", "Contact Us", "Rate the App"].map((item) => (
          <div
            key={item}
            className="flex items-center justify-between rounded-2xl border border-slate-100 bg-white px-4 py-3.5"
          >
            <span className="t-pill">{item}</span>
            <span className="text-slate-300">›</span>
          </div>
        ))}
      </div>

      <p className="mt-6 text-center text-[10px] font-semibold text-slate-400">
        Made with ♥ in Davao City, Philippines
      </p>
    </div>
  );
}
