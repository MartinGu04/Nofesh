/**
 * Fails loudly and early if the public Supabase env vars are missing,
 * instead of letting a browser/server client silently construct with
 * `undefined` and fail deep inside a network call. Never import the
 * service-role key here -- it must only ever be read in server-only code
 * that specifically needs it (see CLAUDE.md rule #2).
 *
 * `NEXT_PUBLIC_*` vars must be referenced as static property access
 * (`process.env.NEXT_PUBLIC_X`) for Next.js to inline them into the browser
 * bundle at build time -- it can't follow dynamic access like
 * `process.env[name]`, since that isn't statically analyzable. Server code
 * still sees the real process.env at runtime either way, so a dynamic
 * lookup silently "worked" server-side while quietly returning undefined
 * in the browser. Each var is therefore read by its literal name below,
 * not through a shared name-keyed helper.
 */
function requireEnv(name: string, value: string | undefined): string {
  if (!value) {
    throw new Error(
      `Missing required environment variable: ${name}. See .env.example.`,
    );
  }
  return value;
}

export function getSupabasePublicEnv() {
  return {
    url: requireEnv(
      "NEXT_PUBLIC_SUPABASE_URL",
      process.env.NEXT_PUBLIC_SUPABASE_URL,
    ),
    anonKey: requireEnv(
      "NEXT_PUBLIC_SUPABASE_ANON_KEY",
      process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY,
    ),
  };
}
