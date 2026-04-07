import Foundation
import NaturalLanguage

// MARK: - Line Classification

extension ReceiptParserService {

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

    /// *1, *2, *3 — quantity markers (max 2 digits after asterisk).
    /// *3691951 ТОВАР — article number prefix, NOT a quantity marker.
    func isQuantityMarker(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix("*") else { return false }
        let after = String(trimmed.dropFirst())
        return after.count <= 2 && after.allSatisfy { $0.isNumber }
    }

    /// OCR noise from QR codes, barcodes, or garbled text.
    func isOCRNoise(_ line: String) -> Bool {
        let tokens = line.components(separatedBy: .whitespaces).filter { !$0.isEmpty }

        if tokens.count == 1, let first = tokens[0].unicodeScalars.first,
           !CharacterSet.alphanumerics.contains(first) {
            return true
        }

        guard tokens.count >= 2 else { return false }

        let singleCharCount = tokens.filter { tok in
            tok.count == 1 && tok.unicodeScalars.first.map { !CharacterSet.alphanumerics.contains($0) } ?? false
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
        if total.count > 4 && alphanumeric.count * 3 < total.count { return true }

        return false
    }

    static let continuationWords: Set<String> = [
        "с", "со", "и", "из", "для", "в", "на", "к", "по", "от",
        "или", "без", "под", "над", "за", "при", "до", "а"
    ]

    /// Previous line ends with preposition → next line is continuation.
    func isContinuation(after line: String) -> Bool {
        let lastWord = line.components(separatedBy: .whitespaces).last?.lowercased() ?? ""
        return Self.continuationWords.contains(lastWord)
    }

    /// Current line starts with conjunction → it continues the previous line.
    func isContinuationStart(of line: String) -> Bool {
        let firstWord = line.components(separatedBy: .whitespaces).first?.lowercased() ?? ""
        return Self.continuationWords.contains(firstWord)
    }

    /// Lines that are a store name/number prefix: "5 Пятёрочка", "3221-Пятерочка"
    func isStoreNumberLine(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        let parts = trimmed.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        guard parts.count >= 2, let first = parts.first else { return false }
        let digits = first.replacingOccurrences(of: "-", with: "")
        return digits.count <= 4 && digits.allSatisfy({ $0.isNumber })
    }

    /// Lines that look like a person name (cashier, loyalty card holder).
    func isPersonName(_ line: String) -> Bool {
        let tokens = line.trimmingCharacters(in: .whitespaces)
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
        guard tokens.count == 2 else { return false }
        return tokens.allSatisfy { tok in
            guard let first = tok.unicodeScalars.first,
                  CharacterSet.uppercaseLetters.contains(first) else { return false }
            return tok.unicodeScalars.allSatisfy { CharacterSet.letters.contains($0) }
        }
    }

    /// Lines like "74.90 *1.514" — price × weight/quantity breakdown.
    func isPriceTimesQuantity(_ line: String) -> Bool {
        let parts = line.trimmingCharacters(in: .whitespaces)
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
        guard parts.count == 2 else { return false }
        guard parsePrice(from: parts[0]) != nil else { return false }
        let second = parts[1]
        guard second.hasPrefix("*") else { return false }
        let digits = String(second.dropFirst())
        return !digits.isEmpty && digits.replacingOccurrences(of: ".", with: "")
                                        .replacingOccurrences(of: ",", with: "")
                                        .allSatisfy({ $0.isNumber })
    }

    /// Lines like "18.00%", "10.00%" — VAT rate lines.
    func isPercentageLine(_ line: String) -> Bool {
        return line.trimmingCharacters(in: .whitespaces).hasSuffix("%")
    }

    /// Lines that look like a street address ending with a building number like "68А1", "13 В".
    func isAddressWithNumber(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard trimmed.count > 5 else { return false }
        let lastToken = (trimmed.components(separatedBy: .whitespaces).last ?? "").lowercased()
        let digits = lastToken.unicodeScalars.filter { CharacterSet.decimalDigits.contains($0) }
        let letters = lastToken.unicodeScalars.filter { CharacterSet.letters.contains($0) }
        guard digits.count > 0 && letters.count > 0 && lastToken.count <= 6 else { return false }

        let measureSuffixes = ["г", "кг", "мл", "л", "гр", "oz", "ml", "kg"]
        if measureSuffixes.contains(where: { lastToken.hasSuffix($0) }) { return false }

        return true
    }

    func isDuplicatePriceMark(_ line: String) -> Bool {
        let parts = line.trimmingCharacters(in: .whitespaces)
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
        guard parts.count >= 2, parts.last!.allSatisfy({ $0 == "*" }) else { return false }
        return parsePrice(from: parts.dropLast().joined()) != nil
    }
}

// MARK: - Price Detection

extension ReceiptParserService {

    func findPriceAtEnd(of line: String) -> (namePart: String, amount: Decimal)? {
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

    func findStandalonePrice(in line: String) -> Decimal? {
        var stripped = stripCurrencySuffix(from: line)

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
            guard !parts[0].isEmpty,
                  parts[0].allSatisfy({ $0.isNumber }),
                  parts[0].count >= 2,
                  parts[0].count <= 6 else { return nil }
            guard let amount = Decimal(string: parts[0]), amount >= 5 else { return nil }
            return amount
        }

        guard parts.count == 2,
              parts[1].count <= 2,
              parts[1].allSatisfy({ $0.isNumber }),
              !parts[0].isEmpty,
              parts[0].allSatisfy({ $0.isNumber }),
              parts[0].count <= 6 else { return nil }

        guard let amount = Decimal(string: normalized), amount > 0 else { return nil }
        guard amount >= 5 else { return nil }

        return amount
    }

    /// Removes leading article number from product lines.
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
}

// MARK: - Name Construction

extension ReceiptParserService {

    func makeItem(nameParts: [String], amount: Decimal) -> ReceiptItem? {
        let raw = nameParts.joined(separator: " ")
        let name = extractMeaningfulWords(from: raw)
        let letterCount = name.unicodeScalars.filter { CharacterSet.letters.contains($0) }.count
        guard letterCount >= minLettersInName else { return nil }
        return ReceiptItem(name: name, amount: amount)
    }

    func extractMeaningfulWords(from text: String) -> String {
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
