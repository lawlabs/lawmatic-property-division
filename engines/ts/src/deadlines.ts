import { addMonths, addYears, daysBetween, maxDate } from "./money.ts";
import type { DeadlineItem, DeadlineLevel, MaritalPropertyCase } from "./types.ts";

function level(daysLeft: number): DeadlineLevel {
  if (daysLeft < 0) return "expired";
  if (daysLeft <= 30) return "critical";
  if (daysLeft <= 90) return "warning";
  return "info";
}

function item(code: string, date: string | null, asOf: string): DeadlineItem {
  if (!date) return { code, date: null, level: null, days_left: null };
  const days_left = daysBetween(asOf, date);
  return { code, date, level: level(days_left), days_left };
}

export function deadlines(caseDoc: MaritalPropertyCase, asOf: string): DeadlineItem[] {
  const facts = caseDoc.facts;
  const items: DeadlineItem[] = [];

  const override = facts.limitation?.override_deadline ?? null;
  let limitation: string | null = override;
  if (!limitation && facts.limitation?.violation_known_at) {
    const raw = addYears(facts.limitation.violation_known_at, 3);
    limitation = maxDate(raw, facts.dissolved_at);
  }
  items.push(item("deadline.limitation", limitation, asOf));

  for (const asset of caseDoc.assets) {
    if (asset.disposed?.at && asset.disposed.spouse_consent === false) {
      items.push(item("deadline.disposal_challenge", addYears(asset.disposed.at, 1), asOf));
    }
  }

  if (facts.contract?.exists) {
    items.push(item("deadline.contract_challenge", null, asOf));
  }

  const finalForm = caseDoc.court_case?.decision?.final_form_at ?? null;
  items.push(item("deadline.appeal", finalForm ? addMonths(finalForm, 1) : null, asOf));
  items.push(item("deadline.cassation", finalForm ? addMonths(finalForm, 3) : null, asOf));

  return items;
}
