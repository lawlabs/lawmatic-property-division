import type { Jurisdiction } from "./types.ts";

export const MAGISTRATE_CLAIM_LIMIT = 50_000;

export function jurisdiction(claimPrice: number): Jurisdiction {
  return claimPrice <= MAGISTRATE_CLAIM_LIMIT ? "magistrate" : "district";
}
