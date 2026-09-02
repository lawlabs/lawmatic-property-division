import Foundation

extension Asset: Identifiable {}
extension Liability: Identifiable {}
extension Scenario: Identifiable {}
extension Valuation: Identifiable {}
extension FamilyFacts.Child: Identifiable {}

extension SidePosition {
    public static func common() -> SidePosition {
        SidePosition(position: .common, ground: nil, claimedPersonalShare: nil, proposedTo: nil)
    }
}

extension Asset.Positions {
    public static func bothCommon() -> Asset.Positions {
        Asset.Positions(wife: .common(), husband: .common())
    }
}

extension Liability.LiabilityPositions {
    public static func bothCommon() -> Liability.LiabilityPositions {
        Liability.LiabilityPositions(
            wife: Liability.LoosePosition(position: "common", ground: nil),
            husband: Liability.LoosePosition(position: "common", ground: nil)
        )
    }
}

extension Scenario {
    public static func primaryClaim(plaintiff: Side = .husband) -> Scenario {
        Scenario(
            id: "s-claim",
            title: "Иск",
            kind: .claim,
            isPrimary: true,
            wifeShare: 0.5,
            deviationGrounds: nil,
            valuationPolicy: .perItem,
            massCutoff: .separation,
            assetItems: [],
            liabilityItems: [],
            claim: ScenarioClaim(
                plaintiff: plaintiff,
                divorceClaimed: nil,
                priorRightEstablished: nil,
                injunctionRequested: nil,
                plaintiffType: .individual,
                claimPriceOverride: nil,
                claimPriceNote: nil,
                filedAt: nil
            )
        )
    }
}

extension MaritalPropertyCase {
    public static func empty() -> MaritalPropertyCase {
        MaritalPropertyCase(
            schemaVersion: 2,
            regime: "ru_community_property",
            facts: FamilyFacts(
                marriage: FamilyFacts.Marriage(registeredAt: nil),
                separatedAt: nil,
                dissolvedAt: nil,
                contract: FamilyFacts.FlagDocument(exists: false),
                agreement: FamilyFacts.Agreement(exists: false, notarized: nil, assetIds: nil),
                parties: FamilyFacts.Parties(ourClient: nil, plaintiff: .husband),
                children: [],
                limitation: nil
            ),
            assets: [],
            liabilities: [],
            scenarios: [.primaryClaim()],
            courtCase: nil
        )
    }
}
