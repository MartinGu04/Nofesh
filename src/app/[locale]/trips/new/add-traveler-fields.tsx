"use client";

import { useState } from "react";
import { useTranslations } from "next-intl";

/**
 * "Add someone" -- lets the family add a traveler without an account
 * (a child, typically) inline while creating the trip, instead of a
 * separate traveler-management screen. Each row submits as a
 * (newTravelerName, newTravelerDob) pair via same-name repeated inputs,
 * which FormData.getAll() returns as parallel arrays in DOM order.
 */
export function AddTravelerFields() {
  const t = useTranslations("trips.create");
  const [rowKeys, setRowKeys] = useState<number[]>([]);
  const [nextKey, setNextKey] = useState(0);

  function addRow() {
    setRowKeys((keys) => [...keys, nextKey]);
    setNextKey((key) => key + 1);
  }

  function removeRow(key: number) {
    setRowKeys((keys) => keys.filter((k) => k !== key));
  }

  return (
    <div className="flex flex-col gap-[var(--space-sm)]">
      {rowKeys.map((key) => (
        <div key={key} className="flex items-end gap-[var(--space-sm)]">
          <label className="flex flex-1 flex-col gap-1 text-start text-sm">
            <span className="font-medium text-text">
              {t("newTravelerNameLabel")}
            </span>
            <input
              type="text"
              name="newTravelerName"
              required
              className="rounded-md border border-border bg-background px-[var(--space-sm)] py-2 text-text"
            />
          </label>
          <label className="flex flex-col gap-1 text-start text-sm">
            <span className="font-medium text-text">
              {t("newTravelerDobLabel")}
            </span>
            <input
              type="date"
              name="newTravelerDob"
              className="rounded-md border border-border bg-background px-[var(--space-sm)] py-2 text-text"
            />
          </label>
          <button
            type="button"
            onClick={() => removeRow(key)}
            aria-label={t("removeTraveler")}
            className="flex h-11 w-11 shrink-0 items-center justify-center rounded-pill text-lg text-text-muted transition-colors hover:bg-accent-muted/30"
          >
            ×
          </button>
        </div>
      ))}
      {/* text-text, not text-accent: teal text at 14px/semibold on a light
          surface only reaches ~4:1 contrast, under DESIGN.md's 4.5:1
          baseline (same issue fixed in trip-summary-card.tsx). The teal
          border alone (a non-text UI boundary, 3:1 threshold) still marks
          this as a distinct/secondary action. */}
      <button
        type="button"
        onClick={addRow}
        className="self-start rounded-pill border border-accent px-[var(--space-md)] py-2 text-sm font-semibold text-text transition-colors hover:bg-accent-muted/30"
      >
        {t("addSomeone")}
      </button>
    </div>
  );
}
