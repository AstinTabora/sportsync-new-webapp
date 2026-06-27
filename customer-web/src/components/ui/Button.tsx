import type { ButtonHTMLAttributes, ReactNode } from "react";

type Variant = "primary" | "outline" | "ghost";

interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: Variant;
  full?: boolean;
  children: ReactNode;
}

const styles: Record<Variant, string> = {
  primary:
    "bg-primary text-white shadow-cta hover:bg-primary-dark active:scale-[.98]",
  outline:
    "bg-white text-primary border border-slate-300 hover:border-primary/40 active:scale-[.98]",
  ghost: "bg-slate-50 text-slate-500 border border-slate-100 hover:bg-slate-100",
};

export default function Button({
  variant = "primary",
  full,
  children,
  className = "",
  ...props
}: ButtonProps) {
  return (
    <button
      {...props}
      className={`inline-flex items-center justify-center gap-2 rounded-md px-5 py-3
        text-[11px] font-extrabold uppercase tracking-[1.4px] transition
        disabled:opacity-50 disabled:pointer-events-none
        ${full ? "w-full" : ""} ${styles[variant]} ${className}`}
    >
      {children}
    </button>
  );
}
