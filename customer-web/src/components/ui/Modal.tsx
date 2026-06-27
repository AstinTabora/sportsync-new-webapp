import { useEffect, type ReactNode } from "react";
import { CloseIcon } from "./Icon";

// Responsive modal: bottom sheet on mobile, centered dialog on desktop.

interface ModalProps {
  open: boolean;
  onClose: () => void;
  children: ReactNode;
  title?: string;
  maxWidth?: string; // tailwind max-w-* class for desktop
}

export default function Modal({
  open,
  onClose,
  children,
  title,
  maxWidth = "max-w-md",
}: ModalProps) {
  useEffect(() => {
    if (!open) return;
    const onKey = (e: KeyboardEvent) => e.key === "Escape" && onClose();
    document.addEventListener("keydown", onKey);
    document.body.style.overflow = "hidden";
    return () => {
      document.removeEventListener("keydown", onKey);
      document.body.style.overflow = "";
    };
  }, [open, onClose]);

  if (!open) return null;

  return (
    <div
      className="fixed inset-0 z-50 flex items-end justify-center sm:items-center"
      role="dialog"
      aria-modal="true"
    >
      <div
        className="absolute inset-0 bg-black/50 animate-[fadeIn_.15s_ease-out]"
        onClick={onClose}
      />
      <div
        className={`relative w-full ${maxWidth} bg-white rounded-t-3xl sm:rounded-3xl shadow-hero
          max-h-[92vh] overflow-y-auto animate-[slideUp_.22s_ease-out] sm:animate-[fadeIn_.18s_ease-out]`}
      >
        {/* Mobile drag handle */}
        <div className="sm:hidden flex justify-center pt-3">
          <div className="h-1 w-10 rounded-full bg-slate-200" />
        </div>
        {title && (
          <div className="flex items-center justify-between px-6 pt-4 pb-2">
            <h2 className="t-page-title">{title}</h2>
            <button
              onClick={onClose}
              className="grid h-8 w-8 place-items-center rounded-md text-slate-400 hover:bg-slate-50"
              aria-label="Close"
            >
              <CloseIcon size={18} />
            </button>
          </div>
        )}
        <div className="px-6 pb-6 pt-2">{children}</div>
      </div>

      <style>{`
        @keyframes slideUp { from { transform: translateY(100%); } to { transform: translateY(0); } }
        @keyframes fadeIn { from { opacity: 0; } to { opacity: 1; } }
      `}</style>
    </div>
  );
}
