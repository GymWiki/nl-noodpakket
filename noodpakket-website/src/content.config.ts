import { defineCollection } from "astro:content";
import { glob } from "astro/loaders";
import { z } from "astro/zod";

/** Eén Markdown-bestand per release in src/content/wijzigingen/. */
const wijzigingen = defineCollection({
  loader: glob({ pattern: "**/*.md", base: "./src/content/wijzigingen" }),
  schema: z.object({
    version: z.string(),
    date: z.coerce.date(),
    title: z.string().optional(),
  }),
});

export const collections = { wijzigingen };
