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

  // create_family() does both inserts (the family row, and the caller's
  // own family_members row as owner) atomically in one SECURITY DEFINER
  // call -- see the migration for why this can't be two separate
  // client-side inserts (the family row wasn't yet readable under RLS
  // between them).
  const { error } = await supabase.rpc("create_family", { p_name: name });

  if (error) {
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
