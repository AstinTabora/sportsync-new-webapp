import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

// SportSync customer web — Vite + React SPA.
export default defineConfig({
  plugins: [react()],
  server: {
    port: 5173,
    host: true,
  },
});
