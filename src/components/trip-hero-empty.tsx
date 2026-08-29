import { getTranslations } from "next-intl/server";
import { Link } from "@/i18n/navigation";

/**
 * Home when the family has no trips yet -- the first real product moment,
 * not a generic empty state. DESIGN.md's horizon gradient is reserved for
 * exactly this kind of moment ("the hero of a new trip"), with the
 * wave-line motif marking the transition back to the page background
 * instead of a hard rectangle.
 */
export async function TripHeroEmpty() {
  const t = await getTranslations("home.empty");

  return (
    <main className="flex flex-1 flex-col">
      <div
        className="relative flex flex-1 flex-col items-center justify-center gap-[var(--space-md)] overflow-hidden px-[var(--space-md)] py-[var(--space-2xl)] text-center"
        style={{
          background:
            "linear-gradient(135deg, var(--nofesh-navy) 0%, var(--nofesh-terracotta) 100%)",
        }}
      >
        <h1 className="max-w-md text-balance font-display text-4xl leading-tight text-white">
          {t("title")}
        </h1>
        <p className="max-w-sm text-white/85">{t("body")}</p>
        <Link
          href="/trips/new"
          className="mt-[var(--space-sm)] flex h-12 items-center justify-center rounded-pill bg-white px-[var(--space-lg)] font-semibold text-navy transition-colors hover:bg-white/90"
        >
          {t("cta")}
        </Link>

        <svg
          aria-hidden="true"
          viewBox="0 0 400 40"
          preserveAspectRatio="none"
          className="absolute inset-x-0 bottom-0 h-10 w-full text-background"
        >
          <path
            d="M0 20c40-16 80-16 120 0s80 16 120 0 80-16 120 0 80 16 120 0v20H0z"
            fill="currentColor"
          />
        </svg>
      </div>
    </main>
  );
}
