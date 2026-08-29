import { redirect } from "next/navigation";
import { getTranslations } from "next-intl/server";
import { Link } from "@/i18n/navigation";
import { getCurrentUserAndFamily } from "@/lib/auth/session";
import { createClient } from "@/lib/supabase/server";
import { createFamily, joinFamily } from "./actions";
import { InviteCode } from "./invite-code";

export default async function OnboardingPage({
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

  const tErrors = await getTranslations("errors");

  if (familyId) {
    const supabase = await createClient();
    const { data: family } = await supabase
      .from("families")
      .select("name, invite_code")
      .eq("id", familyId)
      .single();

    const tInvite = await getTranslations("family.invite");

    return (
      <main className="flex flex-1 items-center justify-center bg-background px-md py-2xl">
        <div className="flex w-full max-w-sm flex-col items-center gap-6 rounded-lg bg-surface-raised p-lg text-center shadow-[0_12px_32px_rgba(18,44,66,0.10)]">
          <div>
            <h1 className="font-display text-2xl text-text">
              {tInvite("title")}
            </h1>
            <p className="mt-2 text-sm text-text-muted">{tInvite("body")}</p>
          </div>
          {family && <InviteCode code={family.invite_code} />}
          <Link
            href="/"
            className="flex h-12 w-full items-center justify-center rounded-pill bg-primary px-lg font-semibold text-white transition-colors hover:bg-primary-hover"
          >
            {tInvite("continueCta")}
          </Link>
        </div>
      </main>
    );
  }

  const tCreate = await getTranslations("family.create");
  const tJoin = await getTranslations("family.join");
  const createFamilyWithLocale = createFamily.bind(null, locale);
  const joinFamilyWithLocale = joinFamily.bind(null, locale);

  return (
    <main className="flex flex-1 items-center justify-center bg-background px-md py-2xl">
      <div className="flex w-full max-w-sm flex-col gap-6 rounded-lg bg-surface-raised p-lg shadow-[0_12px_32px_rgba(18,44,66,0.10)]">
        <div className="text-center">
          <h1 className="font-display text-2xl text-text">
            {tCreate("title")}
          </h1>
        </div>

        <form action={createFamilyWithLocale} className="flex flex-col gap-3">
          <label className="flex flex-col gap-1 text-start text-sm">
            <span className="font-medium text-text">
              {tCreate("nameLabel")}
            </span>
            <input
              type="text"
              name="name"
              required
              placeholder={tCreate("namePlaceholder")}
              className="rounded-md border border-border bg-background px-sm py-2 text-text"
            />
          </label>
          <button
            type="submit"
            className="flex h-12 items-center justify-center rounded-pill bg-primary px-lg font-semibold text-white transition-colors hover:bg-primary-hover"
          >
            {tCreate("cta")}
          </button>
        </form>

        <div className="flex items-center gap-3 text-xs text-text-muted">
          <span className="h-px flex-1 bg-border" />
          <span>{tJoin("divider")}</span>
          <span className="h-px flex-1 bg-border" />
        </div>

        <form action={joinFamilyWithLocale} className="flex flex-col gap-3">
          <label className="flex flex-col gap-1 text-start text-sm">
            <span className="font-medium text-text">{tJoin("title")}</span>
            <input
              type="text"
              name="inviteCode"
              dir="ltr"
              placeholder={tJoin("codeLabel")}
              className="rounded-md border border-border bg-background px-sm py-2 text-text tracking-widest"
            />
          </label>
          <button
            type="submit"
            className="flex h-12 items-center justify-center rounded-pill border border-accent px-lg font-semibold text-accent transition-colors hover:bg-accent-muted/30"
          >
            {tJoin("cta")}
          </button>
        </form>

        {error && (
          <p role="alert" className="text-center text-sm text-red-600">
            {error === "invalid-code"
              ? tErrors("invalidInviteCode")
              : tErrors("generic")}
          </p>
        )}
      </div>
    </main>
  );
}
