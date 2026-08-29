import { createClient } from "@/lib/supabase/server";

export type FamilyTraveler = {
  id: string;
  displayName: string;
  linkedUserId: string | null;
};

/**
 * A family's travelers, with a linked adult's name resolved from their
 * live profile (not the possibly-stale travelers.display_name captured at
 * link time) -- see the traveler_member_linking migration for why this is
 * a query-time preference rather than a kept-in-sync column.
 *
 * travelers.linked_user_id and profiles.user_id are sibling foreign keys
 * to auth.users, not a direct relationship, so PostgREST can't embed
 * profiles in one nested select here -- two queries, merged below.
 */
export async function getFamilyTravelers(
  familyId: string,
): Promise<FamilyTraveler[]> {
  const supabase = await createClient();

  const { data: travelers } = await supabase
    .from("travelers")
    .select("id, display_name, linked_user_id")
    .eq("family_id", familyId)
    .order("created_at", { ascending: true });

  const linkedUserIds = (travelers ?? [])
    .map((t) => t.linked_user_id)
    .filter((id): id is string => id !== null);

  const profileNames = new Map<string, string | null>();
  if (linkedUserIds.length > 0) {
    const { data: profiles } = await supabase
      .from("profiles")
      .select("user_id, display_name")
      .in("user_id", linkedUserIds);
    for (const p of profiles ?? []) {
      profileNames.set(p.user_id, p.display_name);
    }
  }

  return (travelers ?? []).map((t) => ({
    id: t.id,
    displayName:
      (t.linked_user_id ? profileNames.get(t.linked_user_id) : null) ||
      t.display_name,
    linkedUserId: t.linked_user_id,
  }));
}
