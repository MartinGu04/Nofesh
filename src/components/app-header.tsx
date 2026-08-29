import { getTranslations } from "next-intl/server";
import { Link } from "@/i18n/navigation";
import { signOut } from "@/lib/auth/actions";

export async function AppHeader({ locale }: { locale: string }) {
  const t = await getTranslations();
  const signOutWithLocale = signOut.bind(null, locale);

  return (
    <header className="flex items-center justify-between border-b border-border px-[var(--space-md)] py-[var(--space-sm)]">
      <Link href="/" className="font-display text-lg text-text">
        {t("app.name")}
      </Link>
      <nav className="flex items-center gap-[var(--space-md)] text-sm">
        <Link href="/profile" className="text-text-muted hover:text-text">
          {t("profile.title")}
        </Link>
        <form action={signOutWithLocale}>
          <button
            type="submit"
            className="text-text-muted transition-colors hover:text-text"
          >
            {t("common.signOut")}
          </button>
        </form>
      </nav>
    </header>
  );
}
