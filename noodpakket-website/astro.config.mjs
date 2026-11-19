// @ts-check
import { defineConfig } from "astro/config";
import sitemap from "@astrojs/sitemap";
import tailwindcss from "@tailwindcss/vite";
import { SITE_URL } from "./src/config/site";
import { lastmodFor } from "./src/lib/sitemap";

export default defineConfig({
  site: SITE_URL,
  output: "static",
  trailingSlash: "never",
  build: { format: "file" },
  integrations: [
    sitemap({
      // lastmod alleen waar een bijgehouden datum bestaat; de 404 hoort er niet in.
      filter: (page) => !page.endsWith("/404"),
      serialize(item) {
        const lastmod = lastmodFor(new URL(item.url).pathname);
        return lastmod ? { ...item, lastmod } : item;
      },
    }),
  ],
  vite: { plugins: [tailwindcss()], build: { assetsInlineLimit: 0 } },
});
