/**
 * Fails loudly and early if the public Supabase env vars are missing,
 * instead of letting a browser/server client silently construct with
 * `undefined` and fail deep inside a network call. Never import the
 * service-role key here -- it must only ever be read in server-only code
 * that specifically needs it (see CLAUDE.md rule #2).
 */
function requireEnv(name: string): string {
  const value = process.env[name];
  if (!value) {
    throw new Error(
      `Missing required environment variable: ${name}. See .env.example.`,
    );
  }
  return value;
}

export function getSupabasePublicEnv() {
  return {
    url: requireEnv("NEXT_PUBLIC_SUPABASE_URL"),
    anonKey: requireEnv("NEXT_PUBLIC_SUPABASE_ANON_KEY"),
  };
}
