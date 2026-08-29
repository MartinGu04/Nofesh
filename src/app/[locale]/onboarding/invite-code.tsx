"use client";

import { useState } from "react";
import { useTranslations } from "next-intl";

export function InviteCode({ code }: { code: string }) {
  const t = useTranslations("family.invite");
  const [copied, setCopied] = useState(false);

  async function handleCopy() {
    try {
      await navigator.clipboard.writeText(code);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    } catch {
      // Clipboard API can be unavailable (permissions, insecure context);
      // the code is still visibly selectable on the page as a fallback.
    }
  }

  return (
    <div className="flex flex-col items-center gap-2">
      <bdi
        dir="ltr"
        className="rounded-md border border-border bg-background px-[var(--space-lg)] py-3 font-display text-2xl tracking-[0.3em] text-text"
      >
        {code}
      </bdi>
      <button
        type="button"
        onClick={handleCopy}
        className="rounded-pill border border-accent px-[var(--space-md)] py-2 text-sm font-semibold text-accent transition-colors hover:bg-accent-muted/30"
      >
        {copied ? t("copied") : t("cta")}
      </button>
    </div>
  );
}
