"use server";

import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { getCurrentUserAndFamily } from "@/lib/auth/session";

export async function createTrip(locale: string, formData: FormData) {
  const { user, familyId } = await getCurrentUserAndFamily();
  if (!user) {
    redirect(`/${locale}/sign-in`);
  }
  if (!familyId) {
    redirect(`/${locale}/onboarding`);
  }

  const destination = String(formData.get("destination") ?? "").trim();
  const startDate = String(formData.get("startDate") ?? "");
  const endDate = String(formData.get("endDate") ?? "");
  const travelerIds = formData.getAll("travelerId").map(String);

  // Same-name repeated inputs (see add-traveler-fields.tsx) come back as
  // parallel arrays in DOM order; skip any row the user added but never
  // named. create_trip() re-validates all of this server-side regardless
  // -- this is just keeping obviously-empty rows from ever reaching it.
  const newTravelerNames = formData.getAll("newTravelerName").map(String);
  const newTravelerDobs = formData.getAll("newTravelerDob").map(String);
  const newTravelers = newTravelerNames
    .map((name, i) => ({
      name: name.trim(),
      date_of_birth: newTravelerDobs[i] || null,
    }))
    .filter((t) => t.name !== "");

  if (!destination || !startDate || !endDate) {
    redirect(`/${locale}/trips/new?error=1`);
  }

  const supabase = await createClient();
  const { error } = await supabase.rpc("create_trip", {
    p_family_id: familyId,
    p_destination: destination,
    p_start_date: startDate,
    p_end_date: endDate,
    p_traveler_ids: travelerIds,
    p_new_travelers: newTravelers,
  });

  if (error) {
    redirect(`/${locale}/trips/new?error=1`);
  }

  redirect(`/${locale}`);
}
