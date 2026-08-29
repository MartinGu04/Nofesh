import { getTranslations } from "next-intl/server";
import { getTripTiming } from "@/lib/dates/trip-timing";
import { formatDateRange } from "@/lib/dates/format";
import type { FamilyTrip } from "@/lib/trips/queries";
import type { AppLocale } from "@/i18n/routing";

/**
 * The smallest meaningful post-creation presentation: destination, dates
 * with a countdown that's always accurate (never negative -- see
 * getTripTiming), and who's coming. One card, per DESIGN.md's "Today
 * surface" guidance -- not a dashboard, and not the full lifecycle Home
 * (that's a later slice).
 */
export async function TripSummaryCard({
  trip,
  locale,
}: {
  trip: FamilyTrip;
  locale: AppLocale;
}) {
  const t = await getTranslations("home.trip");
  const timing = getTripTiming(trip.startDate, trip.endDate);
  const dateRange = formatDateRange(locale, trip.startDate, trip.endDate);

  return (
    <main className="flex flex-1 items-center justify-center bg-background px-[var(--space-md)] py-[var(--space-2xl)]">
      <div className="flex w-full max-w-[32rem] flex-col gap-[var(--space-md)] rounded-lg bg-surface-raised p-[var(--space-lg)] text-center shadow-[0_12px_32px_rgba(18,44,66,0.10)]">
        {/* text-text-muted, not text-accent: at this size/weight (14px,
            semibold) teal-on-white only reaches ~4:1 contrast, under
            DESIGN.md's 4.5:1 baseline -- verified by computing the actual
            ratio, not by eyeballing a screenshot. The uppercase/tracking
            treatment still reads as a distinct "kicker" label without
            needing a separate color. */}
        <p className="text-sm font-semibold uppercase tracking-wide text-text-muted">
          {timing.state === "upcoming" &&
            t("countdown", { days: timing.daysUntil })}
          {timing.state === "today" && t("today")}
          {timing.state === "ongoing" && t("ongoing")}
          {timing.state === "past" && t("past")}
        </p>

        <h1 className="font-display text-3xl text-text">
          <bdi>{trip.destination}</bdi>
        </h1>

        <p className="text-text-muted">
          <bdi>{dateRange}</bdi>
        </p>

        {trip.participantNames.length > 0 && (
          <p className="text-text-muted">
            {t("who")} <bdi>{trip.participantNames.join(", ")}</bdi>
          </p>
        )}

        {timing.state === "upcoming" && (
          <p className="mt-[var(--space-sm)] text-sm text-text-muted">
            {t("hint")}
          </p>
        )}
      </div>
    </main>
  );
}
