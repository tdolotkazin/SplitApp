import Foundation
import NaturalLanguage

/// Parses raw OCR lines from a receipt into structured items.
///
/// Handles two common receipt layouts:
/// A) Inline:  "Молоко 89.90"  — name and price on the same line
/// B) Columnar: Vision OCR reads all names first, then all prices.
///              Uses a FIFO name queue: each name line is enqueued,
///              each standalone price dequeues the oldest name.
final class ReceiptParserService {

    // MARK: - Configuration

    private let minLettersInName = 4

    private static let singleWordServiceTokens: Set<String> = [
        "цена", "скидка", "скидкой", "итого", "итог", "сумма", "оплата",
        "наличными", "безналичными", "сдача", "приход", "расход",
        "блюдо", "всего", "количество", "наименование",
        "товар", "товары", "услуга",
        // Common store/chain names that appear as standalone header lines
        "пятерочка", "пятёрочка", "агроторг", "магнит", "дикси",
        "перекрёсток", "перекресток", "лента", "ашан", "метро"
    ]

    private static let serviceKeywords: Set<String> = [
        "итого", "итог:", "total", "наличными", "безналичными",
        "visa", "mastercard", "скидка:", "бонус", "баллы",
        "ндс", "сумма ндс", "nds", "vat",
        "кассовый чек", "чек №", "чек #", "спасибо",
        "инн:", "кпп:", "огрн",
        "фискальный", "фн:", "фд:", "фп:", "офд",
        "приход", "расход", "возврат прихода", "возврат расхода",
        "www.", "http", ".ru", ".com", "receipt", "cashier",
        "подытог", "округление", "принято:", "сдача:",
        "касса:", "кассир:", "смена:", "чек:",
        "ооо ", "ип ", "оао ", "зао ", "пао ", "ао ",
        "цена со", "кол-во", "скидкой", "б: сумма", "а: сумма",
        "место расчетов", "сайт фнс", "сно:", "код:", "зн ккт", "рн ккт",
        // Loyalty card / cashier name lines
        "карта:", "карта лояльности", "держатель",
        // Restaurant-specific headers
        "официант", "столик", "стол №", "заказ №", "счёт №", "счет №",
        "наименование", "количество", "блюдо", "позиция",
        "всего:", "итого:", "обслуживание", "сервисный сбор",
        // Promo/footer text
        "сканируй", "чаевые", "qr код", "qr-код", "оставить отзыв",
        "спасибо за", "приятного аппетита", "ждём вас",
        // Payment method words
        "электронными", "округлени",
        // Store/chain names in multi-word context
        "агроторг", "торговый зал",
        // Cashier name line without colon
        "кассир",
        // Gas station / fiscal device identifiers
        "азк №", "азк no", "азс №", "азс no", "эн ккт", "зн ккт", "рн ккт",
        "нефтепродукт", "роснефть", "лукойл", "газпром"
    ]

    private static let addressKeywords: Set<String> = [
        "обл.,", "область", "район", "ул.", "улица",
        "проспект", "корп.", "офис", "этаж",
        " д.", "д. ", ". д."
    ]

    private static let quantityUnits: Set<String> = [
        "шт", "кг", " x ", " х ", " × "
    ]

    private let tokenizer = NLTokenizer(unit: .word)
    private let languageRecognizer = NLLanguageRecognizer()

    // MARK: - Public

    func parse(lines: [String]) -> [ReceiptItem] {
        let cleaned = lines.map { $0.trimmingCharacters(in: .whitespaces) }

        var items: [ReceiptItem] = []

        // FIFO queue: each entry is one or more lines forming a single product name.
        // Multi-line names are grouped when consecutive name-only lines look like
        // a continuation (both truncated — end without a price).
        // Each name line gets its own slot in the queue.
        // Prices dequeue from the front — preserving order.
        var nameQueue: [String] = []

        for line in cleaned {
            guard !line.isEmpty else { continue }

            // Running-total echo lines: "=89.90"
            if line.hasPrefix("=") { continue }

            if isServiceLine(line) || isAddressLine(line) { continue }
            if isMaskedLine(line) { continue }
            if isPurelyNumeric(line) { continue }
            if isQuantityMarker(line) { continue }
            if isQuantityLine(line) { continue }
            if isTaxClassMarker(line) { continue }
            if isDuplicatePriceMark(line) { continue }
            if isPriceTimesQuantity(line) { continue }
            if isPercentageLine(line) { continue }
            if isAddressWithNumber(line) { continue }
            if isOCRNoise(line) { continue }
            if isStoreNumberLine(line) { continue }
            if isPersonName(line) { continue }

            // ── Price detection ───────────────────────────────────────────

            if let (namePart, amount) = findPriceAtEnd(of: line) {
                // Name is on the same line — take inline name, ignore queue
                let nameParts = namePart.isEmpty
                    ? (nameQueue.isEmpty ? [] : [nameQueue.removeFirst()])
                    : [namePart]
                if let item = makeItem(nameParts: nameParts, amount: amount) {
                    items.append(item)
                    print("[Parser] ✓ \(item.name) — \(item.amount)")
                } else {
                    print("[Parser] ✗ rejected name=\(nameParts) amount=\(amount)")
                }
                continue
            }

            if let amount = findStandalonePrice(in: line) {
                let nameParts = nameQueue.isEmpty ? [] : [nameQueue.removeFirst()]
                if let item = makeItem(nameParts: nameParts, amount: amount) {
                    items.append(item)
                    print("[Parser] ✓ \(item.name) — \(item.amount)")
                } else {
                    print("[Parser] ✗ rejected name=\(nameParts) amount=\(amount)")
                }
                continue
            }

            // ── Name line — enqueue ───────────────────────────────────────
            let enqueueLine = stripArticleNumber(from: line)
            let letters = enqueueLine.unicodeScalars.filter { CharacterSet.letters.contains($0) }
            guard letters.count >= minLettersInName else { continue }

            // Merge if:
            // - previous entry is a single word ("Пакет" + "ПЯТЕРОЧКА 65х40см")
            // - previous line ends with preposition/conjunction ("Куриная печень с")
            // - OR current line starts with conjunction ("и малосол форелью")
            let prevWordCount = nameQueue.last?
                .components(separatedBy: .whitespaces).filter({ !$0.isEmpty }).count ?? 0
            let shouldMerge = !nameQueue.isEmpty && (
                prevWordCount == 1 ||
                (prevWordCount >= 3 &&
                 (isContinuation(after: nameQueue.last!) || isContinuationStart(of: enqueueLine)))
            )

            if shouldMerge {
                nameQueue[nameQueue.count - 1] += " " + enqueueLine
                print("[Parser] merged: \(nameQueue.last!)")
            } else {
                nameQueue.append(enqueueLine)
                print("[Parser] queued: \(enqueueLine)")
            }
        }

        print("[Parser] Total items: \(items.count)")
        return items
    }

    // MARK: - Line Classification

    private func isServiceLine(_ line: String) -> Bool {
        let lower = line.lowercased().trimmingCharacters(in: .whitespaces)
        // Exact match for single service words
        if Self.singleWordServiceTokens.contains(lower) { return true }
        // Lines containing ":" are field labels (payment method, totals, etc.)
        // e.g. "ОКРУГ ЛЕННЕ:", "ЭЛЕКТРОННЫМИ:", "CHO: ОСН"
        if lower.contains(":") { return true }
        return Self.serviceKeywords.contains(where: { lower.contains($0) })
    }

    private func isAddressLine(_ line: String) -> Bool {
        let lower = line.lowercased()
        return Self.addressKeywords.contains(where: { lower.contains($0) })
    }

    private func isMaskedLine(_ line: String) -> Bool {
        let nonSpace = line.unicodeScalars.filter { !CharacterSet.whitespaces.contains($0) }
        guard nonSpace.count > 3 else { return false }
        return nonSpace.allSatisfy { !CharacterSet.alphanumerics.contains($0) }
    }

    private func isPurelyNumeric(_ line: String) -> Bool {
        let nonSpace = line.unicodeScalars.filter { !CharacterSet.whitespaces.contains($0) }
        guard nonSpace.count > 3 else { return false }
        return nonSpace.allSatisfy { CharacterSet.decimalDigits.contains($0) }
    }

    private func isQuantityLine(_ line: String) -> Bool {
        guard line.first?.isNumber == true else { return false }
        let lower = line.lowercased()
        return Self.quantityUnits.contains(where: { lower.contains($0) })
    }

    private func isTaxClassMarker(_ line: String) -> Bool {
        let t = line.trimmingCharacters(in: .whitespaces)
        return t.count == 1 && t.first?.isLetter == true
    }

    /// *1, *2, *3 — quantity markers (max 2 digits after asterisk).
    /// *3691951 ТОВАР — article number prefix, NOT a quantity marker.
    private func isQuantityMarker(_ line: String) -> Bool {
        let t = line.trimmingCharacters(in: .whitespaces)
        guard t.hasPrefix("*") else { return false }
        let after = String(t.dropFirst())
        // Only treat as quantity marker if it's 1-2 digits with nothing else
        return after.count <= 2 && after.allSatisfy { $0.isNumber }
    }

    /// OCR noise from QR codes, barcodes, or garbled text.
    private func isOCRNoise(_ line: String) -> Bool {
        let tokens = line.components(separatedBy: .whitespaces).filter { !$0.isEmpty }

        // Single token starting with a non-alphanumeric char: "•ЗшТ", "·ABC"
        if tokens.count == 1, let first = tokens[0].unicodeScalars.first,
           !CharacterSet.alphanumerics.contains(first) {
            return true
        }

        guard tokens.count >= 2 else { return false }

        // More than 1/3 of tokens are single chars — QR/barcode noise
        let singleCharCount = tokens.filter { $0.count == 1 }.count
        if singleCharCount * 3 > tokens.count { return true }

        // Short mixed tokens with digits and latin caps — QR noise pattern like "B4", "J0", "M0"
        let noisyTokenCount = tokens.filter { t in
            t.count <= 3 &&
            t.unicodeScalars.contains(where: { CharacterSet.decimalDigits.contains($0) }) &&
            t.unicodeScalars.contains(where: { CharacterSet.uppercaseLetters.contains($0) })
        }.count
        if tokens.count >= 4 && noisyTokenCount * 2 >= tokens.count { return true }

        // High ratio of non-alphanumeric characters
        let total = line.unicodeScalars.filter { !CharacterSet.whitespaces.contains($0) }
        let alphanumeric = total.filter { CharacterSet.alphanumerics.contains($0) }
        if total.count > 4 && alphanumeric.count * 3 < total.count { return true }

        return false
    }

    private static let continuationWords: Set<String> = [
        "с", "со", "и", "из", "для", "в", "на", "к", "по", "от",
        "или", "без", "под", "над", "за", "при", "до", "а"
    ]

    /// Previous line ends with preposition → next line is continuation.
    private func isContinuation(after line: String) -> Bool {
        let lastWord = line.components(separatedBy: .whitespaces).last?.lowercased() ?? ""
        return Self.continuationWords.contains(lastWord)
    }

    /// Current line starts with conjunction → it continues the previous line.
    private func isContinuationStart(of line: String) -> Bool {
        let firstWord = line.components(separatedBy: .whitespaces).first?.lowercased() ?? ""
        return Self.continuationWords.contains(firstWord)
    }

    /// Lines that are a store name/number prefix: "5 Пятёрочка", "3221-Пятерочка"
    /// Pattern: starts with 1-4 digits optionally followed by dash, then store name.
    private func isStoreNumberLine(_ line: String) -> Bool {
        let t = line.trimmingCharacters(in: .whitespaces)
        let parts = t.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        guard parts.count >= 2, let first = parts.first else { return false }
        let digits = first.replacingOccurrences(of: "-", with: "")
        return digits.count <= 4 && digits.allSatisfy({ $0.isNumber })
    }

    /// Lines that look like a person name (cashier, loyalty card holder).
    /// Heuristic: 2 tokens, both start with uppercase letter, second may be partial (< 5 chars).
    private func isPersonName(_ line: String) -> Bool {
        let tokens = line.trimmingCharacters(in: .whitespaces)
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
        guard tokens.count == 2 else { return false }
        // Both tokens must start with an uppercase letter and contain only letters
        return tokens.allSatisfy { t in
            guard let first = t.unicodeScalars.first,
                  CharacterSet.uppercaseLetters.contains(first) else { return false }
            return t.unicodeScalars.allSatisfy { CharacterSet.letters.contains($0) }
        }
    }

    /// Lines like "74.90 *1.514" — price × weight/quantity breakdown.
    private func isPriceTimesQuantity(_ line: String) -> Bool {
        let parts = line.trimmingCharacters(in: .whitespaces)
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
        guard parts.count == 2 else { return false }
        // First token is a price, second starts with * followed by a number
        guard parsePrice(from: parts[0]) != nil else { return false }
        let second = parts[1]
        guard second.hasPrefix("*") else { return false }
        let digits = String(second.dropFirst())
        return !digits.isEmpty && digits.replacingOccurrences(of: ".", with: "")
                                        .replacingOccurrences(of: ",", with: "")
                                        .allSatisfy({ $0.isNumber })
    }

    /// Lines like "18.00%", "10.00%" — VAT rate lines.
    private func isPercentageLine(_ line: String) -> Bool {
        return line.trimmingCharacters(in: .whitespaces).hasSuffix("%")
    }

    /// Lines that look like a street address ending with a building number like "68А1", "13 В".
    /// Excludes weight/volume suffixes common in product names: "600г", "220г", "1кг", "500мл".
    private func isAddressWithNumber(_ line: String) -> Bool {
        let t = line.trimmingCharacters(in: .whitespaces)
        guard t.count > 5 else { return false }
        let lastToken = (t.components(separatedBy: .whitespaces).last ?? "").lowercased()
        let digits = lastToken.unicodeScalars.filter { CharacterSet.decimalDigits.contains($0) }
        let letters = lastToken.unicodeScalars.filter { CharacterSet.letters.contains($0) }
        guard digits.count > 0 && letters.count > 0 && lastToken.count <= 6 else { return false }

        // Exclude measurement suffixes — these are product weights, not building numbers
        let measureSuffixes = ["г", "кг", "мл", "л", "гр", "oz", "ml", "kg"]
        if measureSuffixes.contains(where: { lastToken.hasSuffix($0) }) { return false }

        return true
    }

    private func isDuplicatePriceMark(_ line: String) -> Bool {
        let parts = line.trimmingCharacters(in: .whitespaces)
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
        guard parts.count >= 2, parts.last!.allSatisfy({ $0 == "*" }) else { return false }
        return parsePrice(from: parts.dropLast().joined()) != nil
    }

    // MARK: - Price Detection

    private func findPriceAtEnd(of line: String) -> (namePart: String, amount: Decimal)? {
        let stripped = stripCurrencySuffix(from: line)
        let parts = stripped.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        guard parts.count >= 2 else { return nil }

        if let amount = parsePrice(from: parts.last!) {
            let namePart = parts.dropLast(1).joined(separator: " ")
            return (namePart.trimmingCharacters(in: .whitespaces), amount)
        }

        let lastTwo = parts.suffix(2).joined()
        if let amount = parsePrice(from: lastTwo) {
            let namePart = parts.dropLast(2).joined(separator: " ")
            return (namePart.trimmingCharacters(in: .whitespaces), amount)
        }

        return nil
    }

    private func findStandalonePrice(in line: String) -> Decimal? {
        var stripped = stripCurrencySuffix(from: line)

        // Strip trailing single-letter tax class: "44.99 А" → "44.99"
        let parts = stripped.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        if parts.count == 2,
           let last = parts.last,
           last.count == 1, last.first?.isLetter == true {
            stripped = parts[0]
        }

        let compact = stripped
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "\u{00A0}", with: "")
        guard !compact.isEmpty else { return nil }

        let allowed = CharacterSet.decimalDigits.union(CharacterSet(charactersIn: ".,"))
        guard compact.unicodeScalars.allSatisfy({ allowed.contains($0) }) else { return nil }
        return parsePrice(from: compact)
    }

    private func parsePrice(from token: String) -> Decimal? {
        var token = token
        // Dash as decimal separator: "49-00" → "49.00" (АЗС-style receipts)
        if !token.contains(".") && !token.contains(",") {
            let dashParts = token.components(separatedBy: "-")
            if dashParts.count == 2,
               !dashParts[0].isEmpty, dashParts[0].allSatisfy({ $0.isNumber }),
               dashParts[1].count <= 2, dashParts[1].allSatisfy({ $0.isNumber }) {
                token = dashParts.joined(separator: ".")
            }
        }
        let normalized = token
            .replacingOccurrences(of: ",", with: ".")
            .replacingOccurrences(of: "\u{00A0}", with: "")

        let parts = normalized.components(separatedBy: ".")
        guard parts.count == 2,
              parts[1].count <= 2,
              parts[1].allSatisfy({ $0.isNumber }),
              !parts[0].isEmpty,
              parts[0].allSatisfy({ $0.isNumber }),
              parts[0].count <= 6 else { return nil }

        guard let amount = Decimal(string: normalized), amount > 0 else { return nil }

        // Reject suspiciously small amounts — likely quantity column (1, 2, 3...)
        // Real prices for any product/dish are at least 5 units of currency
        guard amount >= 5 else { return nil }

        return amount
    }

    /// Removes leading article number from product lines.
    /// "*3691951 ФРЕГ Скумбрия" → "ФРЕГ Скумбрия"
    /// "3682543 Хлеб КОРЕНСКОЙ" → "Хлеб КОРЕНСКОЙ"
    private func stripArticleNumber(from line: String) -> String {
        var t = line.trimmingCharacters(in: .whitespaces)
        // Remove leading asterisk
        if t.hasPrefix("*") { t = String(t.dropFirst()) }
        let parts = t.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        guard let first = parts.first else { return t }
        // If the first token is purely numeric (article number) — drop it
        if first.allSatisfy({ $0.isNumber }) && first.count >= 4 {
            return parts.dropFirst().joined(separator: " ")
        }
        return t
    }

    private func stripCurrencySuffix(from line: String) -> String {
        var result = line
        for suffix in ["руб.", "руб", " р.", " р", "rub", "RUB", "₽"] {
            if result.hasSuffix(suffix) {
                result = String(result.dropLast(suffix.count))
            }
        }
        return result.trimmingCharacters(in: .whitespaces)
    }

    // MARK: - Name Construction

    private func makeItem(nameParts: [String], amount: Decimal) -> ReceiptItem? {
        let raw = nameParts.joined(separator: " ")
        let name = extractMeaningfulWords(from: raw)
        let letterCount = name.unicodeScalars.filter { CharacterSet.letters.contains($0) }.count
        guard letterCount >= minLettersInName else { return nil }
        return ReceiptItem(name: name, amount: amount)
    }

    private func extractMeaningfulWords(from text: String) -> String {
        tokenizer.string = text
        languageRecognizer.reset()
        languageRecognizer.processString(text)
        if let lang = languageRecognizer.dominantLanguage {
            tokenizer.setLanguage(lang)
        }

        var words: [String] = []
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
            let token = String(text[range])
            if token.unicodeScalars.contains(where: { CharacterSet.letters.contains($0) }) {
                words.append(token)
            }
            return true
        }
        return words.joined(separator: " ")
    }
}
