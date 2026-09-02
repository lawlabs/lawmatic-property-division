# `@lawlabs/marital-property`

Референсный движок TypeScript по [SPEC.md](../../SPEC.md) § 4. Чистые функции, без UI и сети.

```ts
import { divide, courtFee, jurisdiction, deadlines } from "@lawlabs/marital-property";

const result = divide(caseDoc, "s-claim");
// result.mass, result.compensation, result.claim_price, result.court_fee, result.warnings
```

Тесты читают все файлы из `../../vectors/` и сверяют ожидаемые числа с допуском 0,01 ₽.

```bash
npm install
npm test
```

Пакет пока подключается по пути к репозиторию (git / file). Публикация в npm — после 2.0.0-beta.
