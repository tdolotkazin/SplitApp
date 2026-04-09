import Foundation

final class EmojiTextParser {
    func parse() throws -> [EmojiPredictModel] {
        guard let url = Bundle.main.url(forResource: "emojis", withExtension: "txt") else {
            throw EmojiTextParserError.fileNotFound
        }

        guard let content = try? String(contentsOf: url, encoding: .utf8) else {
            throw EmojiTextParserError.invalidDecoding
        }

        return parseContent(content)
    }

    func parseContent(_ content: String) -> [EmojiPredictModel] {
        let lines = content.components(separatedBy: .newlines)
        var result: [EmojiPredictModel] = []

        for line in lines {
            if let emoji = parseLine(line) {
                result.append(emoji)
            }
        }

        return result
    }

    private func parseLine(_ line: String) -> EmojiPredictModel? {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else { return nil }
        guard !trimmed.hasPrefix("#") else { return nil }
        guard trimmed.contains("; fully-qualified") else { return nil }

        guard let semicolonIndex = trimmed.firstIndex(of: ";"),
              let hashIndex = trimmed.firstIndex(of: "#")
        else {
            return nil
        }

        let leftPart = trimmed[..<semicolonIndex]
            .trimmingCharacters(in: .whitespaces)

        let rightPart = trimmed[trimmed.index(after: hashIndex)...]
            .trimmingCharacters(in: .whitespaces)

        let codePoints = leftPart
            .split(separator: " ")
            .map(String.init)

        let tokens = rightPart.split(separator: " ", omittingEmptySubsequences: true)

        guard tokens.count >= 3 else {
            return nil
        }

        let emojiSymbol = String(tokens[0])
        let version = String(tokens[1])
        let name = tokens.dropFirst(2).joined(separator: " ")

        return EmojiPredictModel(
            emoji: emojiSymbol,
            name: name,
            version: version,
            codePoints: codePoints
        )
    }
}
