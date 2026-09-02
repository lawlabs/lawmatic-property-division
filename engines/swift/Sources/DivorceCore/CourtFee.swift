public let feeScaleFrom = "2024-09-09"

private let scaleBasis = "пп. 1 п. 1 ст. 333.19 НК РФ (ред. ФЗ от 08.08.2024 № 259-ФЗ)"

public func propertyFeeByScale(_ price: Double) -> Double {
    if price <= 100_000 { return 4_000 }
    if price <= 300_000 { return 4_000 + 0.03 * (price - 100_000) }
    if price <= 500_000 { return 10_000 + 0.025 * (price - 300_000) }
    if price <= 1_000_000 { return 15_000 + 0.02 * (price - 500_000) }
    if price <= 3_000_000 { return 25_000 + 0.01 * (price - 1_000_000) }
    if price <= 8_000_000 { return 45_000 + 0.007 * (price - 3_000_000) }
    if price <= 24_000_000 { return 80_000 + 0.0035 * (price - 8_000_000) }
    if price <= 50_000_000 { return 136_000 + 0.003 * (price - 24_000_000) }
    if price <= 100_000_000 { return 214_000 + 0.002 * (price - 50_000_000) }
    return min(314_000 + 0.0015 * (price - 100_000_000), 900_000)
}

public func courtFee(_ input: CourtFeeInput) throws -> CourtFeeResult {
    var warnings: [String] = []
    var breakdown: [CourtFeeBreakdownItem] = []
    let type = input.plaintiffType ?? .individual
    let stage = input.stage ?? .firstInstance

    if let filed = input.filedAt, filed < feeScaleFrom {
        throw EngineError.feeScaleNotSupported
    }
    if type == .organization {
        warnings.append("fee.organization_scale_not_implemented")
    }

    switch stage {
    case .appeal:
        breakdown.append(.init(item: "appeal", amount: 3_000, basis: "ст. 333.19 НК РФ — апелляционная жалоба, 3 000 ₽"))
    case .cassation:
        breakdown.append(.init(item: "cassation", amount: 5_000, basis: "ст. 333.19 НК РФ — кассационная жалоба, 5 000 ₽"))
    case .supremeCourt:
        breakdown.append(.init(item: "supreme_court", amount: 7_000, basis: "ст. 333.19 НК РФ — жалоба в Верховный Суд РФ, 7 000 ₽"))
    case .firstInstance:
        if input.priorRightEstablished == true {
            breakdown.append(.init(
                item: "property_claim_fixed",
                amount: 3_000,
                basis: "пп. 3 п. 1 ст. 333.20 → пп. 3 п. 1 ст. 333.19 НК РФ"
            ))
        } else {
            breakdown.append(.init(
                item: "property_claim",
                amount: roundFeeToRuble(propertyFeeByScale(input.claimPrice)),
                basis: scaleBasis
            ))
        }
    }

    if input.divorceClaimed == true {
        breakdown.append(.init(item: "divorce", amount: 5_000, basis: "пп. 5 п. 1 ст. 333.19 НК РФ"))
    }
    if input.injunctionRequested == true {
        breakdown.append(.init(item: "injunction", amount: 10_000, basis: "ст. 333.19 НК РФ — заявление об обеспечении иска"))
    }

    return CourtFeeResult(
        courtFee: breakdown.reduce(0) { $0 + $1.amount },
        breakdown: breakdown,
        warnings: warnings
    )
}

public func notaryAgreementFee(_ amount: Double) -> Double {
    min(20_000, max(300, roundFeeToRuble(amount * 0.005)))
}
