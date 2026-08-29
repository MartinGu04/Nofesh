// Asia/Jerusalem, not the server's own timezone or a naive UTC comparison,
// so "today" doesn't flip a day early/late around midnight UTC for
// Israeli users (see israeli-postgres-toolkit's timezone guidance).
const TRIP_TIMEZONE = "Asia/Jerusalem";

/** Today's date in the trip timezone, as YYYY-MM-DD -- directly comparable
 * to trips.start_date/end_date (Postgres `date` columns serialize the
 * same way), no date parsing needed for the comparisons callers do. */
export function todayInTripTimezone(): string {
  return new Intl.DateTimeFormat("en-CA", { timeZone: TRIP_TIMEZONE }).format(
    new Date(),
  );
}

export type TripTiming =
  | { state: "upcoming"; daysUntil: number }
  | { state: "today" }
  | { state: "ongoing" }
  | { state: "past" };

/**
 * Never returns a negative countdown -- a trip that has started is "today"
 * or "ongoing", one that has finished is "past", and only a genuinely
 * future trip gets a days-until count.
 */
export function getTripTiming(startDate: string, endDate: string): TripTiming {
  const today = todayInTripTimezone();

  if (today < startDate) {
    const daysUntil = Math.round(
      (Date.parse(`${startDate}T00:00:00Z`) -
        Date.parse(`${today}T00:00:00Z`)) /
        86_400_000,
    );
    return { state: "upcoming", daysUntil };
  }

  if (today > endDate) {
    return { state: "past" };
  }

  return today === startDate ? { state: "today" } : { state: "ongoing" };
}
