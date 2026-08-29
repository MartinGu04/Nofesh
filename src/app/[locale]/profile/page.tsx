import { redirect } from "next/navigation";
import { getTranslations } from "next-intl/server";
import { AppHeader } from "@/components/app-header";
import { getCurrentUser } from "@/lib/auth/session";
import { createClient } from "@/lib/supabase/server";
import { updateProfile } from "./actions";

export default async function ProfilePage({
  params,
  searchParams,
}: {
  params: Promise<{ locale: string }>;
  searchParams: Promise<{ saved?: string }>;
}) {
  const { locale } = await params;
  const { saved } = await searchParams;
  const user = await getCurrentUser();

  if (!user) {
    redirect(`/${locale}/sign-in`);
  }

  const supabase = await createClient();
  const { data: profile } = await supabase
    .from("profiles")
    .select("display_name")
    .eq("user_id", user.id)
    .single();

  const t = await getTranslations();
  const updateProfileWithLocale = updateProfile.bind(null, locale);

  return (
    <>
      <AppHeader locale={locale} />
      <main className="flex flex-1 items-center justify-center bg-background px-[var(--space-md)] py-[var(--space-2xl)]">
        <div className="flex w-full max-w-sm flex-col gap-6 rounded-lg bg-surface-raised p-[var(--space-lg)] shadow-[0_12px_32px_rgba(18,44,66,0.10)]">
          <h1 className="font-display text-2xl text-text">
            {t("profile.title")}
          </h1>
          <form
            action={updateProfileWithLocale}
            className="flex flex-col gap-3"
          >
            <label className="flex flex-col gap-1 text-start text-sm">
              <span className="font-medium text-text">
                {t("profile.displayNameLabel")}
              </span>
              <input
                type="text"
                name="displayName"
                defaultValue={profile?.display_name ?? ""}
                className="rounded-md border border-border bg-background px-[var(--space-sm)] py-2 text-text"
              />
            </label>
            <button
              type="submit"
              className="flex h-12 items-center justify-center rounded-pill bg-primary px-[var(--space-lg)] font-semibold text-white transition-colors hover:bg-primary-hover"
            >
              {t("common.save")}
            </button>
          </form>
          {saved && (
            <p className="text-center text-sm text-accent">
              {t("profile.saved")}
            </p>
          )}
        </div>
      </main>
    </>
  );
}
