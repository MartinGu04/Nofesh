"use client";

import { useEffect } from "react";
import { useTranslations } from "next-intl";

/**
 * Shared error boundary for every route in the [locale] segment. Next.js
 * requires this to be a Client Component. Replaces the default dev/prod
 * stack-trace screen with something that matches DESIGN.md's voice instead.
 */
export default function RouteError({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  const t = useTranslations("errors");

  useEffect(() => {
    console.error(error);
  }, [error]);

  return (
    <div className="flex flex-1 flex-col items-center justify-center gap-4 bg-background px-md py-2xl text-center">
      <p className="text-text-muted">{t("generic")}</p>
      <button
        type="button"
        onClick={reset}
        className="flex h-12 items-center justify-center rounded-pill bg-primary px-lg font-semibold text-white transition-colors hover:bg-primary-hover"
      >
        {t("retry")}
      </button>
    </div>
  );
}
