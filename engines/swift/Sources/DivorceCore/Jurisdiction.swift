public let magistrateClaimLimit = 50_000.0

public func jurisdiction(_ claimPrice: Double) -> Jurisdiction {
    claimPrice <= magistrateClaimLimit ? .magistrate : .district
}
