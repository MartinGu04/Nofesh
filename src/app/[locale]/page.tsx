import { redirect } from "next/navigation";
import { getTranslations } from "next-intl/server";
import { getCurrentUserAndFamily } from "@/lib/auth/session";
import { AppHeader } from "@/components/app-header";

/**
 * Phase 0 Home: an authenticated, empty shell. No trips exist yet, so there
 * is no lifecycle logic here (see PRODUCT.md's lifecycle model) -- that's
 * V1. This route only proves sign-in -> family membership -> a real
 * authenticated page, end to end.
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

  const t = await getTranslations("home");

  return (
    <>
      <AppHeader locale={locale} />
      <main className="flex flex-1 flex-col items-center justify-center gap-3 px-md py-2xl text-center">
        <h1 className="font-display text-3xl text-text">
          {t("emptyTitle")}
        </h1>
        <p className="max-w-md text-text-muted">{t("emptyBody")}</p>
      </main>
    </>
  );
}
