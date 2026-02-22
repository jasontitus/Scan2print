import XCTest
@testable import Scan2Print

final class NetworkServiceTests: XCTestCase {

    // MARK: - NetworkError descriptions

    func testUploadFailedErrorDescription() {
        let error = NetworkError.uploadFailed
        XCTAssertEqual(error.errorDescription, "Failed to upload model to server")
    }

    func testSlicingFailedErrorDescription() {
        let error = NetworkError.slicingFailed("Mesh too complex")
        XCTAssertEqual(error.errorDescription, "Slicing failed: Mesh too complex")
    }

    func testPrintFailedErrorDescription() {
        let error = NetworkError.printFailed
        XCTAssertEqual(error.errorDescription, "Failed to send print command")
    }

    func testSlicingFailedErrorDescriptionWithEmptyReason() {
        let error = NetworkError.slicingFailed("")
        XCTAssertEqual(error.errorDescription, "Slicing failed: ")
    }

    // MARK: - NetworkService can be instantiated

    func testNetworkServiceCanBeCreated() {
        let service = NetworkService()
        XCTAssertNotNil(service)
    }

    // MARK: - NetworkError LocalizedError conformance

    func testNetworkErrorIsLocalizedError() {
        let error: any LocalizedError = NetworkError.uploadFailed
        XCTAssertNotNil(error.errorDescription)
    }

    func testNetworkErrorUsedAsSwiftError() {
        let error: any Error = NetworkError.printFailed
        // localizedDescription should include the custom errorDescription
        XCTAssertTrue(error.localizedDescription.contains("Failed to send print command"))
    }
}
