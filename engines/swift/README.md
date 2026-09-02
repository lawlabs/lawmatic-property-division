# DivorceCore

Swift-пакет с тем же калькулятором, что `@lawlabs/marital-property`: чистые функции над JSON-документом дела, без UI и без сети.

```swift
import DivorceCore

let caseDoc = try JSONCoding.decoder().decode(MaritalPropertyCase.self, from: data)
let result = try divide(caseDoc, scenarioId: "s-claim")
// result.mass, result.compensation, result.claimPrice, result.courtFee, result.warnings
```

Публичные функции совпадают с TypeScript: `divide`, `claimPrice`, `warningsFor`, `courtFee`, `propertyFeeByScale`, `notaryAgreementFee`, `jurisdiction`, `deadlines`.

```bash
swift test --package-path engines/swift
```

Тесты читают `../../vectors` и обязаны давать тот же результат, что `npm test --prefix engines/ts` (допуск 0,01 ₽).
