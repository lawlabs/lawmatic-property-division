import Foundation

public let specVersion = "2.0.0-alpha"
public let moneyTolerance = 0.01

public enum EngineError: Error, Equatable, CustomStringConvertible {
    case scenarioNotFound(String)
    case regimeNotSupported
    case feeScaleNotSupported

    public var description: String {
        switch self {
        case .scenarioNotFound(let id): return "scenario_not_found:\(id)"
        case .regimeNotSupported: return "regime_not_supported"
        case .feeScaleNotSupported: return "fee.scale_not_supported"
        }
    }
}

public enum Side: String, Codable, Sendable {
    case wife, husband
}

public enum Position: String, Codable, Sendable {
    case common
    case personalWife = "personal_wife"
    case personalHusband = "personal_husband"
    case partlyPersonal = "partly_personal"
    case excluded
    case disputed
}

public enum TransferTarget: String, Codable, Sendable {
    case wife, husband
    case jointShares = "joint_shares"
    case sale, court, children
}

public enum ValuationType: String, Codable, Sendable {
    case partyWife = "party_wife"
    case partyHusband = "party_husband"
    case marketReference = "market_reference"
    case appraiser, expert, court, cadastral
    case salePrice = "sale_price"
    case settlement
}

public enum ScenarioKind: String, Codable, Sendable {
    case claim, counterclaim, settlement, expert
    case courtDecision = "court_decision"
    case appeal, negotiation, other
}

public enum ValuationPolicy: String, Codable, Sendable {
    case courtFirst = "court_first"
    case wife, husband, blended
    case perItem = "per_item"
}

public enum PlaintiffType: String, Codable, Sendable {
    case individual, organization
}

public enum CourtStage: String, Codable, Sendable {
    case firstInstance = "first_instance"
    case appeal, cassation
    case supremeCourt = "supreme_court"
}

public enum Jurisdiction: String, Codable, Sendable {
    case magistrate, district
}

public enum DeadlineLevel: String, Codable, Sendable {
    case info, warning, critical, expired
}

public enum FamilyPurposeStatus: String, Codable, Sendable {
    case proven, disputed
    case notClaimed = "not_claimed"
}

public enum LiabilityAllocation: String, Codable, Sendable {
    case proportional, wife, husband
}

public enum MassCutoff: String, Codable, Sendable {
    case separation, dissolution
}

public struct SidePosition: Codable, Sendable {
    public var position: Position
    public var ground: String?
    public var claimedPersonalShare: Double?
    public var proposedTo: TransferTarget?
}

public struct Valuation: Codable, Sendable {
    public var id: String
    public var type: ValuationType
    public var amount: Double
    public var currency: String
    public var fxRate: Double?
    public var fxDate: String?
    public var valuedAt: String?
    public var source: String?
    public var acceptedByCourt: Bool?
    public var note: String?
}

public struct Funding: Codable, Sendable {
    public var common: Double?
    public var personalWife: Double?
    public var personalHusband: Double?
    public var maternityCapital: Double?
    public var loan: Double?
    public var note: String?
}

public struct Disposed: Codable, Sendable {
    public var at: String?
    public var by: Side?
    public var price: Double?
    public var spouseConsent: Bool?
    public var proceedsUse: String?
}

public struct Asset: Codable, Sendable {
    public var id: String
    public var kind: String
    public var title: String
    public var titleHolder: String
    public var acquiredAt: String?
    public var acquisitionPrice: Double?
    public var funding: Funding?
    public var childrenShareOverride: Double?
    public var disposed: Disposed?
    public var encumbranceLiabilityIds: [String]?
    public var positions: Positions
    public var valuations: [Valuation]

    public struct Positions: Codable, Sendable {
        public var wife: SidePosition
        public var husband: SidePosition
    }
}

public struct Liability: Codable, Sendable {
    public var id: String
    public var kind: String
    public var title: String
    public var outstanding: Outstanding
    public var currency: String
    public var fxRate: Double?
    public var fxDate: String?
    public var linkedAssetId: String?
    public var familyPurpose: FamilyPurpose
    public var positions: LiabilityPositions

    public struct Outstanding: Codable, Sendable {
        public var amount: Double
        public var at: String?
    }

    public struct FamilyPurpose: Codable, Sendable {
        public var claimedBy: Side?
        public var status: FamilyPurposeStatus
    }

    public struct LiabilityPositions: Codable, Sendable {
        public var wife: LoosePosition
        public var husband: LoosePosition
    }

    public struct LoosePosition: Codable, Sendable {
        public var position: String
        public var ground: String?
    }
}

public struct ScenarioAssetItem: Codable, Sendable {
    public var assetId: String
    public var include: Bool
    public var valuationId: String?
    public var acceptedPosition: Position?
    public var personalShareOverride: Double?
    public var addBack: Bool?
    public var assignedTo: TransferTarget?
    public var shareRatio: SideAmounts?
}

public struct ScenarioLiabilityItem: Codable, Sendable {
    public var liabilityId: String
    public var include: Bool
    public var treatAsCommon: Bool
    public var allocation: LiabilityAllocation
}

public struct ScenarioClaim: Codable, Sendable {
    public var plaintiff: Side?
    public var divorceClaimed: Bool?
    public var priorRightEstablished: Bool?
    public var injunctionRequested: Bool?
    public var plaintiffType: PlaintiffType?
    public var claimPriceOverride: Double?
    public var claimPriceNote: String?
    public var filedAt: String?
}

public struct DeviationGround: Codable, Sendable {
    public var kind: String
    public var note: String?
}

public struct Scenario: Codable, Sendable {
    public var id: String
    public var title: String
    public var kind: ScenarioKind
    public var isPrimary: Bool
    public var wifeShare: Double
    public var deviationGrounds: [DeviationGround]?
    public var valuationPolicy: ValuationPolicy
    public var massCutoff: MassCutoff?
    public var assetItems: [ScenarioAssetItem]
    public var liabilityItems: [ScenarioLiabilityItem]
    public var claim: ScenarioClaim?
}

public struct FamilyFacts: Codable, Sendable {
    public var marriage: Marriage
    public var separatedAt: String?
    public var dissolvedAt: String?
    public var contract: FlagDocument?
    public var agreement: Agreement?
    public var parties: Parties
    public var children: [Child]
    public var limitation: Limitation?

    public struct Marriage: Codable, Sendable {
        public var registeredAt: String?
    }

    public struct FlagDocument: Codable, Sendable {
        public var exists: Bool
    }

    public struct Agreement: Codable, Sendable {
        public var exists: Bool
        public var notarized: Bool?
        public var assetIds: [String]?
    }

    public struct Parties: Codable, Sendable {
        public var ourClient: Side?
        public var plaintiff: Side?
    }

    public struct Child: Codable, Sendable {
        public var id: String
        public var name: String
    }

    public struct Limitation: Codable, Sendable {
        public var violationKnownAt: String?
        public var overrideDeadline: String?
        public var note: String?
    }
}

public struct CourtCaseInfo: Codable, Sendable {
    public var decision: Decision?

    public struct Decision: Codable, Sendable {
        public var at: String?
        public var finalFormAt: String?
    }
}

public struct MaritalPropertyCase: Codable, Sendable {
    public var schemaVersion: Int
    public var regime: String
    public var facts: FamilyFacts
    public var assets: [Asset]
    public var liabilities: [Liability]
    public var scenarios: [Scenario]
    public var courtCase: CourtCaseInfo?
}

public struct SideAmounts: Codable, Sendable, Equatable {
    public var wife: Double
    public var husband: Double

    public init(wife: Double = 0, husband: Double = 0) {
        self.wife = wife
        self.husband = husband
    }

    public subscript(_ side: Side) -> Double {
        get { side == .wife ? wife : husband }
        set { if side == .wife { wife = newValue } else { husband = newValue } }
    }
}

public struct Compensation: Sendable, Equatable {
    public var from: Side?
    public var to: Side?
    public var amount: Double
}

public struct MassTotals: Sendable, Equatable {
    public var assetsCommon: Double
    public var liabilitiesCommon: Double
    public var net: Double
}

public struct ReceivedTotals: Sendable, Equatable {
    public var assets: SideAmounts
    public var liabilities: SideAmounts
    public var net: SideAmounts
}

public struct DivisionResult: Sendable {
    public var mass: MassTotals
    public var ideal: SideAmounts
    public var received: ReceivedTotals
    public var unallocated: Double
    public var compensation: Compensation
    public var claimPrice: Double?
    public var courtFee: Double?
    public var jurisdiction: Jurisdiction?
    public var warnings: [String]
}

public struct CourtFeeInput: Codable, Sendable {
    public var claimPrice: Double
    public var filedAt: String?
    public var plaintiffType: PlaintiffType?
    public var divorceClaimed: Bool?
    public var priorRightEstablished: Bool?
    public var injunctionRequested: Bool?
    public var stage: CourtStage?

    public init(
        claimPrice: Double,
        filedAt: String? = nil,
        plaintiffType: PlaintiffType? = nil,
        divorceClaimed: Bool? = nil,
        priorRightEstablished: Bool? = nil,
        injunctionRequested: Bool? = nil,
        stage: CourtStage? = nil
    ) {
        self.claimPrice = claimPrice
        self.filedAt = filedAt
        self.plaintiffType = plaintiffType
        self.divorceClaimed = divorceClaimed
        self.priorRightEstablished = priorRightEstablished
        self.injunctionRequested = injunctionRequested
        self.stage = stage
    }
}

public struct CourtFeeBreakdownItem: Sendable, Equatable {
    public var item: String
    public var amount: Double
    public var basis: String
}

public struct CourtFeeResult: Sendable {
    public var courtFee: Double
    public var breakdown: [CourtFeeBreakdownItem]
    public var warnings: [String]
}

public struct DeadlineItem: Sendable, Equatable {
    public var code: String
    public var date: String?
    public var level: DeadlineLevel?
    public var daysLeft: Int?
}

public struct ComputeOptions: Sendable {
    public var asOf: String?

    public init(asOf: String? = nil) {
        self.asOf = asOf
    }
}

public enum JSONCoding {
    public static func decoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }
}

final class WarningSink {
    private(set) var codes: [String] = []

    func add(_ code: String) {
        if !codes.contains(code) {
            codes.append(code)
        }
    }
}
