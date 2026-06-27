import type { Config } from "tailwindcss";

const config: Config = {
  content: [
    "./app/**/*.{js,ts,jsx,tsx,mdx}",
    "./components/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    extend: {
      colors: {
        brand: {
          50: "#eef9f0",
          100: "#d6f0db",
          200: "#aee1b9",
          300: "#7fce92",
          400: "#54b96e",
          500: "#33a04f",
          600: "#26803e",
          700: "#1f6633",
          800: "#1a512a",
          900: "#143f21",
        },
      },
      fontFamily: {
        sans: [
          "Plus Jakarta Sans",
          "ui-sans-serif",
          "system-ui",
          "-apple-system",
          "sans-serif",
        ],
      },
    },
  },
  plugins: [],
};

export default config;
