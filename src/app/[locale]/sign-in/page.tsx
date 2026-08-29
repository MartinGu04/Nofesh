import { redirect } from "next/navigation";
import { getCurrentUser } from "@/lib/auth/session";
import { SignInForm } from "./sign-in-form";

export default async function SignInPage({
  params,
}: {
  params: Promise<{ locale: string }>;
}) {
  const { locale } = await params;
  const user = await getCurrentUser();
  if (user) {
    redirect(`/${locale}`);
  }

  return (
    <main className="flex flex-1 items-center justify-center bg-background px-[var(--space-md)] py-[var(--space-2xl)]">
      <SignInForm />
    </main>
  );
}
