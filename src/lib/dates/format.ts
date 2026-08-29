import type { AppLocale } from "@/i18n/routing";

// Genuine Intl.DateTimeFormat, not a hand-built dd/mm/yyyy string -- the
// active app locale decides formatting, not a hardcoded pattern. "en-GB"
// (not "en-US") because Nofesh's English UI still serves the same
// day-before-month-reading audience as the Hebrew UI, not a US one.
const INTL_LOCALE: Record<AppLocale, string> = {
  he: "he-IL",
  en: "en-GB",
};

/**
 * A localized, long-form date range ("14–21 באוגוסט 2026" /
 * "14–21 August 2026"), via Intl's own formatRange -- it already handles
 * same-month vs. cross-month vs. cross-year ranges correctly, no manual
 * range-formatting logic needed.
 */
export function formatDateRange(
  locale: AppLocale,
  startDate: string,
  endDate: string,
): string {
  const formatter = new Intl.DateTimeFormat(INTL_LOCALE[locale], {
    day: "numeric",
    month: "long",
    year: "numeric",
  });
  return formatter.formatRange(
    new Date(`${startDate}T00:00:00Z`),
    new Date(`${endDate}T00:00:00Z`),
  );
}
