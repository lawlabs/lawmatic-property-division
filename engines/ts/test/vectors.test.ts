import { readdirSync, readFileSync, statSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { describe, expect, it } from "vitest";
import { almostEqual, courtFee, deadlines, divide, jurisdiction } from "../src/index.ts";
import type { CourtFeeInput, MaritalPropertyCase } from "../src/types.ts";

const vectorsRoot = join(dirname(fileURLToPath(import.meta.url)), "../../../vectors");

type Vector = {
  id: string;
  kind: string;
  input: Record<string, unknown>;
  expected: Record<string, unknown>;
};

function loadVectors(): Vector[] {
  const found: Vector[] = [];
  for (const category of readdirSync(vectorsRoot)) {
    const dir = join(vectorsRoot, category);
    if (!statSync(dir).isDirectory()) continue;
    for (const file of readdirSync(dir)) {
      if (!file.endsWith(".json")) continue;
      found.push(JSON.parse(readFileSync(join(dir, file), "utf8")) as Vector);
    }
  }
  return found.sort((a, b) => a.id.localeCompare(b.id));
}

function expectMoney(actual: number, expected: number, label: string): void {
  expect(almostEqual(actual, expected), `${label}: ${actual} ≠ ${expected}`).toBe(true);
}

describe("тест-векторы", () => {
  for (const vector of loadVectors()) {
    it(vector.id, () => {
      switch (vector.kind) {
        case "court_fee": {
          const result = courtFee(vector.input as CourtFeeInput);
          const expected = vector.expected as { court_fee: number; breakdown?: { item: string; amount: number }[] };
          expectMoney(result.court_fee, expected.court_fee, "court_fee");
          if (expected.breakdown) {
            expect(result.breakdown.map((row) => row.item)).toEqual(expected.breakdown.map((row) => row.item));
            for (const [index, row] of expected.breakdown.entries()) {
              expectMoney(result.breakdown[index]!.amount, row.amount, `breakdown.${row.item}`);
            }
          }
          break;
        }
        case "division":
        case "claim_price":
        case "warnings": {
          const input = vector.input as { case: MaritalPropertyCase; scenario_id: string };
          const result = divide(input.case, input.scenario_id);
          const expected = vector.expected as {
            mass?: { assets_common: number; liabilities_common: number; net: number };
            ideal?: { wife: number; husband: number };
            received?: {
              assets: { wife: number; husband: number };
              liabilities: { wife: number; husband: number };
              net: { wife: number; husband: number };
            };
            unallocated?: number;
            compensation?: { from: string | null; to: string | null; amount: number };
            claim_price?: number | null;
            court_fee?: number | null;
            jurisdiction?: string | null;
            warnings?: string[];
          };
          if (expected.mass) {
            expectMoney(result.mass.assets_common, expected.mass.assets_common, "mass.assets_common");
            expectMoney(result.mass.liabilities_common, expected.mass.liabilities_common, "mass.liabilities_common");
            expectMoney(result.mass.net, expected.mass.net, "mass.net");
          }
          if (expected.ideal) {
            expectMoney(result.ideal.wife, expected.ideal.wife, "ideal.wife");
            expectMoney(result.ideal.husband, expected.ideal.husband, "ideal.husband");
          }
          if (expected.received) {
            expectMoney(result.received.assets.wife, expected.received.assets.wife, "received.assets.wife");
            expectMoney(result.received.assets.husband, expected.received.assets.husband, "received.assets.husband");
            expectMoney(result.received.liabilities.wife, expected.received.liabilities.wife, "received.liabilities.wife");
            expectMoney(
              result.received.liabilities.husband,
              expected.received.liabilities.husband,
              "received.liabilities.husband",
            );
            expectMoney(result.received.net.wife, expected.received.net.wife, "received.net.wife");
            expectMoney(result.received.net.husband, expected.received.net.husband, "received.net.husband");
          }
          if (expected.unallocated != null) expectMoney(result.unallocated, expected.unallocated, "unallocated");
          if (expected.compensation) {
            expect(result.compensation.from).toBe(expected.compensation.from);
            expect(result.compensation.to).toBe(expected.compensation.to);
            expectMoney(result.compensation.amount, expected.compensation.amount, "compensation.amount");
          }
          if (expected.claim_price != null) {
            expect(result.claim_price).not.toBeNull();
            expectMoney(result.claim_price!, expected.claim_price, "claim_price");
          }
          if (expected.court_fee != null) {
            expect(result.court_fee).not.toBeNull();
            expectMoney(result.court_fee!, expected.court_fee, "court_fee");
          }
          if (expected.jurisdiction) expect(result.jurisdiction).toBe(expected.jurisdiction);
          if (expected.warnings) {
            for (const code of expected.warnings) {
              expect(result.warnings, `нет предупреждения ${code}: ${result.warnings.join(", ")}`).toContain(code);
            }
          }
          break;
        }
        case "jurisdiction": {
          const input = vector.input as { claim_price: number };
          const expected = vector.expected as { jurisdiction: string };
          expect(jurisdiction(input.claim_price)).toBe(expected.jurisdiction);
          break;
        }
        case "deadlines": {
          const input = vector.input as { case: MaritalPropertyCase; as_of: string };
          const expected = vector.expected as {
            items: { code: string; date?: string | null; level?: string | null }[];
          };
          const items = deadlines(input.case, input.as_of);
          for (const row of expected.items) {
            const found = items.find((item) => item.code === row.code);
            expect(found, `нет срока ${row.code}`).toBeTruthy();
            if (row.date !== undefined) expect(found!.date).toBe(row.date);
            if (row.level !== undefined) expect(found!.level).toBe(row.level);
          }
          break;
        }
        default:
          throw new Error(`неизвестный kind: ${vector.kind}`);
      }
    });
  }
});
