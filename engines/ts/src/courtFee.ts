import { roundFeeToRuble } from "./money.ts";
import type { CourtFeeBreakdownItem, CourtFeeInput, CourtFeeResult } from "./types.ts";

export const FEE_SCALE_FROM = "2024-09-09";

const SCALE_BASIS = "пп. 1 п. 1 ст. 333.19 НК РФ (ред. ФЗ от 08.08.2024 № 259-ФЗ)";

/**
 * Шкала имущественного иска для физических лиц, заявления с 09.09.2024.
 * Таблица датирована: при смене закона добавляется новая, эта не удаляется.
 */
export function propertyFeeByScale(price: number): number {
  if (price <= 100_000) return 4_000;
  if (price <= 300_000) return 4_000 + 0.03 * (price - 100_000);
  if (price <= 500_000) return 10_000 + 0.025 * (price - 300_000);
  if (price <= 1_000_000) return 15_000 + 0.02 * (price - 500_000);
  if (price <= 3_000_000) return 25_000 + 0.01 * (price - 1_000_000);
  if (price <= 8_000_000) return 45_000 + 0.007 * (price - 3_000_000);
  if (price <= 24_000_000) return 80_000 + 0.0035 * (price - 8_000_000);
  if (price <= 50_000_000) return 136_000 + 0.003 * (price - 24_000_000);
  if (price <= 100_000_000) return 214_000 + 0.002 * (price - 50_000_000);
  return Math.min(314_000 + 0.0015 * (price - 100_000_000), 900_000);
}

export function courtFee(input: CourtFeeInput): CourtFeeResult {
  const warnings: string[] = [];
  const breakdown: CourtFeeBreakdownItem[] = [];
  const type = input.plaintiff_type ?? "individual";
  const stage = input.stage ?? "first_instance";

  if (input.filed_at && input.filed_at < FEE_SCALE_FROM) {
    throw new Error("fee.scale_not_supported");
  }
  if (type === "organization") {
    warnings.push("fee.organization_scale_not_implemented");
  }

  if (stage === "appeal") {
    breakdown.push({ item: "appeal", amount: 3_000, basis: "ст. 333.19 НК РФ — апелляционная жалоба, 3 000 ₽" });
  } else if (stage === "cassation") {
    breakdown.push({ item: "cassation", amount: 5_000, basis: "ст. 333.19 НК РФ — кассационная жалоба, 5 000 ₽" });
  } else if (stage === "supreme_court") {
    breakdown.push({
      item: "supreme_court",
      amount: 7_000,
      basis: "ст. 333.19 НК РФ — жалоба в Верховный Суд РФ, 7 000 ₽",
    });
  } else if (input.prior_right_established) {
    breakdown.push({
      item: "property_claim_fixed",
      amount: 3_000,
      basis: "пп. 3 п. 1 ст. 333.20 → пп. 3 п. 1 ст. 333.19 НК РФ",
    });
  } else {
    const amount = roundFeeToRuble(propertyFeeByScale(input.claim_price));
    breakdown.push({ item: "property_claim", amount, basis: SCALE_BASIS });
  }

  if (input.divorce_claimed) {
    breakdown.push({ item: "divorce", amount: 5_000, basis: "пп. 5 п. 1 ст. 333.19 НК РФ" });
  }
  if (input.injunction_requested) {
    breakdown.push({
      item: "injunction",
      amount: 10_000,
      basis: "ст. 333.19 НК РФ — заявление об обеспечении иска",
    });
  }

  const court_fee = breakdown.reduce((sum, row) => sum + row.amount, 0);
  return { court_fee, breakdown, warnings };
}

/** Нотариальный тариф за соглашение о разделе: 0,5 %, мин. 300, макс. 20 000 (без УПТХ). */
export function notaryAgreementFee(amount: number): number {
  return Math.min(20_000, Math.max(300, roundFeeToRuble(amount * 0.005)));
}
