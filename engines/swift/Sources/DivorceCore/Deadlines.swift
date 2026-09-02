public func deadlines(_ caseDoc: MaritalPropertyCase, asOf: String) -> [DeadlineItem] {
    var items: [DeadlineItem] = []
    let facts = caseDoc.facts

    var limitation = facts.limitation?.overrideDeadline
    if limitation == nil, let known = facts.limitation?.violationKnownAt {
        limitation = ISODate.max(ISODate.addYears(known, 3), facts.dissolvedAt)
    }
    items.append(deadlineItem(code: "deadline.limitation", date: limitation, asOf: asOf))

    for asset in caseDoc.assets {
        if let at = asset.disposed?.at, asset.disposed?.spouseConsent == false {
            items.append(deadlineItem(code: "deadline.disposal_challenge", date: ISODate.addYears(at, 1), asOf: asOf))
        }
    }

    if facts.contract?.exists == true {
        items.append(deadlineItem(code: "deadline.contract_challenge", date: nil, asOf: asOf))
    }

    let finalForm = caseDoc.courtCase?.decision?.finalFormAt
    items.append(deadlineItem(
        code: "deadline.appeal",
        date: finalForm.map { ISODate.addMonths($0, 1) },
        asOf: asOf
    ))
    items.append(deadlineItem(
        code: "deadline.cassation",
        date: finalForm.map { ISODate.addMonths($0, 3) },
        asOf: asOf
    ))
    return items
}

private func deadlineLevel(_ daysLeft: Int) -> DeadlineLevel {
    if daysLeft < 0 { return .expired }
    if daysLeft <= 30 { return .critical }
    if daysLeft <= 90 { return .warning }
    return .info
}

private func deadlineItem(code: String, date: String?, asOf: String) -> DeadlineItem {
    guard let date else {
        return DeadlineItem(code: code, date: nil, level: nil, daysLeft: nil)
    }
    let days = ISODate.daysBetween(asOf, date)
    return DeadlineItem(code: code, date: date, level: deadlineLevel(days), daysLeft: days)
}
