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

public enum Side: String, Codable, Sendable, CaseIterable {
    case wife, husband
}

public enum Position: String, Codable, Sendable, CaseIterable {
    case common
    case personalWife = "personal_wife"
    case personalHusband = "personal_husband"
    case partlyPersonal = "partly_personal"
    case excluded
    case disputed
}

public enum TransferTarget: String, Codable, Sendable, CaseIterable {
    case wife, husband
    case jointShares = "joint_shares"
    case sale, court, children
}

public enum ValuationType: String, Codable, Sendable, CaseIterable {
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

public enum FamilyPurposeStatus: String, Codable, Sendable, CaseIterable {
    case proven, disputed
    case notClaimed = "not_claimed"
}

public enum LiabilityAllocation: String, Codable, Sendable, CaseIterable {
    case proportional, wife, husband
}

public enum MassCutoff: String, Codable, Sendable {
    case separation, dissolution
}

public struct SidePosition: Codable, Sendable, Equatable {
    public var position: Position
    public var ground: String?
    public var claimedPersonalShare: Double?
    public var proposedTo: TransferTarget?

    public init(
        position: Position,
        ground: String? = nil,
        claimedPersonalShare: Double? = nil,
        proposedTo: TransferTarget? = nil
    ) {
        self.position = position
        self.ground = ground
        self.claimedPersonalShare = claimedPersonalShare
        self.proposedTo = proposedTo
    }
}

public struct Valuation: Codable, Sendable, Equatable {
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

    public init(
        id: String,
        type: ValuationType,
        amount: Double,
        currency: String = "RUB",
        fxRate: Double? = nil,
        fxDate: String? = nil,
        valuedAt: String? = nil,
        source: String? = nil,
        acceptedByCourt: Bool? = nil,
        note: String? = nil
    ) {
        self.id = id
        self.type = type
        self.amount = amount
        self.currency = currency
        self.fxRate = fxRate
        self.fxDate = fxDate
        self.valuedAt = valuedAt
        self.source = source
        self.acceptedByCourt = acceptedByCourt
        self.note = note
    }
}

public struct Funding: Codable, Sendable, Equatable {
    public var common: Double?
    public var personalWife: Double?
    public var personalHusband: Double?
    public var maternityCapital: Double?
    public var loan: Double?
    public var note: String?

    public init(
        common: Double? = nil,
        personalWife: Double? = nil,
        personalHusband: Double? = nil,
        maternityCapital: Double? = nil,
        loan: Double? = nil,
        note: String? = nil
    ) {
        self.common = common
        self.personalWife = personalWife
        self.personalHusband = personalHusband
        self.maternityCapital = maternityCapital
        self.loan = loan
        self.note = note
    }
}

public struct Disposed: Codable, Sendable, Equatable {
    public var at: String?
    public var by: Side?
    public var price: Double?
    public var spouseConsent: Bool?
    public var proceedsUse: String?

    public init(
        at: String? = nil,
        by: Side? = nil,
        price: Double? = nil,
        spouseConsent: Bool? = nil,
        proceedsUse: String? = nil
    ) {
        self.at = at
        self.by = by
        self.price = price
        self.spouseConsent = spouseConsent
        self.proceedsUse = proceedsUse
    }
}

public struct Asset: Codable, Sendable, Equatable {
    public var id: String
    public var kind: String
    public var title: String
    public var description: String?
    public var identifiers: Identifiers?
    public var titleHolder: String
    public var acquiredAt: String?
    public var acquisitionBasis: String?
    public var acquisitionPrice: Double?
    public var funding: Funding?
    public var childrenShareOverride: Double?
    public var disposed: Disposed?
    public var encumbranceLiabilityIds: [String]?
    public var positions: Positions
    public var valuations: [Valuation]
    public var notes: String?

    public struct Identifiers: Codable, Sendable, Equatable {
        public var cadastral: String?
        public var address: String?
        public var areaSqm: Double?
        public var vin: String?
        public var plate: String?
        public var year: Int?
        public var accountMask: String?
        public var bank: String?
        public var inn: String?
        public var ogrn: String?
        public var sharePct: Double?
        public var other: String?

        public init(
            cadastral: String? = nil,
            address: String? = nil,
            areaSqm: Double? = nil,
            vin: String? = nil,
            plate: String? = nil,
            year: Int? = nil,
            accountMask: String? = nil,
            bank: String? = nil,
            inn: String? = nil,
            ogrn: String? = nil,
            sharePct: Double? = nil,
            other: String? = nil
        ) {
            self.cadastral = cadastral
            self.address = address
            self.areaSqm = areaSqm
            self.vin = vin
            self.plate = plate
            self.year = year
            self.accountMask = accountMask
            self.bank = bank
            self.inn = inn
            self.ogrn = ogrn
            self.sharePct = sharePct
            self.other = other
        }

        public var summary: String? {
            [cadastral, plate, vin, address, bank].compactMap { $0 }.first
        }
    }

    public struct Positions: Codable, Sendable, Equatable {
        public var wife: SidePosition
        public var husband: SidePosition

        public init(wife: SidePosition, husband: SidePosition) {
            self.wife = wife
            self.husband = husband
        }
    }

    public init(
        id: String,
        kind: String,
        title: String,
        description: String? = nil,
        identifiers: Identifiers? = nil,
        titleHolder: String,
        acquiredAt: String? = nil,
        acquisitionBasis: String? = nil,
        acquisitionPrice: Double? = nil,
        funding: Funding? = nil,
        childrenShareOverride: Double? = nil,
        disposed: Disposed? = nil,
        encumbranceLiabilityIds: [String]? = nil,
        positions: Positions = Positions(wife: SidePosition(position: .common), husband: SidePosition(position: .common)),
        valuations: [Valuation],
        notes: String? = nil
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.description = description
        self.identifiers = identifiers
        self.titleHolder = titleHolder
        self.acquiredAt = acquiredAt
        self.acquisitionBasis = acquisitionBasis
        self.acquisitionPrice = acquisitionPrice
        self.funding = funding
        self.childrenShareOverride = childrenShareOverride
        self.disposed = disposed
        self.encumbranceLiabilityIds = encumbranceLiabilityIds
        self.positions = positions
        self.valuations = valuations
        self.notes = notes
    }
}

public struct Liability: Codable, Sendable, Equatable {
    public var id: String
    public var kind: String
    public var title: String
    public var creditorName: String?
    public var contract: Contract?
    public var borrower: String?
    public var principal: Double?
    public var outstanding: Outstanding
    public var currency: String
    public var fxRate: Double?
    public var fxDate: String?
    public var monthlyPayment: Double?
    public var maturityAt: String?
    public var linkedAssetId: String?
    public var familyPurpose: FamilyPurpose
    public var positions: LiabilityPositions
    public var notes: String?

    public struct Contract: Codable, Sendable, Equatable {
        public var number: String?
        public var date: String?

        public init(number: String? = nil, date: String? = nil) {
            self.number = number
            self.date = date
        }
    }

    public struct Outstanding: Codable, Sendable, Equatable {
        public var amount: Double
        public var at: String?

        public init(amount: Double, at: String? = nil) {
            self.amount = amount
            self.at = at
        }
    }

    public struct FamilyPurpose: Codable, Sendable, Equatable {
        public var claimedBy: Side?
        public var status: FamilyPurposeStatus

        public init(claimedBy: Side? = nil, status: FamilyPurposeStatus = .notClaimed) {
            self.claimedBy = claimedBy
            self.status = status
        }
    }

    public struct LiabilityPositions: Codable, Sendable, Equatable {
        public var wife: LoosePosition
        public var husband: LoosePosition

        public init(wife: LoosePosition, husband: LoosePosition) {
            self.wife = wife
            self.husband = husband
        }
    }

    public struct LoosePosition: Codable, Sendable, Equatable {
        public var position: String
        public var ground: String?

        public init(position: String, ground: String? = nil) {
            self.position = position
            self.ground = ground
        }
    }

    public init(
        id: String,
        kind: String,
        title: String,
        creditorName: String? = nil,
        contract: Contract? = nil,
        borrower: String? = nil,
        principal: Double? = nil,
        outstanding: Outstanding,
        currency: String = "RUB",
        fxRate: Double? = nil,
        fxDate: String? = nil,
        monthlyPayment: Double? = nil,
        maturityAt: String? = nil,
        linkedAssetId: String? = nil,
        familyPurpose: FamilyPurpose = FamilyPurpose(),
        positions: LiabilityPositions = LiabilityPositions(
            wife: LoosePosition(position: "common"),
            husband: LoosePosition(position: "common")
        ),
        notes: String? = nil
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.creditorName = creditorName
        self.contract = contract
        self.borrower = borrower
        self.principal = principal
        self.outstanding = outstanding
        self.currency = currency
        self.fxRate = fxRate
        self.fxDate = fxDate
        self.monthlyPayment = monthlyPayment
        self.maturityAt = maturityAt
        self.linkedAssetId = linkedAssetId
        self.familyPurpose = familyPurpose
        self.positions = positions
        self.notes = notes
    }
}

public struct ScenarioAssetItem: Codable, Sendable, Equatable {
    public var assetId: String
    public var include: Bool
    public var valuationId: String?
    public var acceptedPosition: Position?
    public var personalShareOverride: Double?
    public var addBack: Bool?
    public var assignedTo: TransferTarget?
    public var shareRatio: SideAmounts?

    public init(
        assetId: String,
        include: Bool = true,
        valuationId: String? = nil,
        acceptedPosition: Position? = nil,
        personalShareOverride: Double? = nil,
        addBack: Bool? = nil,
        assignedTo: TransferTarget? = nil,
        shareRatio: SideAmounts? = nil
    ) {
        self.assetId = assetId
        self.include = include
        self.valuationId = valuationId
        self.acceptedPosition = acceptedPosition
        self.personalShareOverride = personalShareOverride
        self.addBack = addBack
        self.assignedTo = assignedTo
        self.shareRatio = shareRatio
    }
}

public struct ScenarioLiabilityItem: Codable, Sendable, Equatable {
    public var liabilityId: String
    public var include: Bool
    public var treatAsCommon: Bool
    public var allocation: LiabilityAllocation

    public init(
        liabilityId: String,
        include: Bool = true,
        treatAsCommon: Bool,
        allocation: LiabilityAllocation = .proportional
    ) {
        self.liabilityId = liabilityId
        self.include = include
        self.treatAsCommon = treatAsCommon
        self.allocation = allocation
    }
}

public struct ScenarioClaim: Codable, Sendable, Equatable {
    public var plaintiff: Side?
    public var divorceClaimed: Bool?
    public var priorRightEstablished: Bool?
    public var injunctionRequested: Bool?
    public var plaintiffType: PlaintiffType?
    public var claimPriceOverride: Double?
    public var claimPriceNote: String?
    public var filedAt: String?

    public init(
        plaintiff: Side? = nil,
        divorceClaimed: Bool? = nil,
        priorRightEstablished: Bool? = nil,
        injunctionRequested: Bool? = nil,
        plaintiffType: PlaintiffType? = nil,
        claimPriceOverride: Double? = nil,
        claimPriceNote: String? = nil,
        filedAt: String? = nil
    ) {
        self.plaintiff = plaintiff
        self.divorceClaimed = divorceClaimed
        self.priorRightEstablished = priorRightEstablished
        self.injunctionRequested = injunctionRequested
        self.plaintiffType = plaintiffType
        self.claimPriceOverride = claimPriceOverride
        self.claimPriceNote = claimPriceNote
        self.filedAt = filedAt
    }
}

public struct DeviationGround: Codable, Sendable, Equatable {
    public var kind: String
    public var note: String?

    public init(kind: String, note: String? = nil) {
        self.kind = kind
        self.note = note
    }
}

public struct Scenario: Codable, Sendable, Equatable {
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

    public init(
        id: String,
        title: String,
        kind: ScenarioKind,
        isPrimary: Bool,
        wifeShare: Double,
        deviationGrounds: [DeviationGround]? = nil,
        valuationPolicy: ValuationPolicy,
        massCutoff: MassCutoff? = nil,
        assetItems: [ScenarioAssetItem],
        liabilityItems: [ScenarioLiabilityItem],
        claim: ScenarioClaim? = nil
    ) {
        self.id = id
        self.title = title
        self.kind = kind
        self.isPrimary = isPrimary
        self.wifeShare = wifeShare
        self.deviationGrounds = deviationGrounds
        self.valuationPolicy = valuationPolicy
        self.massCutoff = massCutoff
        self.assetItems = assetItems
        self.liabilityItems = liabilityItems
        self.claim = claim
    }
}

public struct FamilyFacts: Codable, Sendable, Equatable {
    public var marriage: Marriage
    public var separatedAt: String?
    public var dissolvedAt: String?
    public var dissolution: Dissolution?
    public var contract: FlagDocument?
    public var agreement: Agreement?
    public var parties: Parties
    public var children: [Child]
    public var limitation: Limitation?

    public struct Marriage: Codable, Sendable, Equatable {
        public var registeredAt: String?
        public var place: String?
        public var actNumber: String?

        public init(registeredAt: String? = nil, place: String? = nil, actNumber: String? = nil) {
            self.registeredAt = registeredAt
            self.place = place
            self.actNumber = actNumber
        }
    }

    public struct Dissolution: Codable, Sendable, Equatable {
        public var basis: String?
        public var court: String?
        public var decisionNumber: String?
        public var decisionDate: String?

        public init(basis: String? = nil, court: String? = nil, decisionNumber: String? = nil, decisionDate: String? = nil) {
            self.basis = basis
            self.court = court
            self.decisionNumber = decisionNumber
            self.decisionDate = decisionDate
        }
    }

    public struct FlagDocument: Codable, Sendable, Equatable {
        public var exists: Bool

        public init(exists: Bool) {
            self.exists = exists
        }
    }

    public struct Agreement: Codable, Sendable, Equatable {
        public var exists: Bool
        public var notarized: Bool?
        public var assetIds: [String]?

        public init(exists: Bool, notarized: Bool? = nil, assetIds: [String]? = nil) {
            self.exists = exists
            self.notarized = notarized
            self.assetIds = assetIds
        }
    }

    public struct Parties: Codable, Sendable, Equatable {
        public var ourClient: Side?
        public var plaintiff: Side?

        public init(ourClient: Side? = nil, plaintiff: Side? = nil) {
            self.ourClient = ourClient
            self.plaintiff = plaintiff
        }
    }

    public struct Child: Codable, Sendable, Equatable {
        public var id: String
        public var name: String
        public var birthDate: String?

        public init(id: String = UUID().uuidString, name: String, birthDate: String? = nil) {
            self.id = id
            self.name = name
            self.birthDate = birthDate
        }
    }

    public struct Limitation: Codable, Sendable, Equatable {
        public var violationKnownAt: String?
        public var overrideDeadline: String?
        public var note: String?

        public init(violationKnownAt: String? = nil, overrideDeadline: String? = nil, note: String? = nil) {
            self.violationKnownAt = violationKnownAt
            self.overrideDeadline = overrideDeadline
            self.note = note
        }
    }

    public init(
        marriage: Marriage,
        separatedAt: String? = nil,
        dissolvedAt: String? = nil,
        dissolution: Dissolution? = nil,
        contract: FlagDocument? = nil,
        agreement: Agreement? = nil,
        parties: Parties,
        children: [Child],
        limitation: Limitation? = nil
    ) {
        self.marriage = marriage
        self.separatedAt = separatedAt
        self.dissolvedAt = dissolvedAt
        self.dissolution = dissolution
        self.contract = contract
        self.agreement = agreement
        self.parties = parties
        self.children = children
        self.limitation = limitation
    }
}

public struct CourtCaseInfo: Codable, Sendable, Equatable {
    public var decision: Decision?

    public struct Decision: Codable, Sendable, Equatable {
        public var at: String?
        public var finalFormAt: String?

        public init(at: String? = nil, finalFormAt: String? = nil) {
            self.at = at
            self.finalFormAt = finalFormAt
        }
    }

    public init(decision: Decision? = nil) {
        self.decision = decision
    }
}

public struct MaritalPropertyCase: Codable, Sendable, Equatable {
    public var schemaVersion: Int
    public var regime: String
    public var facts: FamilyFacts
    public var assets: [Asset]
    public var liabilities: [Liability]
    public var scenarios: [Scenario]
    public var courtCase: CourtCaseInfo?

    public init(
        schemaVersion: Int,
        regime: String,
        facts: FamilyFacts,
        assets: [Asset],
        liabilities: [Liability],
        scenarios: [Scenario],
        courtCase: CourtCaseInfo? = nil
    ) {
        self.schemaVersion = schemaVersion
        self.regime = regime
        self.facts = facts
        self.assets = assets
        self.liabilities = liabilities
        self.scenarios = scenarios
        self.courtCase = courtCase
    }
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

    public static func encoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
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
