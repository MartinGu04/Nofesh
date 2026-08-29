"use client";

import { useEffect } from "react";

/**
 * Last-resort fallback if the root ([locale]) layout itself throws --
 * locale is unknown at that point, so this shows both languages rather than
 * guessing. Rarely hit in practice; exists so a layout-level failure never
 * shows Next.js's raw stack-trace screen. Must render its own <html>/<body>
 * since it replaces the entire tree, including the normal root layout.
 */
export default function GlobalError({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  useEffect(() => {
    console.error(error);
  }, [error]);

  return (
    <html>
      <body
        style={{
          margin: 0,
          minHeight: "100dvh",
          display: "flex",
          flexDirection: "column",
          alignItems: "center",
          justifyContent: "center",
          gap: "1rem",
          padding: "2rem",
          textAlign: "center",
          background: "#faf5eb",
          color: "#1e2a33",
          fontFamily: "-apple-system, BlinkMacSystemFont, sans-serif",
        }}
      >
        <p dir="rtl">משהו השתבש. לנסות שוב?</p>
        <p dir="ltr">Something went wrong. Try again?</p>
        <button
          type="button"
          onClick={reset}
          style={{
            height: "3rem",
            padding: "0 1.75rem",
            borderRadius: "999px",
            border: "none",
            background: "#d97b4f",
            color: "#fff",
            fontWeight: 600,
            cursor: "pointer",
          }}
        >
          Try again / לנסות שוב
        </button>
      </body>
    </html>
  );
}
