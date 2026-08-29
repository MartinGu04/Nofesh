import { createClient } from "@/lib/supabase/server";
import { getFamilyTravelers } from "@/lib/travelers/queries";
import { todayInTripTimezone } from "@/lib/dates/trip-timing";

export type FamilyTrip = {
  id: string;
  destination: string;
  startDate: string;
  endDate: string;
  participantNames: string[];
};

/**
 * The family's single most relevant trip: the soonest one that hasn't
 * ended yet, or -- if every trip is already in the past -- the most
 * recent one, so Home always has something meaningful to show rather than
 * silently falling back to the empty state. This slice only ever creates
 * one trip, but the query is written to behave sensibly if that changes;
 * a real "which trip is most relevant" / trip-switcher UI is deferred
 * (see PRODUCT.md's lifecycle model), not built speculatively here.
 */
export async function getFamilyCurrentTrip(
  familyId: string,
): Promise<FamilyTrip | null> {
  const supabase = await createClient();

  const { data: trips } = await supabase
    .from("trips")
    .select("id, destination, start_date, end_date")
    .eq("family_id", familyId)
    .order("start_date", { ascending: true });

  if (!trips || trips.length === 0) {
    return null;
  }

  const today = todayInTripTimezone();
  const current =
    trips.find((t) => t.end_date >= today) ?? trips[trips.length - 1];

  const { data: participants } = await supabase
    .from("trip_participants")
    .select("traveler_id")
    .eq("trip_id", current.id);

  const travelerIds = new Set((participants ?? []).map((p) => p.traveler_id));
  const allTravelers = await getFamilyTravelers(familyId);
  const participantNames = allTravelers
    .filter((t) => travelerIds.has(t.id))
    .map((t) => t.displayName);

  return {
    id: current.id,
    destination: current.destination,
    startDate: current.start_date,
    endDate: current.end_date,
    participantNames,
  };
}
