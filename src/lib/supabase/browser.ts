import { createBrowserClient } from "@supabase/ssr";
import { getSupabasePublicEnv } from "./env";

/**
 * Browser-side Supabase client. Uses the anon key only -- RLS is what
 * actually authorizes every read/write this client makes, per
 * ARCHITECTURE.md's "RLS strategy".
 */
export function createClient() {
  const { url, anonKey } = getSupabasePublicEnv();
  return createBrowserClient(url, anonKey);
}
