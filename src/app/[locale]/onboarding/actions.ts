"use server";

import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { getCurrentUser } from "@/lib/auth/session";

export async function createFamily(locale: string, formData: FormData) {
  const user = await getCurrentUser();
  if (!user) {
    redirect(`/${locale}/sign-in`);
  }

  const name = String(formData.get("name") ?? "").trim();
  if (!name) {
    return;
  }

  const supabase = await createClient();

  const { data: family, error: familyError } = await supabase
    .from("families")
    .insert({ name })
    .select("id")
    .single();

  if (familyError || !family) {
    redirect(`/${locale}/onboarding?error=1`);
  }

  const { error: memberError } = await supabase
    .from("family_members")
    .insert({ family_id: family.id, user_id: user.id, role: "owner" });

  if (memberError) {
    redirect(`/${locale}/onboarding?error=1`);
  }

  redirect(`/${locale}/onboarding`);
}

export async function joinFamily(locale: string, formData: FormData) {
  const user = await getCurrentUser();
  if (!user) {
    redirect(`/${locale}/sign-in`);
  }

  const inviteCode = String(formData.get("inviteCode") ?? "").trim();
  if (!inviteCode) {
    return;
  }

  const supabase = await createClient();
  const { error } = await supabase.rpc("join_family_by_invite_code", {
    p_invite_code: inviteCode,
  });

  if (error) {
    redirect(`/${locale}/onboarding?error=invalid-code`);
  }

  redirect(`/${locale}`);
}
