/** @type {import('tailwindcss').Config} */
// Design tokens ported 1:1 from the Flutter app's lib/core/theme/*.dart.
export default {
  content: ["./index.html", "./src/**/*.{ts,tsx}"],
  theme: {
    extend: {
      colors: {
        // Brand
        primary: {
          DEFAULT: "#005F02",
          dark: "#004001",
          light: "#008003",
          xlight: "#E6F0E6",
        },
        // Surface
        canvas: "#F0EEE9",
        surface: "#FAFAF7",
        // Slate (Tailwind already has these, but pin exact values used in app)
        slate: {
          50: "#F8FAFC",
          100: "#F1F5F9",
          200: "#E2E8F0",
          300: "#CBD5E1",
          400: "#94A3B8",
          500: "#64748B",
          600: "#475569",
          700: "#334155",
          800: "#1E293B",
          900: "#0F172A",
        },
        // Status
        amber: { DEFAULT: "#F59E0B", bg: "#FEF3C7" },
        emerald: { DEFAULT: "#10B981", bg: "#D1FAE5" },
        info: { DEFAULT: "#3B82F6", bg: "#DBEAFE" },
        purple: { DEFAULT: "#A855F7", bg: "#F4E6FF" },
        booked: { DEFAULT: "#00A651", bg: "#E6F7ED" },
        gcash: "#0070E0",
      },
      fontFamily: {
        sans: [
          "-apple-system",
          "BlinkMacSystemFont",
          "SF Pro Text",
          "SF Pro Display",
          "system-ui",
          "Segoe UI",
          "Roboto",
          "sans-serif",
        ],
      },
      borderRadius: {
        sm: "8px",
        md: "12px",
        lg: "16px",
        xl: "20px",
        "2xl": "24px",
        "3xl": "28px",
        pill: "999px",
      },
      boxShadow: {
        card: "0 4px 16px rgba(0,0,0,0.08)",
        subtle: "0 2px 12px rgba(0,0,0,0.04)",
        pill: "0 8px 24px rgba(0,0,0,0.08)",
        cta: "0 12px 24px rgba(0,95,2,0.30)",
        hero: "0 20px 60px rgba(0,0,0,0.20)",
        nav: "0 -10px 40px rgba(0,0,0,0.06)",
      },
      maxWidth: {
        content: "1200px",
      },
    },
  },
  plugins: [],
};
