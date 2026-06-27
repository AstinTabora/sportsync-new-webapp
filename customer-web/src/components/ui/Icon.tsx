import type { SVGProps } from "react";
import type { SportType } from "../../data/types";

// Lightweight inline-SVG icon set (Material-style) so we avoid an icon dependency.
// Stroke icons inherit `currentColor`; fill icons use `currentColor` too.

type IconProps = SVGProps<SVGSVGElement> & { size?: number };

function base(size: number | undefined, props: SVGProps<SVGSVGElement>) {
  return {
    width: size ?? 20,
    height: size ?? 20,
    viewBox: "0 0 24 24",
    fill: "none",
    stroke: "currentColor",
    strokeWidth: 2,
    strokeLinecap: "round" as const,
    strokeLinejoin: "round" as const,
    ...props,
  };
}

export const HomeIcon = ({ size, ...p }: IconProps) => (
  <svg {...base(size, p)}>
    <path d="M3 11l9-8 9 8" />
    <path d="M5 10v10h14V10" />
  </svg>
);

export const CalendarIcon = ({ size, ...p }: IconProps) => (
  <svg {...base(size, p)}>
    <rect x="3" y="4" width="18" height="17" rx="2" />
    <path d="M3 9h18M8 2v4M16 2v4" />
  </svg>
);

export const UserIcon = ({ size, ...p }: IconProps) => (
  <svg {...base(size, p)}>
    <circle cx="12" cy="8" r="4" />
    <path d="M4 21c0-4 4-6 8-6s8 2 8 6" />
  </svg>
);

export const StarIcon = ({ size, ...p }: IconProps) => (
  <svg {...base(size, p)} fill="currentColor" stroke="none">
    <path d="M12 2l2.9 6.3 6.9.6-5.2 4.6 1.6 6.8L12 17.3 5.8 20.9l1.6-6.8L2.2 8.9l6.9-.6z" />
  </svg>
);

export const PinIcon = ({ size, ...p }: IconProps) => (
  <svg {...base(size, p)}>
    <path d="M12 22s7-7.6 7-13a7 7 0 1 0-14 0c0 5.4 7 13 7 13z" />
    <circle cx="12" cy="9" r="2.5" />
  </svg>
);

export const SearchIcon = ({ size, ...p }: IconProps) => (
  <svg {...base(size, p)}>
    <circle cx="11" cy="11" r="7" />
    <path d="M21 21l-4.3-4.3" />
  </svg>
);

export const SlidersIcon = ({ size, ...p }: IconProps) => (
  <svg {...base(size, p)}>
    <path d="M4 7h12M4 17h8" />
    <circle cx="18" cy="7" r="2" />
    <circle cx="14" cy="17" r="2" />
  </svg>
);

export const ChevronRight = ({ size, ...p }: IconProps) => (
  <svg {...base(size, p)}>
    <path d="M9 6l6 6-6 6" />
  </svg>
);

export const ChevronLeft = ({ size, ...p }: IconProps) => (
  <svg {...base(size, p)}>
    <path d="M15 6l-6 6 6 6" />
  </svg>
);

export const ArrowLeft = ({ size, ...p }: IconProps) => (
  <svg {...base(size, p)}>
    <path d="M19 12H5M11 18l-6-6 6-6" />
  </svg>
);

export const CloseIcon = ({ size, ...p }: IconProps) => (
  <svg {...base(size, p)}>
    <path d="M18 6L6 18M6 6l12 12" />
  </svg>
);

export const CheckIcon = ({ size, ...p }: IconProps) => (
  <svg {...base(size, p)}>
    <path d="M20 6L9 17l-5-5" />
  </svg>
);

export const QrIcon = ({ size, ...p }: IconProps) => (
  <svg {...base(size, p)}>
    <rect x="3" y="3" width="7" height="7" rx="1" />
    <rect x="14" y="3" width="7" height="7" rx="1" />
    <rect x="3" y="14" width="7" height="7" rx="1" />
    <path d="M14 14h3v3h-3zM21 14v7M17 21h4" />
  </svg>
);

export const CashIcon = ({ size, ...p }: IconProps) => (
  <svg {...base(size, p)}>
    <rect x="2" y="6" width="20" height="12" rx="2" />
    <circle cx="12" cy="12" r="2.5" />
  </svg>
);

export const CardIcon = ({ size, ...p }: IconProps) => (
  <svg {...base(size, p)}>
    <rect x="2" y="5" width="20" height="14" rx="2" />
    <path d="M2 10h20" />
  </svg>
);

export const EditIcon = ({ size, ...p }: IconProps) => (
  <svg {...base(size, p)}>
    <path d="M12 20h9" />
    <path d="M16.5 3.5a2.1 2.1 0 0 1 3 3L7 19l-4 1 1-4z" />
  </svg>
);

export const LogoutIcon = ({ size, ...p }: IconProps) => (
  <svg {...base(size, p)}>
    <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4" />
    <path d="M16 17l5-5-5-5M21 12H9" />
  </svg>
);

export const LoginIcon = ({ size, ...p }: IconProps) => (
  <svg {...base(size, p)}>
    <path d="M15 3h4a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2h-4" />
    <path d="M10 17l-5-5 5-5M3 12h12" />
  </svg>
);

export const BoltIcon = ({ size, ...p }: IconProps) => (
  <svg {...base(size, p)} fill="currentColor" stroke="none">
    <path d="M13 2L3 14h7l-1 8 10-12h-7z" />
  </svg>
);

export const ClockIcon = ({ size, ...p }: IconProps) => (
  <svg {...base(size, p)}>
    <circle cx="12" cy="12" r="9" />
    <path d="M12 7v5l3 2" />
  </svg>
);

export const GridIcon = ({ size, ...p }: IconProps) => (
  <svg {...base(size, p)}>
    <rect x="3" y="3" width="7" height="7" rx="1" />
    <rect x="14" y="3" width="7" height="7" rx="1" />
    <rect x="3" y="14" width="7" height="7" rx="1" />
    <rect x="14" y="14" width="7" height="7" rx="1" />
  </svg>
);

export const ListIcon = ({ size, ...p }: IconProps) => (
  <svg {...base(size, p)}>
    <path d="M8 6h13M8 12h13M8 18h13M3 6h.01M3 12h.01M3 18h.01" />
  </svg>
);

export const CourtIcon = ({ size, ...p }: IconProps) => (
  <svg {...base(size, p)}>
    <rect x="3" y="5" width="18" height="14" rx="1" />
    <path d="M12 5v14M3 12h18" />
  </svg>
);

// Sport-specific icons (badminton / pickleball / basketball)
const ShuttleIcon = ({ size, ...p }: IconProps) => (
  <svg {...base(size, p)}>
    <circle cx="12" cy="17" r="3" />
    <path d="M12 14l-4-9M12 14l4-9M12 14V5M8.5 5h7" />
  </svg>
);

const PaddleIcon = ({ size, ...p }: IconProps) => (
  <svg {...base(size, p)}>
    <circle cx="10" cy="9" r="6" />
    <path d="M14 13l5 6" />
  </svg>
);

const BasketballIcon = ({ size, ...p }: IconProps) => (
  <svg {...base(size, p)}>
    <circle cx="12" cy="12" r="9" />
    <path d="M3 12h18M12 3v18M5 6c3 3 3 11 0 14M19 6c-3 3-3 11 0 14" />
  </svg>
);

export function SportIcon({ type, ...p }: IconProps & { type: SportType }) {
  if (type === "badminton") return <ShuttleIcon {...p} />;
  if (type === "pickleball") return <PaddleIcon {...p} />;
  return <BasketballIcon {...p} />;
}
