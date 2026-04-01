import Foundation

/// Parses raw OCR lines from a receipt into structured items with amounts.
///
/// Uses a state-machine approach: accumulates name-only lines into a buffer,
/// flushes the buffer when a price line is detected. Handles item names
/// spanning up to 5 lines.
final class ReceiptParserService {

    // MARK: - Patterns

    /// Price at the END of a line, optionally preceded by fill characters (dots, dashes).
    /// Allows an optional currency suffix (руб, р, rub).
    /// Examples: "Молоко..........89.90", "Хлеб 45,00", "Масло сл. 1 234,50 р"
    private static let priceAtEndPattern: NSRegularExpression = try! NSRegularExpression(
        pattern: #"[.\-\s_]*(\d{1,6}[\s\u00A0]?\d{0,3}[.,]\d{2})\s*(?:руб\.?|р\.?|rub)?\s*$"#,
        options: .caseInsensitive
    )

    /// Line that is ONLY a price — the name was on previous lines.
    /// Example: a standalone "89.90" line after "Молоко 3.2%"
    private static let standalonePricePattern: NSRegularExpression = try! NSRegularExpression(
        pattern: #"^\s*(\d{1,6}[\s\u00A0]?\d{0,3}[.,]\d{2})\s*(?:руб\.?|р\.?|rub)?\s*$"#,
        options: .caseInsensitive
    )

    /// Quantity/unit lines to skip: "2 x 45.00", "1.500 кг x 200.00", "3 шт"
    private static let quantityLinePattern: NSRegularExpression = try! NSRegularExpression(
        pattern: #"^\s*\d+[.,]?\d*\s*(?:[xхXХ×]|шт\.?|кг\.?|г\.?|л\.?|мл\.?)"#,
        options: .caseInsensitive
    )

    /// Pure numeric lines — barcodes, article numbers, etc.
    private static let pureNumberPattern: NSRegularExpression = try! NSRegularExpression(
        pattern: #"^\s*\d[\d\s]{0,19}\d\s*$"#
    )

    /// Lines consisting mostly of repeated symbols — masked card numbers (****), separators (----).
    private static let maskedLinePattern: NSRegularExpression = try! NSRegularExpression(
        pattern: #"^[\s\*\-\=\#\_]{4,}$"#
    )

    /// Address-like lines — contain city, street, region indicators.
    private static let addressPattern: NSRegularExpression = try! NSRegularExpression(
        pattern: #"(?:обл\.|область|район|город|г\.|ул\.|улица|пр\.|проспект|д\.|корп\.|кв\.|офис|этаж)"#,
        options: .caseInsensitive
    )

    // Service lines that break item grouping
    private static let skipKeywords: Set<String> = [
        "итого", "total", "сумма", "наличные", "карта", "сдача", "visa", "mastercard", "мир",
        "скидка", "бонус", "баллы", "ндс", "nds", "vat", "налог",
        "кассир", "оператор", "кассовый чек", "чек №", "чек #", "спасибо",
        "магазин", "адрес", "тел.", "телефон", "инн", "кпп", "огрн",
        "фискальный", "фн:", "фд:", "фп:", "офд", "оfd",
        "приход", "расход", "возврат прихода", "возврат расхода",
        "www.", "http", "receipt", "cashier",
        "оплата", "безналичный", "электронными", "сертификат"
    ]

    /// Minimum number of letter characters a name must contain to be valid.
    private let minLettersInName = 2

    private let maxNameLines = 5

    // MARK: - Public

    /// Parses OCR text lines into receipt items.
    func parse(lines: [String]) -> [ReceiptItem] {
        let cleaned = lines.map { $0.trimmingCharacters(in: .whitespaces) }

        var items: [ReceiptItem] = []
        var nameBuffer: [String] = []  // accumulates name-only lines

        for line in cleaned {
            // Empty or service lines — reset buffer, they break item groups
            if line.isEmpty || isServiceLine(line) || isAddressLine(line) {
                nameBuffer = []
                continue
            }

            // Masked lines (****) or separator lines — reset buffer
            if isMaskedLine(line) {
                nameBuffer = []
                continue
            }

            // Pure numbers (barcodes, articles) — skip silently, don't reset buffer
            if isPurlyNumeric(line) { continue }

            // Quantity/measure lines — skip silently, don't reset buffer
            if isQuantityLine(line) { continue }

            // Line ends with a price → emit item using buffer + name prefix on this line
            if let (namePart, amount) = extractPriceAtEnd(from: line) {
                var parts = nameBuffer
                if !namePart.isEmpty { parts.append(namePart) }
                if let item = makeItem(nameParts: parts, amount: amount) {
                    items.append(item)
                }
                nameBuffer = []
                continue
            }

            // Line is ONLY a price → use buffer as the name
            if let amount = extractStandalonePrice(from: line) {
                if let item = makeItem(nameParts: nameBuffer, amount: amount) {
                    items.append(item)
                }
                nameBuffer = []
                continue
            }

            // Name-only line → add to buffer, capped at maxNameLines
            if nameBuffer.count >= maxNameLines { nameBuffer.removeFirst() }
            nameBuffer.append(line)
        }

        return items
    }

    // MARK: - Line Classification

    private func isServiceLine(_ line: String) -> Bool {
        let lower = line.lowercased()
        return Self.skipKeywords.contains(where: { lower.contains($0) })
    }

    private func isAddressLine(_ line: String) -> Bool {
        let ns = line as NSString
        let range = NSRange(location: 0, length: ns.length)
        return Self.addressPattern.firstMatch(in: line, range: range) != nil
    }

    private func isMaskedLine(_ line: String) -> Bool {
        matchesFully(Self.maskedLinePattern, in: line)
    }

    private func isPurlyNumeric(_ line: String) -> Bool {
        matchesFully(Self.pureNumberPattern, in: line)
    }

    private func isQuantityLine(_ line: String) -> Bool {
        matchesPrefix(Self.quantityLinePattern, in: line)
    }

    // MARK: - Price Extraction

    private func extractPriceAtEnd(from line: String) -> (name: String, amount: Decimal)? {
        guard let match = firstMatch(Self.priceAtEndPattern, in: line, group: 1) else { return nil }
        guard let amount = decimal(from: match.value), amount > 0 else { return nil }

        // Name = everything before the match, with fill chars cleaned up
        let namePart = String(line[line.startIndex..<match.fullMatchStart])
            .replacingOccurrences(of: #"[.\-_*]{2,}"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)

        return (namePart, amount)
    }

    private func extractStandalonePrice(from line: String) -> Decimal? {
        guard let match = firstMatch(Self.standalonePricePattern, in: line, group: 1) else { return nil }
        guard let amount = decimal(from: match.value), amount > 0 else { return nil }
        return amount
    }

    // MARK: - Helpers

    private func makeItem(nameParts: [String], amount: Decimal) -> ReceiptItem? {
        let raw = nameParts.joined(separator: " ")

        // Remove digits, asterisks, hash symbols
        let cleaned = raw
            .replacingOccurrences(of: #"[\d\*#]"#, with: "", options: .regularExpression)
            // Collapse runs of spaces/dashes/dots/underscores left after removal
            .replacingOccurrences(of: #"[\s\-\.\,\_\/\\]{2,}"#, with: " ", options: .regularExpression)
            // Strip leading/trailing non-letter characters (dashes, spaces, punctuation)
            .replacingOccurrences(of: #"^[^a-zA-Zа-яёА-ЯЁ]+"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"[^a-zA-Zа-яёА-ЯЁ]+$"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)

        // Must contain at least minLettersInName actual letters
        let letterCount = cleaned.unicodeScalars.filter { CharacterSet.letters.contains($0) }.count
        guard letterCount >= minLettersInName else { return nil }

        return ReceiptItem(name: cleaned, amount: amount)
    }

    private func decimal(from raw: String) -> Decimal? {
        let normalized = raw
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "\u{00A0}", with: "")
            .replacingOccurrences(of: ",", with: ".")
        return Decimal(string: normalized)
    }

    // Returns (captureGroup value, start of full match) or nil
    private func firstMatch(
        _ regex: NSRegularExpression,
        in string: String,
        group: Int
    ) -> (value: String, fullMatchStart: String.Index)? {
        let ns = string as NSString
        let range = NSRange(location: 0, length: ns.length)
        guard let match = regex.firstMatch(in: string, range: range) else { return nil }

        let groupRange = match.range(at: group)
        guard groupRange.location != NSNotFound,
              let swiftGroup = Range(groupRange, in: string),
              let swiftFull = Range(match.range, in: string) else { return nil }

        return (String(string[swiftGroup]), swiftFull.lowerBound)
    }

    private func matchesFully(_ regex: NSRegularExpression, in string: String) -> Bool {
        let ns = string as NSString
        let range = NSRange(location: 0, length: ns.length)
        guard let match = regex.firstMatch(in: string, range: range) else { return false }
        return match.range.length == ns.length
    }

    private func matchesPrefix(_ regex: NSRegularExpression, in string: String) -> Bool {
        let ns = string as NSString
        let range = NSRange(location: 0, length: ns.length)
        guard let match = regex.firstMatch(in: string, range: range) else { return false }
        return match.range.location == 0
    }
}
