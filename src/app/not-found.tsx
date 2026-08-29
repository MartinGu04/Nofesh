import Link from "next/link";

/**
 * The only not-found page in the app -- also used for unmatched paths
 * under a real /he or /en prefix, not just fully unresolvable ones.
 * next-intl's official pattern for a locale-aware 404 (a
 * [locale]/[...rest] catch-all calling notFound(), paired with
 * [locale]/not-found.tsx) turned out to misbehave on this Next.js version
 * without a plain app/layout.tsx above [locale]/layout.tsx: it returned
 * HTTP 200 instead of 404, and Next still rendered this root file's
 * content regardless, ignoring the locale-scoped one. This plain root
 * file, with no locale-aware routing trick, gets a correct 404 status and
 * is what actually renders either way -- so it shows both languages
 * rather than guessing, same approach as global-error.tsx.
 */
export default function RootNotFound() {
  return (
    <div
      style={{
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
      <p dir="rtl">לא הצלחנו למצוא את הדף הזה.</p>
      <p dir="ltr">We couldn&apos;t find that page.</p>
      <Link
        href="/"
        style={{
          height: "3rem",
          display: "flex",
          alignItems: "center",
          padding: "0 1.75rem",
          borderRadius: "999px",
          background: "#d97b4f",
          color: "#fff",
          fontWeight: 600,
          textDecoration: "none",
        }}
      >
        Nofesh
      </Link>
    </div>
  );
}
