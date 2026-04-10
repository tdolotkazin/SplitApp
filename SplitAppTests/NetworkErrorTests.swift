import XCTest
@testable import SplitApp

final class NetworkErrorTests: XCTestCase {
    func testHTTPErrorDescriptionContainsStatusCodeAndDetail() {
        let error = NetworkError.httpError(statusCode: 404, detail: "Not Found")

        XCTAssertEqual(error.errorDescription, "HTTP error 404: Not Found")
    }

    func testHTTPErrorDescriptionUsesFallbackWhenDetailIsNil() {
        let error = NetworkError.httpError(statusCode: 500, detail: nil)

        XCTAssertEqual(error.errorDescription, "HTTP error 500: Unknown error")
    }
}
