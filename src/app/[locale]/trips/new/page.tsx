import { redirect } from "next/navigation";
import { getTranslations } from "next-intl/server";
import { getCurrentUserAndFamily } from "@/lib/auth/session";
import { getFamilyTravelers } from "@/lib/travelers/queries";
import { AppHeader } from "@/components/app-header";
import { SubmitButton } from "@/components/submit-button";
import { AddTravelerFields } from "./add-traveler-fields";
import { createTrip } from "./actions";

export default async function NewTripPage({
  params,
  searchParams,
}: {
  params: Promise<{ locale: string }>;
  searchParams: Promise<{ error?: string }>;
}) {
  const { locale } = await params;
  const { error } = await searchParams;
  const { user, familyId } = await getCurrentUserAndFamily();

  if (!user) {
    redirect(`/${locale}/sign-in`);
  }
  if (!familyId) {
    redirect(`/${locale}/onboarding`);
  }

  const travelers = await getFamilyTravelers(familyId);
  const t = await getTranslations();
  const createTripWithLocale = createTrip.bind(null, locale);
  const inputClass =
    "rounded-md border border-border bg-background px-[var(--space-md)] py-3 text-text";

  return (
    <>
      <AppHeader locale={locale} />
      <main className="flex flex-1 justify-center bg-background px-[var(--space-md)] py-[var(--space-2xl)]">
        <form
          action={createTripWithLocale}
          className="flex w-full max-w-[36rem] flex-col gap-[var(--space-lg)]"
        >
          <h1 className="text-center font-display text-3xl text-text">
            {t("trips.create.title")}
          </h1>

          <label className="flex flex-col gap-1 text-start">
            <span className="font-medium text-text">
              {t("trips.create.destinationLabel")}
            </span>
            <input
              type="text"
              name="destination"
              required
              placeholder={t("trips.create.destinationPlaceholder")}
              className={`${inputClass} text-lg`}
            />
          </label>

          <fieldset className="flex flex-col gap-2">
            <legend className="mb-1 font-medium text-text">
              {t("trips.create.whenLabel")}
            </legend>
            <div className="flex gap-[var(--space-sm)]">
              <label className="flex flex-1 flex-col gap-1 text-start text-sm">
                <span className="text-text-muted">
                  {t("trips.create.startDateLabel")}
                </span>
                <input
                  type="date"
                  name="startDate"
                  required
                  className={inputClass}
                />
              </label>
              <label className="flex flex-1 flex-col gap-1 text-start text-sm">
                <span className="text-text-muted">
                  {t("trips.create.endDateLabel")}
                </span>
                <input
                  type="date"
                  name="endDate"
                  required
                  className={inputClass}
                />
              </label>
            </div>
          </fieldset>

          <fieldset className="flex flex-col gap-[var(--space-sm)]">
            <legend className="mb-1 font-medium text-text">
              {t("trips.create.whoLabel")}
            </legend>
            <div className="flex flex-col gap-1">
              {travelers.map((traveler) => (
                <label
                  key={traveler.id}
                  className="flex min-h-11 items-center gap-3"
                >
                  <input
                    type="checkbox"
                    name="travelerId"
                    value={traveler.id}
                    defaultChecked={traveler.linkedUserId === user.id}
                    className="h-5 w-5 shrink-0 accent-primary"
                  />
                  <span className="text-text">{traveler.displayName}</span>
                </label>
              ))}
            </div>
            <AddTravelerFields />
          </fieldset>

          {error && (
            <p role="alert" className="text-center text-sm text-red-600">
              {t("errors.generic")}
            </p>
          )}

          <SubmitButton
            pendingChildren={t("common.loading")}
            className="flex h-12 items-center justify-center rounded-pill bg-primary px-[var(--space-lg)] font-semibold text-white transition-colors hover:bg-primary-hover disabled:opacity-50"
          >
            {t("trips.create.submitCta")}
          </SubmitButton>
        </form>
      </main>
    </>
  );
}
