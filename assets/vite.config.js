import { defineConfig } from "vite";
import { svelte } from "@sveltejs/vite-plugin-svelte";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = fileURLToPath(new URL(".", import.meta.url));

export default defineConfig({
  plugins: [svelte()],
  resolve: {
    alias: {
      "$app/environment": path.resolve(
        __dirname,
        "svelte/lib/sveltekit-shim.js",
      ),
      $lib: path.resolve(__dirname, "svelte/lib"),
      $components: path.resolve(__dirname, "svelte/components"),
      $widgets: path.resolve(__dirname, "svelte/widgets"),
      $routes: path.resolve(__dirname, "svelte/routes"),
    },
  },
  build: {
    outDir: path.resolve(__dirname, "../priv/static"),
    chunkSizeWarningLimit: 1000,
    emptyOutDir: false,
    rollupOptions: {
      input: { app: path.resolve(__dirname, "svelte/main.js") },
      output: {
        entryFileNames: "assets/app.js",
        chunkFileNames: "assets/[name]-[hash].js",
        assetFileNames: (info) =>
          info.names?.[0]?.endsWith(".css")
            ? "assets/app.css"
            : "assets/[name]-[hash][extname]",
      },
    },
  },
});
