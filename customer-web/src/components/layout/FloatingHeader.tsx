import { useNavigate } from "react-router-dom";
import Logo from "../ui/Logo";
import { UserIcon } from "../ui/Icon";

// Mobile-only glassmorphic floating header pill (matches FloatingHeader.dart).
export default function FloatingHeader() {
  const navigate = useNavigate();
  return (
    <div className="md:hidden fixed inset-x-0 top-0 z-30 px-3 pt-3"
      style={{ paddingTop: "max(0.75rem, env(safe-area-inset-top))" }}>
      <div className="mx-auto flex h-12 max-w-content items-center justify-between rounded-2xl border border-slate-100/80 bg-white/85 px-3 shadow-subtle backdrop-blur-xl">
        <div className="flex items-center gap-2">
          <Logo size={28} />
          <span className="t-wordmark">SPORTSYNC</span>
        </div>
        <button
          onClick={() => navigate("/profile")}
          className="grid h-7 w-7 place-items-center rounded-md bg-primary text-white"
          aria-label="Profile"
        >
          <UserIcon size={14} />
        </button>
      </div>
    </div>
  );
}
