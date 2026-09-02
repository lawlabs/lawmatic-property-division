import DivorceCore
import XCTest

final class VectorTests: XCTestCase {
    func testAllVectors() throws {
        let vectors = try loadVectors()
        XCTAssertFalse(vectors.isEmpty, "в vectors/ нет JSON-файлов")

        for vector in vectors {
            do {
                try assertVector(vector)
            } catch {
                XCTFail("\(vector.id): \(error)")
            }
        }
    }
}

final class CourtFeeExtraTests: XCTestCase {
    func testRejectsScaleBefore2024_09_09() {
        XCTAssertThrowsError(
            try courtFee(CourtFeeInput(claimPrice: 100_000, filedAt: "2024-09-08"))
        ) { error in
            XCTAssertEqual(error as? EngineError, .feeScaleNotSupported)
            XCTAssertEqual((error as? EngineError)?.description, "fee.scale_not_supported")
        }
    }

    func testNotaryAgreementFee() {
        XCTAssertEqual(notaryAgreementFee(10_000), 300)
        XCTAssertEqual(notaryAgreementFee(2_000_000), 10_000)
        XCTAssertEqual(notaryAgreementFee(10_000_000), 20_000)
    }
}

// MARK: - Прогон вектора

private func assertVector(_ vector: VectorFile) throws {
    switch vector.kind {
    case "court_fee":
        let result = try courtFee(vector.input.asCourtFeeInput())
        expectMoney(result.courtFee, vector.expected.courtFee, "\(vector.id) court_fee")
        if let expectedRows = vector.expected.breakdown {
            XCTAssertEqual(
                result.breakdown.map(\.item),
                expectedRows.map(\.item),
                "\(vector.id) breakdown items"
            )
            for (index, row) in expectedRows.enumerated() {
                expectMoney(result.breakdown[index].amount, row.amount, "\(vector.id) breakdown.\(row.item)")
            }
        }

    case "division", "claim_price", "warnings":
        guard let caseDoc = vector.input.maritalCase, let scenarioId = vector.input.scenarioId else {
            return XCTFail("\(vector.id): нет input.case / scenario_id")
        }
        let result = try divide(caseDoc, scenarioId: scenarioId)
        let expected = vector.expected
        if let mass = expected.mass {
            expectMoney(result.mass.assetsCommon, mass.assetsCommon, "\(vector.id) mass.assets_common")
            expectMoney(result.mass.liabilitiesCommon, mass.liabilitiesCommon, "\(vector.id) mass.liabilities_common")
            expectMoney(result.mass.net, mass.net, "\(vector.id) mass.net")
        }
        if let ideal = expected.ideal {
            expectMoney(result.ideal.wife, ideal.wife, "\(vector.id) ideal.wife")
            expectMoney(result.ideal.husband, ideal.husband, "\(vector.id) ideal.husband")
        }
        if let received = expected.received {
            expectMoney(result.received.assets.wife, received.assets.wife, "\(vector.id) received.assets.wife")
            expectMoney(result.received.assets.husband, received.assets.husband, "\(vector.id) received.assets.husband")
            expectMoney(result.received.liabilities.wife, received.liabilities.wife, "\(vector.id) received.liabilities.wife")
            expectMoney(result.received.liabilities.husband, received.liabilities.husband, "\(vector.id) received.liabilities.husband")
            expectMoney(result.received.net.wife, received.net.wife, "\(vector.id) received.net.wife")
            expectMoney(result.received.net.husband, received.net.husband, "\(vector.id) received.net.husband")
        }
        if let unallocated = expected.unallocated {
            expectMoney(result.unallocated, unallocated, "\(vector.id) unallocated")
        }
        if let compensation = expected.compensation {
            XCTAssertEqual(result.compensation.from?.rawValue, compensation.from, "\(vector.id) compensation.from")
            XCTAssertEqual(result.compensation.to?.rawValue, compensation.to, "\(vector.id) compensation.to")
            expectMoney(result.compensation.amount, compensation.amount, "\(vector.id) compensation.amount")
        }
        if let claimPrice = expected.claimPrice {
            XCTAssertNotNil(result.claimPrice, "\(vector.id) claim_price")
            expectMoney(result.claimPrice ?? 0, claimPrice, "\(vector.id) claim_price")
        }
        if let fee = expected.courtFee {
            XCTAssertNotNil(result.courtFee, "\(vector.id) court_fee")
            expectMoney(result.courtFee ?? 0, fee, "\(vector.id) court_fee")
        }
        if let court = expected.jurisdiction {
            XCTAssertEqual(result.jurisdiction?.rawValue, court, "\(vector.id) jurisdiction")
        }
        if let warnings = expected.warnings {
            for code in warnings {
                XCTAssertTrue(
                    result.warnings.contains(code),
                    "\(vector.id): нет предупреждения \(code): \(result.warnings.joined(separator: ", "))"
                )
            }
        }

    case "jurisdiction":
        guard let price = vector.input.claimPrice else {
            return XCTFail("\(vector.id): нет claim_price")
        }
        XCTAssertEqual(jurisdiction(price).rawValue, vector.expected.jurisdiction, vector.id)

    case "deadlines":
        guard let caseDoc = vector.input.maritalCase, let asOf = vector.input.asOf else {
            return XCTFail("\(vector.id): нет input.case / as_of")
        }
        let items = deadlines(caseDoc, asOf: asOf)
        for row in vector.expected.items ?? [] {
            guard let found = items.first(where: { $0.code == row.code }) else {
                XCTFail("\(vector.id): нет срока \(row.code)")
                continue
            }
            if let date = row.date {
                XCTAssertEqual(found.date, date, "\(vector.id) \(row.code).date")
            }
            if let level = row.level {
                XCTAssertEqual(found.level?.rawValue, level, "\(vector.id) \(row.code).level")
            }
        }

    default:
        XCTFail("\(vector.id): неизвестный kind \(vector.kind)")
    }
}

private func expectMoney(_ actual: Double?, _ expected: Double?, _ label: String) {
    guard let actual, let expected else {
        XCTFail("\(label): actual=\(String(describing: actual)) expected=\(String(describing: expected))")
        return
    }
    XCTAssertTrue(almostEqual(actual, expected), "\(label): \(actual) ≠ \(expected)")
}

// MARK: - Загрузка векторов

private struct VectorFile: Decodable {
    let id: String
    let kind: String
    let input: VectorInput
    let expected: VectorExpected
}

private struct VectorInput: Decodable {
    let scenarioId: String?
    let asOf: String?
    let maritalCase: MaritalPropertyCase?
    let claimPrice: Double?
    let filedAt: String?
    let plaintiffType: PlaintiffType?
    let divorceClaimed: Bool?
    let priorRightEstablished: Bool?
    let injunctionRequested: Bool?
    let stage: CourtStage?

    enum CodingKeys: String, CodingKey {
        case scenarioId
        case asOf
        case maritalCase = "case"
        case claimPrice
        case filedAt
        case plaintiffType
        case divorceClaimed
        case priorRightEstablished
        case injunctionRequested
        case stage
    }

    func asCourtFeeInput() -> CourtFeeInput {
        CourtFeeInput(
            claimPrice: claimPrice ?? 0,
            filedAt: filedAt,
            plaintiffType: plaintiffType,
            divorceClaimed: divorceClaimed,
            priorRightEstablished: priorRightEstablished,
            injunctionRequested: injunctionRequested,
            stage: stage
        )
    }
}

private struct VectorExpected: Decodable {
    let courtFee: Double?
    let breakdown: [BreakdownExpected]?
    let mass: MassExpected?
    let ideal: SideAmounts?
    let received: ReceivedExpected?
    let unallocated: Double?
    let compensation: CompensationExpected?
    let claimPrice: Double?
    let jurisdiction: String?
    let warnings: [String]?
    let items: [DeadlineExpected]?
}

private struct BreakdownExpected: Decodable {
    let item: String
    let amount: Double
}

private struct MassExpected: Decodable {
    let assetsCommon: Double
    let liabilitiesCommon: Double
    let net: Double
}

private struct ReceivedExpected: Decodable {
    let assets: SideAmounts
    let liabilities: SideAmounts
    let net: SideAmounts
}

private struct CompensationExpected: Decodable {
    let from: String?
    let to: String?
    let amount: Double
}

private struct DeadlineExpected: Decodable {
    let code: String
    let date: String?
    let level: String?
}

private func loadVectors() throws -> [VectorFile] {
    let root = vectorsRoot()
    let decoder = JSONCoding.decoder()
    var found: [VectorFile] = []
    let categories = try FileManager.default.contentsOfDirectory(at: root, includingPropertiesForKeys: [.isDirectoryKey])
    for category in categories {
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: category.path, isDirectory: &isDirectory), isDirectory.boolValue else {
            continue
        }
        let files = try FileManager.default.contentsOfDirectory(at: category, includingPropertiesForKeys: nil)
        for file in files where file.pathExtension == "json" {
            let data = try Data(contentsOf: file)
            do {
                found.append(try decoder.decode(VectorFile.self, from: data))
            } catch {
                throw VectorLoadError(path: file.path, underlying: error)
            }
        }
    }
    return found.sorted { $0.id < $1.id }
}

private struct VectorLoadError: Error, CustomStringConvertible {
    let path: String
    let underlying: Error
    var description: String { "не разобрать \(path): \(underlying)" }
}

private func vectorsRoot() -> URL {
    URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("vectors")
}
