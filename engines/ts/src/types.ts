export const SPEC_VERSION = "2.0.0-alpha";

export type Side = "wife" | "husband";
export type Position =
  | "common"
  | "personal_wife"
  | "personal_husband"
  | "partly_personal"
  | "excluded"
  | "disputed";
export type TransferTarget = "wife" | "husband" | "joint_shares" | "sale" | "court" | "children";
export type ValuationType =
  | "party_wife"
  | "party_husband"
  | "market_reference"
  | "appraiser"
  | "expert"
  | "court"
  | "cadastral"
  | "sale_price"
  | "settlement";
export type ScenarioKind =
  | "claim"
  | "counterclaim"
  | "settlement"
  | "expert"
  | "court_decision"
  | "appeal"
  | "negotiation"
  | "other";
export type ValuationPolicy = "court_first" | "wife" | "husband" | "blended" | "per_item";
export type PlaintiffType = "individual" | "organization";
export type CourtStage = "first_instance" | "appeal" | "cassation" | "supreme_court";
export type Jurisdiction = "magistrate" | "district";
export type DeadlineLevel = "info" | "warning" | "critical" | "expired";

export type SidePosition = {
  position: Position;
  ground?: string | null;
  claimed_personal_share?: number | null;
  proposed_to?: TransferTarget | null;
};

export type Valuation = {
  id: string;
  type: ValuationType;
  amount: number;
  currency: string;
  fx_rate?: number | null;
  fx_date?: string | null;
  valued_at?: string | null;
  source?: string | null;
  accepted_by_court?: boolean | null;
  note?: string | null;
};

export type Funding = {
  common?: number | null;
  personal_wife?: number | null;
  personal_husband?: number | null;
  maternity_capital?: number | null;
  loan?: number | null;
  note?: string | null;
};

export type Asset = {
  id: string;
  kind: string;
  title: string;
  title_holder: string;
  acquired_at?: string | null;
  acquisition_price?: number | null;
  funding?: Funding | null;
  children_share_override?: number | null;
  disposed?: {
    at?: string | null;
    by?: Side | null;
    price?: number | null;
    spouse_consent?: boolean | null;
    proceeds_use?: string | null;
  } | null;
  encumbrance_liability_ids?: string[];
  positions: { wife: SidePosition; husband: SidePosition };
  valuations: Valuation[];
};

export type Liability = {
  id: string;
  kind: string;
  title: string;
  outstanding: { amount: number; at?: string | null };
  currency: string;
  fx_rate?: number | null;
  fx_date?: string | null;
  linked_asset_id?: string | null;
  family_purpose: {
    claimed_by?: Side | null;
    status: "proven" | "disputed" | "not_claimed";
  };
  positions: {
    wife: { position: string; ground?: string | null };
    husband: { position: string; ground?: string | null };
  };
};

export type ScenarioAssetItem = {
  asset_id: string;
  include: boolean;
  valuation_id?: string | null;
  accepted_position?: Position | null;
  personal_share_override?: number | null;
  add_back?: boolean | null;
  assigned_to?: TransferTarget | null;
  share_ratio?: { wife: number; husband: number } | null;
};

export type ScenarioLiabilityItem = {
  liability_id: string;
  include: boolean;
  treat_as_common: boolean;
  allocation: "proportional" | "wife" | "husband";
};

export type ScenarioClaim = {
  plaintiff?: Side | null;
  divorce_claimed?: boolean;
  prior_right_established?: boolean;
  injunction_requested?: boolean;
  plaintiff_type?: PlaintiffType;
  claim_price_override?: number | null;
  claim_price_note?: string | null;
  filed_at?: string | null;
};

export type Scenario = {
  id: string;
  title: string;
  kind: ScenarioKind;
  is_primary: boolean;
  wife_share: number;
  deviation_grounds?: { kind: string; note?: string | null }[];
  valuation_policy: ValuationPolicy;
  mass_cutoff?: "separation" | "dissolution";
  asset_items: ScenarioAssetItem[];
  liability_items: ScenarioLiabilityItem[];
  claim?: ScenarioClaim | null;
};

export type FamilyFacts = {
  marriage: { registered_at?: string | null };
  separated_at?: string | null;
  dissolved_at?: string | null;
  contract?: { exists: boolean } | null;
  agreement?: {
    exists: boolean;
    notarized?: boolean | null;
    asset_ids?: string[];
  } | null;
  parties: { our_client?: Side | null; plaintiff?: Side | null };
  children: { id: string; name: string }[];
  limitation?: {
    violation_known_at?: string | null;
    override_deadline?: string | null;
  } | null;
};

export type MaritalPropertyCase = {
  schema_version: 2;
  regime: "ru_community_property";
  facts: FamilyFacts;
  assets: Asset[];
  liabilities: Liability[];
  scenarios: Scenario[];
  court_case?: {
    decision?: { at?: string | null; final_form_at?: string | null } | null;
  } | null;
};

export type SideAmounts = { wife: number; husband: number };

export type Compensation = {
  from: Side | null;
  to: Side | null;
  amount: number;
};

export type DivisionAssetLine = {
  asset_id: string;
  value: number | null;
  common_part: number;
  assigned_to: TransferTarget | null;
  in_mass: boolean;
  unvalued: boolean;
};

export type DivisionResult = {
  mass: { assets_common: number; liabilities_common: number; net: number };
  ideal: SideAmounts;
  received: { assets: SideAmounts; liabilities: SideAmounts; net: SideAmounts };
  unallocated: number;
  compensation: Compensation;
  claim_price: number | null;
  court_fee: number | null;
  jurisdiction: Jurisdiction | null;
  warnings: string[];
  asset_lines: DivisionAssetLine[];
};

export type CourtFeeInput = {
  claim_price: number;
  filed_at?: string;
  plaintiff_type?: PlaintiffType;
  divorce_claimed?: boolean;
  prior_right_established?: boolean;
  injunction_requested?: boolean;
  stage?: CourtStage;
};

export type CourtFeeBreakdownItem = {
  item:
    | "property_claim"
    | "property_claim_fixed"
    | "divorce"
    | "injunction"
    | "appeal"
    | "cassation"
    | "supreme_court";
  amount: number;
  basis: string;
};

export type CourtFeeResult = {
  court_fee: number;
  breakdown: CourtFeeBreakdownItem[];
  warnings: string[];
};

export type DeadlineItem = {
  code: string;
  date: string | null;
  level: DeadlineLevel | null;
  days_left: number | null;
};

export type ComputeOptions = {
  asOf?: string | null;
};
