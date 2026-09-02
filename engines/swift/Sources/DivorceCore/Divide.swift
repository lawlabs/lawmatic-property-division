public func divide(
    _ caseDoc: MaritalPropertyCase,
    scenarioId: String,
    options: ComputeOptions = ComputeOptions()
) throws -> DivisionResult {
    guard let scenario = caseDoc.scenarios.first(where: { $0.id == scenarioId }) else {
        throw EngineError.scenarioNotFound(scenarioId)
    }
    guard caseDoc.regime == "ru_community_property" else {
        throw EngineError.regimeNotSupported
    }

    let warnings = WarningSink()
    let plaintiff = scenario.claim?.plaintiff ?? caseDoc.facts.parties.plaintiff
    let childrenCount = caseDoc.facts.children.count
    let cutoff: String? = scenario.massCutoff == .dissolution
        ? caseDoc.facts.dissolvedAt
        : caseDoc.facts.separatedAt
    let asOf = options.asOf ?? scenario.claim?.filedAt

    if scenario.wifeShare != 0.5 && (scenario.deviationGrounds ?? []).isEmpty {
        warnings.add("scenario.deviation_without_grounds")
    }
    if caseDoc.facts.agreement?.exists == true && caseDoc.facts.agreement?.notarized == false {
        warnings.add("agreement.not_notarized")
    }

    var assetsCommon = 0.0
    var receivedAssets = SideAmounts()
    var unallocated = 0.0
    var claimedByPlaintiff = 0.0

    for item in scenario.assetItems {
        guard item.include else { continue }
        guard let asset = caseDoc.assets.first(where: { $0.id == item.assetId }) else {
            warnings.add("asset.missing")
            continue
        }
        if excludedByAgreement(caseDoc, assetId: asset.id) { continue }

        if let cutoff, let acquired = asset.acquiredAt, acquired > cutoff {
            warnings.add("asset.acquired_after_separation")
            if item.acceptedPosition == nil { continue }
        }

        collectAssetWarnings(asset, warnings)

        let position = resolvePosition(
            asset: asset,
            item: item,
            scenario: scenario,
            plaintiff: plaintiff,
            warnings: warnings
        )
        guard inMass(position) else { continue }

        let value = assetValueRubles(asset: asset, item: item, scenario: scenario, warnings: warnings, asOf: asOf)
        let personal = item.personalShareOverride
            ?? chosenPersonalShare(asset: asset, position: position, item: item)
            ?? fundingPersonalShare(asset.funding)
        let kids = childrenShare(asset: asset, childrenCount: childrenCount)
        if n(asset.funding?.maternityCapital) > 0 {
            warnings.add("asset.maternity_capital_children_share")
        }
        let commonPart = value * max(0, 1 - personal - kids)
        assetsCommon += commonPart

        let addBack = item.addBack == true && asset.disposed != nil
        if let plaintiff, item.assignedTo == transfer(plaintiff), !addBack {
            claimedByPlaintiff += commonPart
        }
        if addBack {
            if let disposer = asset.disposed?.by {
                receivedAssets[disposer] += commonPart
            } else {
                unallocated += commonPart
            }
        } else if let assigned = item.assignedTo, assigned == .wife || assigned == .husband {
            receivedAssets[side(assigned)] += commonPart
        } else if item.assignedTo == .jointShares, let ratio = item.shareRatio {
            receivedAssets.wife += commonPart * ratio.wife
            receivedAssets.husband += commonPart * ratio.husband
        } else {
            unallocated += commonPart
        }
    }

    var liabilitiesCommon = 0.0
    var receivedLiabilities = SideAmounts()

    for item in scenario.liabilityItems {
        guard item.include else { continue }
        guard let liability = caseDoc.liabilities.first(where: { $0.id == item.liabilityId }) else {
            warnings.add("liability.missing")
            continue
        }
        if liability.familyPurpose.status != .proven {
            warnings.add("liability.family_purpose_not_proven")
        }
        guard item.treatAsCommon else { continue }

        guard let amount = toRubles(
            amount: liability.outstanding.amount,
            currency: liability.currency,
            fxRate: liability.fxRate
        ) else {
            warnings.add("valuation.fx_missing")
            continue
        }
        liabilitiesCommon += amount
        if liability.kind == "mortgage" {
            warnings.add("liability.bank_consent_required")
        }
        switch item.allocation {
        case .wife:
            receivedLiabilities.wife += amount
        case .husband:
            receivedLiabilities.husband += amount
        case .proportional:
            receivedLiabilities.wife += amount * scenario.wifeShare
            receivedLiabilities.husband += amount * (1 - scenario.wifeShare)
        }
    }

    let net = assetsCommon - liabilitiesCommon
    let ideal = SideAmounts(wife: net * scenario.wifeShare, husband: net * (1 - scenario.wifeShare))
    let receivedNet = SideAmounts(
        wife: receivedAssets.wife - receivedLiabilities.wife,
        husband: receivedAssets.husband - receivedLiabilities.husband
    )
    let compensation = compensationOf(receivedNet: receivedNet, ideal: ideal)
    if unallocated > 0 { warnings.add("division.unallocated_present") }

    let claimPrice = claimPriceOf(
        scenario: scenario,
        plaintiff: plaintiff,
        claimedByPlaintiff: claimedByPlaintiff,
        compensation: compensation
    )
    var fee: Double?
    var court: Jurisdiction?
    if let claimPrice {
        let feeResult = try courtFee(CourtFeeInput(
            claimPrice: claimPrice,
            filedAt: scenario.claim?.filedAt,
            plaintiffType: scenario.claim?.plaintiffType ?? .individual,
            divorceClaimed: scenario.claim?.divorceClaimed ?? false,
            priorRightEstablished: scenario.claim?.priorRightEstablished ?? false,
            injunctionRequested: scenario.claim?.injunctionRequested ?? false
        ))
        fee = feeResult.courtFee
        court = jurisdiction(claimPrice)
        for code in feeResult.warnings { warnings.add(code) }
    }

    return DivisionResult(
        mass: MassTotals(assetsCommon: assetsCommon, liabilitiesCommon: liabilitiesCommon, net: net),
        ideal: ideal,
        received: ReceivedTotals(assets: receivedAssets, liabilities: receivedLiabilities, net: receivedNet),
        unallocated: unallocated,
        compensation: compensation,
        claimPrice: claimPrice,
        courtFee: fee,
        jurisdiction: court,
        warnings: warnings.codes
    )
}

public func claimPrice(
    _ caseDoc: MaritalPropertyCase,
    scenarioId: String,
    options: ComputeOptions = ComputeOptions()
) throws -> Double? {
    try divide(caseDoc, scenarioId: scenarioId, options: options).claimPrice
}

public func warningsFor(
    _ caseDoc: MaritalPropertyCase,
    scenarioId: String,
    options: ComputeOptions = ComputeOptions()
) throws -> [String] {
    try divide(caseDoc, scenarioId: scenarioId, options: options).warnings
}

private func transfer(_ side: Side) -> TransferTarget {
    side == .wife ? .wife : .husband
}

private func side(_ target: TransferTarget) -> Side {
    target == .wife ? .wife : .husband
}

private func excludedByAgreement(_ caseDoc: MaritalPropertyCase, assetId: String) -> Bool {
    guard let agreement = caseDoc.facts.agreement, agreement.exists else { return false }
    if agreement.notarized == false { return false }
    return agreement.assetIds?.contains(assetId) ?? false
}

private func chosenPersonalShare(asset: Asset, position: Position, item: ScenarioAssetItem) -> Double? {
    if item.acceptedPosition == .partlyPersonal || position == .partlyPersonal {
        return asset.positions.wife.claimedPersonalShare ?? asset.positions.husband.claimedPersonalShare
    }
    return nil
}

private func compensationOf(receivedNet: SideAmounts, ideal: SideAmounts) -> Compensation {
    let diff = receivedNet.wife - ideal.wife
    if abs(diff) < 0.005 { return Compensation(from: nil, to: nil, amount: 0) }
    if diff > 0 { return Compensation(from: .wife, to: .husband, amount: diff) }
    return Compensation(from: .husband, to: .wife, amount: -diff)
}

private func claimPriceOf(
    scenario: Scenario,
    plaintiff: Side?,
    claimedByPlaintiff: Double,
    compensation: Compensation
) -> Double? {
    if let override = scenario.claim?.claimPriceOverride { return override }
    guard let plaintiff else { return nil }
    var price = claimedByPlaintiff
    if compensation.to == plaintiff { price += compensation.amount }
    return price
}

private func collectAssetWarnings(_ asset: Asset, _ warnings: WarningSink) {
    let wife = asset.positions.wife
    let husband = asset.positions.husband
    if wife.position == .disputed && husband.position == .disputed {
        warnings.add("asset.no_position_other_side")
    }
    func isPersonal(_ side: SidePosition) -> Bool {
        side.position == .personalWife || side.position == .personalHusband
    }
    if (isPersonal(wife) && (wife.ground == nil || wife.ground?.isEmpty == true))
        || (isPersonal(husband) && (husband.ground == nil || husband.ground?.isEmpty == true))
    {
        warnings.add("asset.personal_without_ground")
    }
    if asset.disposed?.spouseConsent == false {
        warnings.add("asset.disposed_without_evidence")
    }
    if (wife.position == .partlyPersonal || husband.position == .partlyPersonal)
        && n(asset.funding?.personalWife) == 0
        && n(asset.funding?.personalHusband) == 0
    {
        warnings.add("asset.partly_personal_needs_tracing")
    }
    if asset.kind == "business_share" {
        warnings.add("business.charter_consent_required")
    }
    if asset.kind == "crypto" {
        warnings.add("asset.crypto_evidence")
    }
}
