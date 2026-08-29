import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";
import { createClient } from "@/lib/supabase/server";
import { routing } from "@/i18n/routing";

/**
 * OAuth (Google) and magic-link callback target. Deliberately outside the
 * `[locale]` segment -- this URL is registered as a fixed redirect URI with
 * Google/Supabase and should not depend on locale routing. The `locale`
 * query param (set when the sign-in flow kicked off) decides where to send
 * the user back to.
 */
export async function GET(request: NextRequest) {
  const { searchParams, origin } = new URL(request.url);
  const code = searchParams.get("code");
  const locale = searchParams.get("locale") ?? routing.defaultLocale;

  if (code) {
    const supabase = await createClient();
    await supabase.auth.exchangeCodeForSession(code);
  }

  return NextResponse.redirect(`${origin}/${locale}`);
}
