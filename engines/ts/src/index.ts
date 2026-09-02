export { SPEC_VERSION } from "./types.ts";
export type {
  Compensation,
  ComputeOptions,
  CourtFeeInput,
  CourtFeeResult,
  DeadlineItem,
  DivisionResult,
  Jurisdiction,
  MaritalPropertyCase,
  Scenario,
} from "./types.ts";

export { courtFee, notaryAgreementFee, propertyFeeByScale } from "./courtFee.ts";
export { jurisdiction, MAGISTRATE_CLAIM_LIMIT } from "./jurisdiction.ts";
export { deadlines } from "./deadlines.ts";
export { claimPrice, divide, warningsFor } from "./divide.ts";
export { almostEqual, MONEY_TOLERANCE } from "./money.ts";
