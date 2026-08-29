"use client";

import { useFormStatus } from "react-dom";

/**
 * A form's submit button, disabled with pending copy while the action is
 * in flight -- ui-ux-pro-max flags silent submits (no loading/success/
 * error feedback) as high-severity. useFormStatus works inside a plain
 * <form action={...}> without making the whole form a Client Component.
 */
export function SubmitButton({
  children,
  pendingChildren,
  className,
}: {
  children: React.ReactNode;
  pendingChildren: React.ReactNode;
  className?: string;
}) {
  const { pending } = useFormStatus();

  return (
    <button type="submit" disabled={pending} className={className}>
      {pending ? pendingChildren : children}
    </button>
  );
}
