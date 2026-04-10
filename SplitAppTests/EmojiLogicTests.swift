import XCTest
@testable import SplitApp

final class EmojiLogicTests: XCTestCase {
    func testMatcherHandlesNormalizationForRussianWordWithPunctuation() {
        let matcher = EmojiAutoReplaceMatcher(
            emojis: [
                EmojiPredictModel(
                    emoji: "🍕",
                    name: "pizza",
                    version: "E0.6",
                    codePoints: ["1F355"]
                )
            ]
        )

        let match = matcher.match(for: "  Пицца!  ")

        XCTAssertEqual(match?.emoji, "🍕")
        XCTAssertEqual(match?.name, "pizza")
    }

    func testMatcherReturnsExactMatch() {
        let matcher = EmojiAutoReplaceMatcher(
            emojis: [
                EmojiPredictModel(
                    emoji: "🧾",
                    name: "receipt",
                    version: "E11.0",
                    codePoints: ["1F9FE"]
                )
            ]
        )

        let match = matcher.match(for: "receipt")

        XCTAssertEqual(match?.emoji, "🧾")
        XCTAssertEqual(match?.name, "receipt")
    }

    func testMatcherReturnsAliasMatchFromRussianDictionary() {
        let matcher = EmojiAutoReplaceMatcher(
            emojis: [
                EmojiPredictModel(
                    emoji: "🧾",
                    name: "receipt",
                    version: "E11.0",
                    codePoints: ["1F9FE"]
                )
            ]
        )

        let match = matcher.match(for: "чек")

        XCTAssertEqual(match?.emoji, "🧾")
        XCTAssertEqual(match?.name, "receipt")
    }

    func testMatcherReturnsNilForEmptyOrUnknownWords() {
        let matcher = EmojiAutoReplaceMatcher(
            emojis: [
                EmojiPredictModel(
                    emoji: "🍕",
                    name: "pizza",
                    version: "E0.6",
                    codePoints: ["1F355"]
                )
            ]
        )

        XCTAssertNil(matcher.match(for: "   "))
        XCTAssertNil(matcher.match(for: "неизвестно"))
    }

    func testParseContentIgnoresCommentsBlankAndNonFullyQualifiedLines() {
        let parser = EmojiTextParser()
        let content = """
        # This is a comment

        1F355                                      ; fully-qualified     # 🍕 E0.6 pizza
        1F469 200D 1F4BB                           ; fully-qualified     # 👩‍💻 E4.0 woman technologist
        1F44D                                      ; minimally-qualified # 👍 E0.6 thumbs up
        totally invalid line
        """

        let result = parser.parseContent(content)

        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0].emoji, "🍕")
        XCTAssertEqual(result[0].name, "pizza")
        XCTAssertEqual(result[0].version, "E0.6")
        XCTAssertEqual(result[0].codePoints, ["1F355"])

        XCTAssertEqual(result[1].emoji, "👩‍💻")
        XCTAssertEqual(result[1].name, "woman technologist")
        XCTAssertEqual(result[1].version, "E4.0")
        XCTAssertEqual(result[1].codePoints, ["1F469", "200D", "1F4BB"])
    }
}
