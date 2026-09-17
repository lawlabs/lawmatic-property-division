import { isAfter, n } from "./money.ts";
import type {
  Asset,
  ComputeOptions,
  Position,
  Scenario,
  ScenarioAssetItem,
  Side,
  Valuation,
  ValuationType,
} from "./types.ts";

const COURT_FIRST: ValuationType[] = [
  "court",
  "expert",
  "appraiser",
  "settlement",
  "market_reference",
  "cadastral",
  "sale_price",
];

export function toRubles(amount: number, currency: string, fxRate?: number | null): number | null {
  if (currency === "RUB") return amount;
  if (fxRate == null || fxRate <= 0) return null;
  return amount * fxRate;
}

function latestOfType(valuations: Valuation[], type: ValuationType): Valuation | undefined {
  const matches = valuations.filter((v) => v.type === type);
  if (matches.length === 0) return undefined;
  return matches.reduce((best, current) => {
    if (!best.valued_at) return current;
    if (!current.valued_at) return best;
    return current.valued_at > best.valued_at ? current : best;
  });
}

function pickCourtFirst(asset: Asset, prefer?: ValuationType): Valuation | undefined {
  const order: ValuationType[] = prefer ? [prefer, ...COURT_FIRST.filter((t) => t !== prefer)] : [...COURT_FIRST];
  const acceptedCourt = asset.valuations.find((v) => v.type === "court" && v.accepted_by_court);
  if (acceptedCourt) return acceptedCourt;
  for (const type of order) {
    const found = latestOfType(asset.valuations, type);
    if (found) return found;
  }
  return latestOfType(asset.valuations, "party_wife") ?? latestOfType(asset.valuations, "party_husband");
}

export function selectValuation(
  asset: Asset,
  item: ScenarioAssetItem,
  scenario: Scenario,
  warnings: string[],
): Valuation | null {
  if (item.valuation_id) {
    const found = asset.valuations.find((v) => v.id === item.valuation_id);
    if (!found) {
      warnings.push("valuation.missing");
      return null;
    }
    return found;
  }

  if (scenario.valuation_policy === "per_item") {
    warnings.push("asset.no_valuation_selected");
    return null;
  }

  if (scenario.valuation_policy === "blended") {
    const wife = latestOfType(asset.valuations, "party_wife");
    const husband = latestOfType(asset.valuations, "party_husband");
    if (wife && husband) {
      const w = toRubles(wife.amount, wife.currency, wife.fx_rate);
      const h = toRubles(husband.amount, husband.currency, husband.fx_rate);
      if (w != null && h != null) {
        return {
          id: `${asset.id}-blended`,
          type: "settlement",
          amount: (w + h) / 2,
          currency: "RUB",
        };
      }
    }
    return wife ?? husband ?? pickCourtFirst(asset) ?? null;
  }

  if (scenario.valuation_policy === "wife") {
    return latestOfType(asset.valuations, "party_wife") ?? pickCourtFirst(asset) ?? null;
  }
  if (scenario.valuation_policy === "husband") {
    return latestOfType(asset.valuations, "party_husband") ?? pickCourtFirst(asset) ?? null;
  }

  return pickCourtFirst(asset) ?? null;
}

export function assetValueDetails(
  asset: Asset,
  item: ScenarioAssetItem,
  scenario: Scenario,
  warnings: string[],
  options: ComputeOptions,
): { amount: number; unvalued: boolean } {
  const valuation = selectValuation(asset, item, scenario, warnings);
  if (!valuation) {
    warnings.push("valuation.missing");
    return { amount: 0, unvalued: true };
  }
  const rubles = toRubles(valuation.amount, valuation.currency, valuation.fx_rate);
  if (rubles == null) {
    warnings.push("valuation.fx_missing");
    return { amount: 0, unvalued: true };
  }
  if (options.asOf && valuation.valued_at && isAfter(options.asOf, addMonthsSafe(valuation.valued_at, 6))) {
    warnings.push("valuation.stale");
  }
  return { amount: rubles, unvalued: false };
}

export function assetValueRubles(
  asset: Asset,
  item: ScenarioAssetItem,
  scenario: Scenario,
  warnings: string[],
  options: ComputeOptions,
): number {
  return assetValueDetails(asset, item, scenario, warnings, options).amount;
}

function addMonthsSafe(iso: string, months: number): string {
  const [y, m, d] = iso.split("-").map(Number);
  const date = new Date(Date.UTC(y!, m! - 1 + months, d));
  return date.toISOString().slice(0, 10);
}

export function fundingPersonalShare(funding?: Asset["funding"]): number {
  if (!funding) return 0;
  const personal = n(funding.personal_wife) + n(funding.personal_husband);
  const total =
    n(funding.common) + personal + n(funding.maternity_capital) + n(funding.loan);
  if (total <= 0) return 0;
  return personal / total;
}

export function childrenShare(asset: Asset, childrenCount: number): number {
  if (asset.children_share_override != null) return asset.children_share_override;
  const mc = n(asset.funding?.maternity_capital);
  if (mc <= 0 || childrenCount <= 0) return 0;
  const price =
    asset.acquisition_price && asset.acquisition_price > 0
      ? asset.acquisition_price
      : n(asset.funding?.common) +
        n(asset.funding?.personal_wife) +
        n(asset.funding?.personal_husband) +
        mc +
        n(asset.funding?.loan);
  if (price <= 0) return 0;
  const members = 2 + childrenCount;
  return (mc / price) * (childrenCount / members);
}

const PERSONAL_OR_EXCLUDED: Position[] = ["personal_wife", "personal_husband", "excluded"];

export function resolvePosition(
  asset: Asset,
  item: ScenarioAssetItem,
  scenario: Scenario,
  plaintiff: Side | null,
  warnings: string[],
): Position {
  if (item.accepted_position) return item.accepted_position;
  const w = asset.positions.wife.position;
  const h = asset.positions.husband.position;
  if (w === "common" && h === "common") return "common";
  if (w === h && PERSONAL_OR_EXCLUDED.includes(w)) return w;
  if (w === h && w === "partly_personal") return "partly_personal";

  const kind = scenario.kind;
  if (kind === "claim" && plaintiff) return asset.positions[plaintiff].position;
  if (kind === "counterclaim" && plaintiff) {
    const other: Side = plaintiff === "wife" ? "husband" : "wife";
    return asset.positions[other].position;
  }
  warnings.push("scenario.disputed_position_unresolved");
  return "disputed";
}

export function inMass(position: Position): boolean {
  return position === "common" || position === "partly_personal";
}
