"use client";

import { useState } from "react";
import { useTranslations, useLocale } from "next-intl";
import { useRouter } from "@/i18n/navigation";
import { createClient } from "@/lib/supabase/browser";

type Step = "start" | "otp-sent";

export function SignInForm() {
  const t = useTranslations("auth.signIn");
  const tErrors = useTranslations("errors");
  const locale = useLocale();
  const router = useRouter();

  const [step, setStep] = useState<Step>("start");
  const [email, setEmail] = useState("");
  const [code, setCode] = useState("");
  const [pending, setPending] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handleGoogleSignIn() {
    setError(null);
    setPending(true);
    const supabase = createClient();
    const { error: oauthError } = await supabase.auth.signInWithOAuth({
      provider: "google",
      options: {
        redirectTo: `${window.location.origin}/auth/callback?locale=${locale}`,
      },
    });
    if (oauthError) {
      setError(tErrors("generic"));
      setPending(false);
    }
    // On success the browser is redirected to Google; nothing else to do.
  }

  async function handleRequestOtp(formEvent: React.FormEvent) {
    formEvent.preventDefault();
    setError(null);
    setPending(true);
    const supabase = createClient();
    const { error: otpError } = await supabase.auth.signInWithOtp({
      email,
      options: {
        emailRedirectTo: `${window.location.origin}/auth/callback?locale=${locale}`,
      },
    });
    setPending(false);
    if (otpError) {
      setError(tErrors("generic"));
      return;
    }
    setStep("otp-sent");
  }

  async function handleVerifyOtp(formEvent: React.FormEvent) {
    formEvent.preventDefault();
    setError(null);
    setPending(true);
    const supabase = createClient();
    const { error: verifyError } = await supabase.auth.verifyOtp({
      email,
      token: code,
      type: "email",
    });
    setPending(false);
    if (verifyError) {
      setError(tErrors("generic"));
      return;
    }
    router.push("/");
    router.refresh();
  }

  return (
    <div className="flex w-full max-w-sm flex-col gap-6 rounded-lg bg-surface-raised p-[var(--space-lg)] shadow-[0_12px_32px_rgba(18,44,66,0.10)]">
      <div className="flex flex-col gap-2 text-center">
        <h1 className="font-display text-3xl text-text">{t("title")}</h1>
        <p className="text-sm text-text-muted">{t("subtitle")}</p>
      </div>

      <button
        type="button"
        onClick={handleGoogleSignIn}
        disabled={pending}
        className="flex h-12 items-center justify-center rounded-pill bg-primary px-[var(--space-lg)] font-semibold text-white transition-colors hover:bg-primary-hover disabled:opacity-50"
      >
        {t("googleCta")}
      </button>

      <div className="flex items-center gap-3 text-xs text-text-muted">
        <span className="h-px flex-1 bg-border" />
        <span aria-hidden="true">·</span>
        <span className="h-px flex-1 bg-border" />
      </div>

      {step === "start" && (
        <form onSubmit={handleRequestOtp} className="flex flex-col gap-3">
          <label className="flex flex-col gap-1 text-start text-sm">
            <span className="font-medium text-text">{t("emailLabel")}</span>
            <input
              type="email"
              required
              dir="ltr"
              autoComplete="email"
              value={email}
              onChange={(inputEvent) => setEmail(inputEvent.target.value)}
              className="rounded-md border border-border bg-background px-[var(--space-sm)] py-2 text-text"
            />
          </label>
          <button
            type="submit"
            disabled={pending}
            className="flex h-12 items-center justify-center rounded-pill border border-accent px-[var(--space-lg)] font-semibold text-accent transition-colors hover:bg-accent-muted/30 disabled:opacity-50"
          >
            {t("otpCta")}
          </button>
        </form>
      )}

      {step === "otp-sent" && (
        <form onSubmit={handleVerifyOtp} className="flex flex-col gap-3">
          <div className="text-start text-sm text-text-muted">
            <p className="font-medium text-text">{t("otpSentTitle")}</p>
            <p>{t("otpSentBody", { email })}</p>
          </div>
          <label className="flex flex-col gap-1 text-start text-sm">
            <span className="font-medium text-text">{t("otpCodeLabel")}</span>
            <input
              type="text"
              inputMode="numeric"
              autoComplete="one-time-code"
              dir="ltr"
              required
              value={code}
              onChange={(inputEvent) => setCode(inputEvent.target.value)}
              className="rounded-md border border-border bg-background px-[var(--space-sm)] py-2 text-text tracking-widest"
            />
          </label>
          <button
            type="submit"
            disabled={pending}
            className="flex h-12 items-center justify-center rounded-pill bg-primary px-[var(--space-lg)] font-semibold text-white transition-colors hover:bg-primary-hover disabled:opacity-50"
          >
            {t("otpCta")}
          </button>
        </form>
      )}

      {error && (
        <p role="alert" className="text-sm text-red-600">
          {error}
        </p>
      )}
    </div>
  );
}
