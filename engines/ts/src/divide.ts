import { courtFee } from "./courtFee.ts";
import { jurisdiction } from "./jurisdiction.ts";
import { n } from "./money.ts";
import type {
  Asset,
  Compensation,
  ComputeOptions,
  DivisionResult,
  MaritalPropertyCase,
  Scenario,
  Side,
  SideAmounts,
} from "./types.ts";
import {
  assetValueRubles,
  childrenShare,
  fundingPersonalShare,
  inMass,
  resolvePosition,
  toRubles,
} from "./value.ts";

function emptySides(): SideAmounts {
  return { wife: 0, husband: 0 };
}

function addWarning(warnings: string[], code: string): void {
  if (!warnings.includes(code)) warnings.push(code);
}

function plaintiffOf(caseDoc: MaritalPropertyCase, scenario: Scenario): Side | null {
  return scenario.claim?.plaintiff ?? caseDoc.facts.parties.plaintiff ?? null;
}

function cutoffDate(caseDoc: MaritalPropertyCase, scenario: Scenario): string | null {
  return scenario.mass_cutoff === "dissolution"
    ? (caseDoc.facts.dissolved_at ?? null)
    : (caseDoc.facts.separated_at ?? null);
}

function excludedByAgreement(caseDoc: MaritalPropertyCase, assetId: string): boolean {
  const agreement = caseDoc.facts.agreement;
  if (!agreement?.exists) return false;
  if (agreement.notarized === false) {
    return false;
  }
  return agreement.asset_ids?.includes(assetId) ?? false;
}

export function divide(
  caseDoc: MaritalPropertyCase,
  scenarioId: string,
  options: ComputeOptions = {},
): DivisionResult {
  const scenario = caseDoc.scenarios.find((s) => s.id === scenarioId);
  if (!scenario) throw new Error(`scenario_not_found:${scenarioId}`);
  if (caseDoc.regime !== "ru_community_property") {
    throw new Error("regime_not_supported");
  }

  const warnings: string[] = [];
  const plaintiff = plaintiffOf(caseDoc, scenario);
  const childrenCount = caseDoc.facts.children.length;
  const cutoff = cutoffDate(caseDoc, scenario);
  const asOf = options.asOf ?? scenario.claim?.filed_at ?? null;

  if (scenario.wife_share !== 0.5 && (!scenario.deviation_grounds || scenario.deviation_grounds.length === 0)) {
    addWarning(warnings, "scenario.deviation_without_grounds");
  }
  if (caseDoc.facts.agreement?.exists && caseDoc.facts.agreement.notarized === false) {
    addWarning(warnings, "agreement.not_notarized");
  }

  let assetsCommon = 0;
  const receivedAssets = emptySides();
  let unallocated = 0;
  let claimedByPlaintiff = 0;

  for (const item of scenario.asset_items) {
    if (!item.include) continue;
    const asset = caseDoc.assets.find((a) => a.id === item.asset_id);
    if (!asset) {
      addWarning(warnings, "asset.missing");
      continue;
    }

    if (excludedByAgreement(caseDoc, asset.id)) continue;

    if (cutoff && asset.acquired_at && asset.acquired_at > cutoff) {
      addWarning(warnings, "asset.acquired_after_separation");
      if (!item.accepted_position) continue;
    }

    collectAssetWarnings(asset, warnings);

    const position = resolvePosition(asset, item, scenario, plaintiff, warnings);
    if (!inMass(position)) continue;

    const value = assetValueRubles(asset, item, scenario, warnings, { asOf });
    const personal =
      item.personal_share_override ??
      chosenPersonalShare(asset, position, item) ??
      fundingPersonalShare(asset.funding);
    const kids = childrenShare(asset, childrenCount);
    if (n(asset.funding?.maternity_capital) > 0) {
      addWarning(warnings, "asset.maternity_capital_children_share");
    }
    const commonPart = value * Math.max(0, 1 - personal - kids);
    assetsCommon += commonPart;

    const addBack = Boolean(item.add_back && asset.disposed);
    if (plaintiff && item.assigned_to === plaintiff && !addBack) {
      claimedByPlaintiff += commonPart;
    }
    if (addBack) {
      const disposer = asset.disposed?.by;
      if (disposer) receivedAssets[disposer] += commonPart;
      else unallocated += commonPart;
    } else if (item.assigned_to === "wife" || item.assigned_to === "husband") {
      receivedAssets[item.assigned_to] += commonPart;
    } else if (item.assigned_to === "joint_shares" && item.share_ratio) {
      receivedAssets.wife += commonPart * item.share_ratio.wife;
      receivedAssets.husband += commonPart * item.share_ratio.husband;
    } else {
      unallocated += commonPart;
    }
  }

  let liabilitiesCommon = 0;
  const receivedLiabilities = emptySides();

  for (const item of scenario.liability_items) {
    if (!item.include) continue;
    const liability = caseDoc.liabilities.find((l) => l.id === item.liability_id);
    if (!liability) {
      addWarning(warnings, "liability.missing");
      continue;
    }
    if (liability.family_purpose.status !== "proven") {
      addWarning(warnings, "liability.family_purpose_not_proven");
    }
    if (!item.treat_as_common) continue;

    const amount = toRubles(liability.outstanding.amount, liability.currency, liability.fx_rate);
    if (amount == null) {
      addWarning(warnings, "valuation.fx_missing");
      continue;
    }
    liabilitiesCommon += amount;
    if (liability.kind === "mortgage") {
      addWarning(warnings, "liability.bank_consent_required");
    }

    if (item.allocation === "wife") receivedLiabilities.wife += amount;
    else if (item.allocation === "husband") receivedLiabilities.husband += amount;
    else {
      receivedLiabilities.wife += amount * scenario.wife_share;
      receivedLiabilities.husband += amount * (1 - scenario.wife_share);
    }
  }

  const net = assetsCommon - liabilitiesCommon;
  const ideal: SideAmounts = {
    wife: net * scenario.wife_share,
    husband: net * (1 - scenario.wife_share),
  };
  const receivedNet: SideAmounts = {
    wife: receivedAssets.wife - receivedLiabilities.wife,
    husband: receivedAssets.husband - receivedLiabilities.husband,
  };
  const compensation = compensationOf(receivedNet, ideal);
  if (unallocated > 0) addWarning(warnings, "division.unallocated_present");

  const claimPrice = claimPriceOf(scenario, plaintiff, claimedByPlaintiff, compensation);
  let fee: number | null = null;
  let court: DivisionResult["jurisdiction"] = null;
  if (claimPrice != null) {
    const feeResult = courtFee({
      claim_price: claimPrice,
      filed_at: scenario.claim?.filed_at ?? undefined,
      plaintiff_type: scenario.claim?.plaintiff_type ?? "individual",
      divorce_claimed: scenario.claim?.divorce_claimed ?? false,
      prior_right_established: scenario.claim?.prior_right_established ?? false,
      injunction_requested: scenario.claim?.injunction_requested ?? false,
    });
    fee = feeResult.court_fee;
    court = jurisdiction(claimPrice);
    for (const w of feeResult.warnings) addWarning(warnings, w);
  }

  return {
    mass: { assets_common: assetsCommon, liabilities_common: liabilitiesCommon, net },
    ideal,
    received: { assets: receivedAssets, liabilities: receivedLiabilities, net: receivedNet },
    unallocated,
    compensation,
    claim_price: claimPrice,
    court_fee: fee,
    jurisdiction: court,
    warnings,
  };
}

function chosenPersonalShare(
  asset: Asset,
  position: ReturnType<typeof resolvePosition>,
  item: { accepted_position?: string | null },
): number | null {
  if (item.accepted_position === "partly_personal" || position === "partly_personal") {
    return (
      asset.positions.wife.claimed_personal_share ??
      asset.positions.husband.claimed_personal_share ??
      null
    );
  }
  return null;
}

function compensationOf(receivedNet: SideAmounts, ideal: SideAmounts): Compensation {
  const diff = receivedNet.wife - ideal.wife;
  if (Math.abs(diff) < 0.005) return { from: null, to: null, amount: 0 };
  if (diff > 0) return { from: "wife", to: "husband", amount: diff };
  return { from: "husband", to: "wife", amount: -diff };
}

function claimPriceOf(
  scenario: Scenario,
  plaintiff: Side | null,
  claimedByPlaintiff: number,
  compensation: Compensation,
): number | null {
  if (scenario.claim?.claim_price_override != null) return scenario.claim.claim_price_override;
  if (!plaintiff) return null;
  let price = claimedByPlaintiff;
  if (compensation.to === plaintiff) price += compensation.amount;
  return price;
}

function collectAssetWarnings(asset: Asset, warnings: string[]): void {
  const w = asset.positions.wife;
  const h = asset.positions.husband;
  if (w.position === "disputed" && h.position === "disputed") {
    addWarning(warnings, "asset.no_position_other_side");
  }
  const personal = (side: typeof w) =>
    side.position === "personal_wife" || side.position === "personal_husband";
  if ((personal(w) && !w.ground) || (personal(h) && !h.ground)) {
    addWarning(warnings, "asset.personal_without_ground");
  }
  if (asset.disposed && asset.disposed.spouse_consent === false) {
    addWarning(warnings, "asset.disposed_without_evidence");
  }
  if (
    (w.position === "partly_personal" || h.position === "partly_personal") &&
    !asset.funding?.personal_wife &&
    !asset.funding?.personal_husband
  ) {
    addWarning(warnings, "asset.partly_personal_needs_tracing");
  }
  if (asset.kind === "business_share") {
    addWarning(warnings, "business.charter_consent_required");
  }
  if (asset.kind === "crypto") {
    addWarning(warnings, "asset.crypto_evidence");
  }
}

export function claimPrice(caseDoc: MaritalPropertyCase, scenarioId: string, options?: ComputeOptions): number | null {
  return divide(caseDoc, scenarioId, options).claim_price;
}

export function warningsFor(caseDoc: MaritalPropertyCase, scenarioId: string, options?: ComputeOptions): string[] {
  return divide(caseDoc, scenarioId, options).warnings;
}

