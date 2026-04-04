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
        "блюдо", "всего", "количество", "наименование", "товар", "товары", "услуга",
        "пятерочка", "пятёрочка", "агроторг", "магнит", "дикси",
        "перекрёсток", "перекресток", "лента", "ашан", "метро"
    ]

    private static let serviceKeywords: Set<String> = [
        "итого", "итог:", "total", "наличными", "безналичными",
        "visa", "mastercard", "скидка:", "бонус", "баллы",
        "ндс", "сумма ндс", "nds", "vat", "кассовый чек", "чек №", "чек #", "спасибо",
        "инн:", "кпп:", "огрн", "фискальный", "фн:", "фд:", "фп:", "офд",
        "приход", "расход", "возврат прихода", "возврат расхода",
        "www.", "http", ".ru", ".com", "receipt", "cashier",
        "подытог", "округление", "принято:", "сдача:",
        "касса:", "кассир:", "смена:", "чек:",
        "ооо ", "ип ", "оао ", "зао ", "пао ", "ао ",
        "цена со", "кол-во", "скидкой", "б: сумма", "а: сумма",
        "место расчетов", "сайт фнс", "сно:", "код:", "зн ккт", "рн ккт",
        "карта:", "карта лояльности", "держатель",
        "официант", "столик", "стол №", "заказ №", "счёт №", "счет №",
        "наименование", "количество", "блюдо", "позиция",
        "всего:", "итого:", "обслуживание", "сервисный сбор",
        "сканируй", "чаевые", "qr код", "qr-код", "оставить отзыв",
        "спасибо за", "приятного аппетита", "ждём вас",
        "электронными", "округлени", "агроторг", "торговый зал", "кассир",
        "азк №", "азк no", "азс №", "азс no", "эн ккт", "зн ккт", "рн ккт",
        "нефтепродукт", "роснефть", "лукойл", "газпром",
        "онлайн-касса", "онлайн - касса"
    ]

    private static let addressKeywords: Set<String> = [
        "обл.,", "область", "район", "ул.", "улица", "проспект", "корп.", "офис", "этаж",
        " д.", "д. ", ". д.", "г.о.", "г. о.", "сириус", "354340"
    ]

    private static let quantityUnits: Set<String> = ["шт", "кг", " x ", " х ", " × "]

    private let tokenizer = NLTokenizer(unit: .word)
    private let languageRecognizer = NLLanguageRecognizer()

    // MARK: - Public

    func parse(lines: [String]) -> [ReceiptItem] {
        let cleaned = lines.map { $0.trimmingCharacters(in: .whitespaces) }
        var items: [ReceiptItem] = []
        var nameQueue: [String] = []

        for line in cleaned {
            guard !line.isEmpty, !line.hasPrefix("=") else { continue }
            guard !shouldSkip(line) else { continue }

            if let (namePart, amount) = findPriceAtEnd(of: line) {
                let nameParts = namePart.isEmpty
                    ? (nameQueue.isEmpty ? [] : [nameQueue.removeFirst()])
                    : [namePart]
                if let item = makeItem(nameParts: nameParts, amount: amount) { items.append(item) }
                continue
            }

            if let amount = findStandalonePrice(in: line) {
                let nameParts = nameQueue.isEmpty ? [] : [nameQueue.removeFirst()]
                if let item = makeItem(nameParts: nameParts, amount: amount) { items.append(item) }
                continue
            }

            let enqueueLine = stripArticleNumber(from: line)
            let letters = enqueueLine.unicodeScalars.filter { CharacterSet.letters.contains($0) }
            guard letters.count >= minLettersInName else { continue }

            let prevWordCount = nameQueue.last?
                .components(separatedBy: .whitespaces).filter({ !$0.isEmpty }).count ?? 0
            let shouldMerge = !nameQueue.isEmpty && (
                prevWordCount == 1 ||
                (prevWordCount >= 3 &&
                 (isContinuation(after: nameQueue.last!) || isContinuationStart(of: enqueueLine)))
            )

            if shouldMerge {
                nameQueue[nameQueue.count - 1] += " " + enqueueLine
            } else {
                nameQueue.append(enqueueLine)
            }
        }

        return items
    }

    private func shouldSkip(_ line: String) -> Bool {
        isServiceLine(line) || isAddressLine(line) || isMaskedLine(line) ||
        isPurelyNumeric(line) || isQuantityMarker(line) || isQuantityLine(line) ||
        isTaxClassMarker(line) || isDuplicatePriceMark(line) || isPriceTimesQuantity(line) ||
        isPercentageLine(line) || isAddressWithNumber(line) || isOCRNoise(line) ||
        isStoreNumberLine(line) || isPersonName(line)
    }
}

// MARK: - Line Classification

private extension ReceiptParserService {

    func isServiceLine(_ line: String) -> Bool {
        let lower = line.lowercased().trimmingCharacters(in: .whitespaces)
        if Self.singleWordServiceTokens.contains(lower) { return true }
        if lower.contains(":") { return true }
        return Self.serviceKeywords.contains(where: { lower.contains($0) })
    }

    func isAddressLine(_ line: String) -> Bool {
        let lower = line.lowercased()
        return Self.addressKeywords.contains(where: { lower.contains($0) })
    }

    func isMaskedLine(_ line: String) -> Bool {
        let nonSpace = line.unicodeScalars.filter { !CharacterSet.whitespaces.contains($0) }
        guard nonSpace.count > 3 else { return false }
        return nonSpace.allSatisfy { !CharacterSet.alphanumerics.contains($0) }
    }

    func isPurelyNumeric(_ line: String) -> Bool {
        let nonSpace = line.unicodeScalars.filter { !CharacterSet.whitespaces.contains($0) }
        guard nonSpace.count > 3 else { return false }
        return nonSpace.allSatisfy { CharacterSet.decimalDigits.contains($0) }
    }

    func isQuantityLine(_ line: String) -> Bool {
        guard line.first?.isNumber == true else { return false }
        let lower = line.lowercased()
        return Self.quantityUnits.contains(where: { lower.contains($0) })
    }

    func isTaxClassMarker(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        return trimmed.count == 1 && trimmed.first?.isLetter == true
    }

    func isQuantityMarker(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix("*") else { return false }
        let after = String(trimmed.dropFirst())
        return after.count <= 2 && after.allSatisfy { $0.isNumber }
    }

    func isOCRNoise(_ line: String) -> Bool {
        let tokens = line.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        if tokens.count == 1, let first = tokens[0].unicodeScalars.first,
           !CharacterSet.alphanumerics.contains(first) { return true }
        guard tokens.count >= 2 else { return false }

        let singleCharCount = tokens.filter { tok in
            tok.count == 1 &&
            tok.unicodeScalars.first.map { !CharacterSet.alphanumerics.contains($0) } ?? false
        }.count
        if singleCharCount * 3 > tokens.count { return true }

        let noisyTokenCount = tokens.filter { tok in
            tok.count <= 3 &&
            tok.unicodeScalars.contains(where: { CharacterSet.decimalDigits.contains($0) }) &&
            tok.unicodeScalars.contains(where: { CharacterSet.uppercaseLetters.contains($0) })
        }.count
        if tokens.count >= 4 && noisyTokenCount * 2 >= tokens.count { return true }

        let total = line.unicodeScalars.filter { !CharacterSet.whitespaces.contains($0) }
        let alphanumeric = total.filter { CharacterSet.alphanumerics.contains($0) }
        return total.count > 4 && alphanumeric.count * 3 < total.count
    }

    static let continuationWords: Set<String> = [
        "с", "со", "и", "из", "для", "в", "на", "к", "по", "от",
        "или", "без", "под", "над", "за", "при", "до", "а"
    ]

    func isContinuation(after line: String) -> Bool {
        let lastWord = line.components(separatedBy: .whitespaces).last?.lowercased() ?? ""
        return Self.continuationWords.contains(lastWord)
    }

    func isContinuationStart(of line: String) -> Bool {
        let firstWord = line.components(separatedBy: .whitespaces).first?.lowercased() ?? ""
        return Self.continuationWords.contains(firstWord)
    }

    func isStoreNumberLine(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        let parts = trimmed.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        guard parts.count >= 2, let first = parts.first else { return false }
        let digits = first.replacingOccurrences(of: "-", with: "")
        return digits.count <= 4 && digits.allSatisfy({ $0.isNumber })
    }

    func isPersonName(_ line: String) -> Bool {
        let tokens = line.trimmingCharacters(in: .whitespaces)
            .components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        guard tokens.count == 2 else { return false }
        return tokens.allSatisfy { token in
            guard let first = token.unicodeScalars.first,
                  CharacterSet.uppercaseLetters.contains(first) else { return false }
            return token.unicodeScalars.allSatisfy { CharacterSet.letters.contains($0) }
        }
    }

    func isPriceTimesQuantity(_ line: String) -> Bool {
        let parts = line.trimmingCharacters(in: .whitespaces)
            .components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        guard parts.count == 2, parsePrice(from: parts[0]) != nil else { return false }
        let second = parts[1]
        guard second.hasPrefix("*") else { return false }
        let digits = String(second.dropFirst())
        return !digits.isEmpty && digits
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: ",", with: "")
            .allSatisfy({ $0.isNumber })
    }

    func isPercentageLine(_ line: String) -> Bool {
        line.trimmingCharacters(in: .whitespaces).hasSuffix("%")
    }

    func isAddressWithNumber(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard trimmed.count > 5 else { return false }
        let lastToken = (trimmed.components(separatedBy: .whitespaces).last ?? "").lowercased()
        let digits = lastToken.unicodeScalars.filter { CharacterSet.decimalDigits.contains($0) }
        let letters = lastToken.unicodeScalars.filter { CharacterSet.letters.contains($0) }
        guard digits.count > 0 && letters.count > 0 && lastToken.count <= 6 else { return false }
        let measureSuffixes = ["г", "кг", "мл", "л", "гр", "oz", "ml", "kg"]
        return !measureSuffixes.contains(where: { lastToken.hasSuffix($0) })
    }

    func isDuplicatePriceMark(_ line: String) -> Bool {
        let parts = line.trimmingCharacters(in: .whitespaces)
            .components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        guard parts.count >= 2, parts.last!.allSatisfy({ $0 == "*" }) else { return false }
        return parsePrice(from: parts.dropLast().joined()) != nil
    }
}

// MARK: - Price Detection & Name Construction

private extension ReceiptParserService {

    func findPriceAtEnd(of line: String) -> (namePart: String, amount: Decimal)? {
        let stripped = stripCurrencySuffix(from: line)
        let parts = stripped.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        guard parts.count >= 2 else { return nil }
        if let amount = parsePrice(from: parts.last!) {
            return (parts.dropLast(1).joined(separator: " ").trimmingCharacters(in: .whitespaces), amount)
        }
        let lastTwo = parts.suffix(2).joined()
        if let amount = parsePrice(from: lastTwo) {
            return (parts.dropLast(2).joined(separator: " ").trimmingCharacters(in: .whitespaces), amount)
        }
        return nil
    }

    func findStandalonePrice(in line: String) -> Decimal? {
        var stripped = stripCurrencySuffix(from: line)
        let parts = stripped.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        if parts.count == 2, let last = parts.last, last.count == 1, last.first?.isLetter == true {
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

    func parsePrice(from token: String) -> Decimal? {
        var token = token
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
        if parts.count == 1 {
            guard !parts[0].isEmpty, parts[0].allSatisfy({ $0.isNumber }),
                  parts[0].count >= 2, parts[0].count <= 6 else { return nil }
            guard let amount = Decimal(string: parts[0]), amount >= 5 else { return nil }
            return amount
        }
        guard parts.count == 2, parts[1].count <= 2, parts[1].allSatisfy({ $0.isNumber }),
              !parts[0].isEmpty, parts[0].allSatisfy({ $0.isNumber }),
              parts[0].count <= 6 else { return nil }
        guard let amount = Decimal(string: normalized), amount >= 5 else { return nil }
        return amount
    }

    func stripArticleNumber(from line: String) -> String {
        var trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed.hasPrefix("*") { trimmed = String(trimmed.dropFirst()) }
        let parts = trimmed.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        guard let first = parts.first else { return trimmed }
        if first.allSatisfy({ $0.isNumber }) && first.count >= 4 {
            return parts.dropFirst().joined(separator: " ")
        }
        return trimmed
    }

    func stripCurrencySuffix(from line: String) -> String {
        var result = line
        for suffix in ["руб.", "руб", " р.", " р", "rub", "RUB", "₽"] where result.hasSuffix(suffix) {
            result = String(result.dropLast(suffix.count))
        }
        return result.trimmingCharacters(in: .whitespaces)
    }

    func makeItem(nameParts: [String], amount: Decimal) -> ReceiptItem? {
        let name = extractMeaningfulWords(from: nameParts.joined(separator: " "))
        let letterCount = name.unicodeScalars.filter { CharacterSet.letters.contains($0) }.count
        guard letterCount >= minLettersInName else { return nil }
        return ReceiptItem(name: name, amount: amount)
    }

    func extractMeaningfulWords(from text: String) -> String {
        tokenizer.string = text
        languageRecognizer.reset()
        languageRecognizer.processString(text)
        if let lang = languageRecognizer.dominantLanguage { tokenizer.setLanguage(lang) }
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
