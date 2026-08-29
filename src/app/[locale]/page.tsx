import { redirect } from "next/navigation";
import { getCurrentUserAndFamily } from "@/lib/auth/session";
import { getFamilyCurrentTrip } from "@/lib/trips/queries";
import { AppHeader } from "@/components/app-header";
import { TripHeroEmpty } from "@/components/trip-hero-empty";
import { TripSummaryCard } from "@/components/trip-summary-card";
import type { AppLocale } from "@/i18n/routing";

/**
 * V1 Slice 1 Home: the family's first real product moment. No trips yet ->
 * the branded empty hero inviting them to plan one. A trip exists -> the
 * smallest meaningful post-creation presentation (destination, dates,
 * who's coming). The full lifecycle-aware Home (PRODUCT.md's six stages)
 * is a later slice -- this only proves trip creation -> a changed Home
 * state, end to end.
 */
export default async function HomePage({
  params,
}: {
  params: Promise<{ locale: string }>;
}) {
  const { locale } = await params;
  const { user, familyId } = await getCurrentUserAndFamily();

  if (!user) {
    redirect(`/${locale}/sign-in`);
  }
  if (!familyId) {
    redirect(`/${locale}/onboarding`);
  }

  const trip = await getFamilyCurrentTrip(familyId);

  return (
    <>
      <AppHeader locale={locale} />
      {trip ? (
        <TripSummaryCard trip={trip} locale={locale as AppLocale} />
      ) : (
        <TripHeroEmpty />
      )}
    </>
  );
}
