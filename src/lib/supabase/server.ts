import { createServerClient } from "@supabase/ssr";
import { cookies } from "next/headers";
import { getSupabasePublicEnv } from "./env";

/**
 * Server-side Supabase client for Server Components, Server Actions, and
 * Route Handlers. Reads the caller's session from cookies and uses the anon
 * key -- RLS enforces authorization, this client never uses the service
 * role key (see CLAUDE.md rule #2).
 */
export async function createClient() {
  const cookieStore = await cookies();
  const { url, anonKey } = getSupabasePublicEnv();

  return createServerClient(url, anonKey, {
    cookies: {
      getAll() {
        return cookieStore.getAll();
      },
      setAll(cookiesToSet) {
        try {
          for (const { name, value, options } of cookiesToSet) {
            cookieStore.set(name, value, options);
          }
        } catch {
          // Called from a Server Component that can't set cookies (e.g. a
          // page render, not a Server Action/Route Handler). The middleware
          // session refresh (see middleware.ts) covers this case, so it's
          // safe to ignore here.
        }
      },
    },
  });
}
