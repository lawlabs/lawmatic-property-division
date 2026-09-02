private let courtFirstOrder: [ValuationType] = [
    .court, .expert, .appraiser, .settlement, .marketReference, .cadastral, .salePrice,
]

func toRubles(amount: Double, currency: String, fxRate: Double?) -> Double? {
    if currency == "RUB" { return amount }
    guard let fxRate, fxRate > 0 else { return nil }
    return amount * fxRate
}

func fundingPersonalShare(_ funding: Funding?) -> Double {
    guard let funding else { return 0 }
    let personal = n(funding.personalWife) + n(funding.personalHusband)
    let total = n(funding.common) + personal + n(funding.maternityCapital) + n(funding.loan)
    guard total > 0 else { return 0 }
    return personal / total
}

func childrenShare(asset: Asset, childrenCount: Int) -> Double {
    if let override = asset.childrenShareOverride { return override }
    let mc = n(asset.funding?.maternityCapital)
    guard mc > 0, childrenCount > 0 else { return 0 }
    let price: Double
    if let acquisition = asset.acquisitionPrice, acquisition > 0 {
        price = acquisition
    } else {
        price = n(asset.funding?.common)
            + n(asset.funding?.personalWife)
            + n(asset.funding?.personalHusband)
            + mc
            + n(asset.funding?.loan)
    }
    guard price > 0 else { return 0 }
    let members = Double(2 + childrenCount)
    return (mc / price) * (Double(childrenCount) / members)
}

func inMass(_ position: Position) -> Bool {
    position == .common || position == .partlyPersonal
}

func resolvePosition(
    asset: Asset,
    item: ScenarioAssetItem,
    scenario: Scenario,
    plaintiff: Side?,
    warnings: WarningSink
) -> Position {
    if let accepted = item.acceptedPosition { return accepted }
    let wife = asset.positions.wife.position
    let husband = asset.positions.husband.position
    if wife == .common && husband == .common { return .common }
    let personalOrExcluded: [Position] = [.personalWife, .personalHusband, .excluded]
    if wife == husband && personalOrExcluded.contains(wife) { return wife }
    if wife == husband && wife == .partlyPersonal { return .partlyPersonal }

    switch scenario.kind {
    case .claim where plaintiff != nil:
        return plaintiff == .wife ? wife : husband
    case .counterclaim where plaintiff != nil:
        return plaintiff == .wife ? husband : wife
    default:
        warnings.add("scenario.disputed_position_unresolved")
        return .disputed
    }
}

func assetValueRubles(
    asset: Asset,
    item: ScenarioAssetItem,
    scenario: Scenario,
    warnings: WarningSink,
    asOf: String?
) -> Double {
    guard let valuation = selectValuation(asset: asset, item: item, scenario: scenario, warnings: warnings) else {
        warnings.add("valuation.missing")
        return 0
    }
    guard let rubles = toRubles(amount: valuation.amount, currency: valuation.currency, fxRate: valuation.fxRate) else {
        warnings.add("valuation.fx_missing")
        return 0
    }
    if let asOf, let valuedAt = valuation.valuedAt, ISODate.isAfter(asOf, ISODate.addMonths(valuedAt, 6)) {
        warnings.add("valuation.stale")
    }
    return rubles
}

private func selectValuation(
    asset: Asset,
    item: ScenarioAssetItem,
    scenario: Scenario,
    warnings: WarningSink
) -> Valuation? {
    if let id = item.valuationId {
        if let found = asset.valuations.first(where: { $0.id == id }) { return found }
        warnings.add("valuation.missing")
        return nil
    }
    if scenario.valuationPolicy == .perItem {
        warnings.add("asset.no_valuation_selected")
        return nil
    }
    if scenario.valuationPolicy == .blended {
        let wife = latestOfType(asset.valuations, .partyWife)
        let husband = latestOfType(asset.valuations, .partyHusband)
        if let wife, let husband {
            let w = toRubles(amount: wife.amount, currency: wife.currency, fxRate: wife.fxRate)
            let h = toRubles(amount: husband.amount, currency: husband.currency, fxRate: husband.fxRate)
            if let w, let h {
                return Valuation(
                    id: "\(asset.id)-blended",
                    type: .settlement,
                    amount: (w + h) / 2,
                    currency: "RUB",
                    fxRate: nil,
                    fxDate: nil,
                    valuedAt: nil,
                    source: nil,
                    acceptedByCourt: nil,
                    note: nil
                )
            }
        }
        return wife ?? husband ?? pickCourtFirst(asset)
    }
    if scenario.valuationPolicy == .wife {
        return latestOfType(asset.valuations, .partyWife) ?? pickCourtFirst(asset)
    }
    if scenario.valuationPolicy == .husband {
        return latestOfType(asset.valuations, .partyHusband) ?? pickCourtFirst(asset)
    }
    return pickCourtFirst(asset)
}

private func latestOfType(_ valuations: [Valuation], _ type: ValuationType) -> Valuation? {
    let matches = valuations.filter { $0.type == type }
    guard let first = matches.first else { return nil }
    return matches.dropFirst().reduce(first) { best, current in
        if best.valuedAt == nil { return current }
        if current.valuedAt == nil { return best }
        return current.valuedAt! > best.valuedAt! ? current : best
    }
}

private func pickCourtFirst(_ asset: Asset, prefer: ValuationType? = nil) -> Valuation? {
    if let accepted = asset.valuations.first(where: { $0.type == .court && $0.acceptedByCourt == true }) {
        return accepted
    }
    var order = courtFirstOrder
    if let prefer {
        order.removeAll { $0 == prefer }
        order.insert(prefer, at: 0)
    }
    for type in order {
        if let found = latestOfType(asset.valuations, type) { return found }
    }
    return latestOfType(asset.valuations, .partyWife) ?? latestOfType(asset.valuations, .partyHusband)
}
