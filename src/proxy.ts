import { createServerClient } from "@supabase/ssr";
import type { NextRequest } from "next/server";
import createMiddleware from "next-intl/middleware";
import { routing } from "./i18n/routing";
import { getSupabasePublicEnv } from "./lib/supabase/env";

const handleI18nRouting = createMiddleware(routing);

export default async function proxy(request: NextRequest) {
  const response = handleI18nRouting(request);

  // Env vars may not be set yet (e.g. before a Supabase project exists) --
  // degrade to i18n-only routing rather than hard-crashing every request.
  let publicEnv: ReturnType<typeof getSupabasePublicEnv>;
  try {
    publicEnv = getSupabasePublicEnv();
  } catch {
    return response;
  }

  const supabase = createServerClient(publicEnv.url, publicEnv.anonKey, {
    cookies: {
      getAll() {
        return request.cookies.getAll();
      },
      setAll(cookiesToSet) {
        for (const { name, value, options } of cookiesToSet) {
          response.cookies.set(name, value, options);
        }
      },
    },
  });

  // Refreshes the auth session cookie (if any) so Server Components
  // downstream see an up-to-date session on every request.
  await supabase.auth.getUser();

  return response;
}

export const config = {
  // Exclude API routes, Next.js internals, the OAuth callback route, and
  // any request for a static file (has a dot in the last path segment).
  matcher: ["/((?!api|_next|_vercel|auth|.*\\..*).*)"],
};
