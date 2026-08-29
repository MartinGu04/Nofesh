import { defineRouting } from "next-intl/routing";

/**
 * Hebrew is the default locale per PRODUCT.md / DESIGN.md — Nofesh's target
 * market is Israeli families, and Hebrew is first-class from day one, not a
 * secondary translation of an English-first product.
 */
export const routing = defineRouting({
  locales: ["he", "en"],
  defaultLocale: "he",
});

export type AppLocale = (typeof routing.locales)[number];

export const localeDirection: Record<AppLocale, "rtl" | "ltr"> = {
  he: "rtl",
  en: "ltr",
};
