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

    let minLettersInName = 4

    static let singleWordServiceTokens: Set<String> = [
        "цена", "скидка", "скидкой", "итого", "итог", "сумма", "оплата",
        "наличными", "безналичными", "сдача", "приход", "расход",
        "блюдо", "всего", "количество", "наименование",
        "товар", "товары", "услуга",
        "пятерочка", "пятёрочка", "агроторг", "магнит", "дикси",
        "перекрёсток", "перекресток", "лента", "ашан", "метро"
    ]

    static let serviceKeywords: Set<String> = [
        "итого", "итог:", "total", "наличными", "безналичными",
        "visa", "mastercard", "скидка:", "бонус", "баллы",
        "ндс", "сумма ндс", "nds", "vat",
        "кассовый чек", "чек №", "чек #", "спасибо",
        "инн:", "кпп:", "огрн",
        "фискальный", "фн:", "фд:", "фп:", "офд",
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
        "карта:", "карта лояльности", "держатель",
        "официант", "столик", "стол №", "заказ №", "счёт №", "счет №",
        "наименование", "количество", "блюдо", "позиция",
        "всего:", "итого:", "обслуживание", "сервисный сбор",
        "сканируй", "чаевые", "qr код", "qr-код", "оставить отзыв",
        "спасибо за", "приятного аппетита", "ждём вас",
        "электронными", "округлени",
        "агроторг", "торговый зал",
        "кассир",
        "азк №", "азк no", "азс №", "азс no", "эн ккт", "зн ккт", "рн ккт",
        "нефтепродукт", "роснефть", "лукойл", "газпром",
        "онлайн-касса", "онлайн - касса"
    ]

    static let addressKeywords: Set<String> = [
        "обл.,", "область", "район", "ул.", "улица",
        "проспект", "корп.", "офис", "этаж",
        " д.", "д. ", ". д.",
        "г.о.", "г. о.", "сириус", "354340"
    ]

    static let quantityUnits: Set<String> = [
        "шт", "кг", " x ", " х ", " × "
    ]

    let tokenizer = NLTokenizer(unit: .word)
    let languageRecognizer = NLLanguageRecognizer()

    // MARK: - Public

    func parse(lines: [String]) -> [ReceiptItem] {
        let cleaned = lines.map { $0.trimmingCharacters(in: .whitespaces) }
        var items: [ReceiptItem] = []
        var nameQueue: [String] = []

        for line in cleaned {
            guard !line.isEmpty, !line.hasPrefix("=") else { continue }
            guard !isSkippedLine(line) else { continue }
            processLine(line, nameQueue: &nameQueue, items: &items)
        }

        print("[Parser] Total items: \(items.count)")
        return items
    }

    // MARK: - Parsing Helpers

    private func isSkippedLine(_ line: String) -> Bool {
        let classifiers: [(String, (String) -> Bool)] = [
            ("service", isServiceLine),
            ("address", isAddressLine),
            ("masked", isMaskedLine),
            ("numeric", isPurelyNumeric),
            ("qtyMarker", isQuantityMarker),
            ("qtyLine", isQuantityLine),
            ("taxClass", isTaxClassMarker),
            ("dupPrice", isDuplicatePriceMark),
            ("pricexQty", isPriceTimesQuantity),
            ("percent", isPercentageLine),
            ("addrNum", isAddressWithNumber),
            ("noise", isOCRNoise),
            ("storeNum", isStoreNumberLine),
            ("person", isPersonName)
        ]
        for (reason, check) in classifiers where check(line) {
            print("[Parser] skip(\(reason)): \(line)")
            return true
        }
        return false
    }

    private func processLine(_ line: String, nameQueue: inout [String], items: inout [ReceiptItem]) {
        if let (namePart, amount) = findPriceAtEnd(of: line) {
            let nameParts = namePart.isEmpty
                ? (nameQueue.isEmpty ? [] : [nameQueue.removeFirst()])
                : [namePart]
            if let item = makeItem(nameParts: nameParts, amount: amount) {
                items.append(item)
                print("[Parser] ✓ \(item.name) — \(item.amount)")
            } else {
                print("[Parser] ✗ rejected name=\(nameParts) amount=\(amount)")
            }
            return
        }

        if let amount = findStandalonePrice(in: line) {
            let nameParts = nameQueue.isEmpty ? [] : [nameQueue.removeFirst()]
            if let item = makeItem(nameParts: nameParts, amount: amount) {
                items.append(item)
                print("[Parser] ✓ \(item.name) — \(item.amount)")
            } else {
                print("[Parser] ✗ rejected name=\(nameParts) amount=\(amount)")
            }
            return
        }

        enqueueNameLine(line, nameQueue: &nameQueue)
    }

    private func enqueueNameLine(_ line: String, nameQueue: inout [String]) {
        let enqueueLine = stripArticleNumber(from: line)
        let letters = enqueueLine.unicodeScalars.filter { CharacterSet.letters.contains($0) }
        guard letters.count >= minLettersInName else { return }

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
}
