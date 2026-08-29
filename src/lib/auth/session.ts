import { createClient } from "@/lib/supabase/server";

export async function getCurrentUser() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  return user;
}

/**
 * Resolves the signed-in user's first family membership, if any. A user can
 * belong to more than one family (see ARCHITECTURE.md "Multi-family
 * membership"); Phase 0/V1 UI only ever acts on the first one found, since
 * no UI exists yet for choosing between families.
 */
export async function getCurrentUserAndFamily() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    return { user: null, familyId: null as string | null };
  }

  const { data: membership } = await supabase
    .from("family_members")
    .select("family_id")
    .eq("user_id", user.id)
    .limit(1)
    .maybeSingle();

  return { user, familyId: membership?.family_id ?? null };
}
