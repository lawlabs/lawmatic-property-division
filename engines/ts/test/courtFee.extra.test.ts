import { describe, expect, it } from "vitest";
import { courtFee, notaryAgreementFee } from "../src/index.ts";

describe("дополнительные правила пошлины", () => {
  it("отказывает в шкале до 09.09.2024", () => {
    expect(() => courtFee({ claim_price: 100_000, filed_at: "2024-09-08" })).toThrow("fee.scale_not_supported");
  });

  it("считает нотариальный тариф за соглашение о разделе", () => {
    expect(notaryAgreementFee(10_000)).toBe(300);
    expect(notaryAgreementFee(2_000_000)).toBe(10_000);
    expect(notaryAgreementFee(10_000_000)).toBe(20_000);
  });
});
