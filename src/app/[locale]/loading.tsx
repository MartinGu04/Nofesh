"use client";

import { useTranslations } from "next-intl";

/**
 * Shared loading fallback for every route in the [locale] segment. A single
 * gentle wave-line pulse, per DESIGN.md's motion guidance (subtle, respects
 * prefers-reduced-motion) -- not a generic spinner-on-white-screen.
 */
export default function Loading() {
  const t = useTranslations("common");

  return (
    <div
      role="status"
      aria-label={t("loading")}
      className="flex flex-1 items-center justify-center bg-background py-[var(--space-2xl)]"
    >
      <svg
        width="64"
        height="16"
        viewBox="0 0 64 16"
        fill="none"
        aria-hidden="true"
        className="text-accent motion-safe:animate-pulse"
      >
        <path
          d="M0 8c4-6 8-6 12 0s8 6 12 0 8-6 12 0 8 6 12 0 8-6 12 0"
          stroke="currentColor"
          strokeWidth="2"
          strokeLinecap="round"
        />
      </svg>
    </div>
  );
}
