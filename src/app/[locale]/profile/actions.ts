"use server";

import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { getCurrentUser } from "@/lib/auth/session";

export async function updateProfile(locale: string, formData: FormData) {
  const user = await getCurrentUser();
  if (!user) {
    redirect(`/${locale}/sign-in`);
  }

  const displayName = String(formData.get("displayName") ?? "").trim();
  const supabase = await createClient();

  await supabase
    .from("profiles")
    .update({ display_name: displayName || null })
    .eq("user_id", user.id);

  redirect(`/${locale}/profile?saved=1`);
}
