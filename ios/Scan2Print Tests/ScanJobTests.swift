import XCTest
@testable import Scan2Print

final class ScanJobTests: XCTestCase {

    private let decoder = JSONDecoder()

    // MARK: - UploadResponse decoding

    func testUploadResponseDecodesFromJSON() throws {
        let json = """
        {
            "jobId": "job-001",
            "status": "uploaded"
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(UploadResponse.self, from: json)
        XCTAssertEqual(response.jobId, "job-001")
        XCTAssertEqual(response.status, "uploaded")
    }

    func testUploadResponseFailsWithMissingFields() {
        let json = """
        {
            "jobId": "job-001"
        }
        """.data(using: .utf8)!

        XCTAssertThrowsError(try decoder.decode(UploadResponse.self, from: json))
    }

    // MARK: - StatusResponse decoding

    func testStatusResponseDecodesWithAllFields() throws {
        let json = """
        {
            "jobId": "job-002",
            "status": "sliced",
            "error": null,
            "createdAt": 1700000000.0,
            "updatedAt": 1700001000.0
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(StatusResponse.self, from: json)
        XCTAssertEqual(response.jobId, "job-002")
        XCTAssertEqual(response.status, "sliced")
        XCTAssertNil(response.error)
        XCTAssertEqual(response.createdAt, 1700000000.0)
        XCTAssertEqual(response.updatedAt, 1700001000.0)
    }

    func testStatusResponseDecodesWithoutOptionalFields() throws {
        let json = """
        {
            "jobId": "job-003",
            "status": "processing"
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(StatusResponse.self, from: json)
        XCTAssertEqual(response.jobId, "job-003")
        XCTAssertEqual(response.status, "processing")
        XCTAssertNil(response.error)
        XCTAssertNil(response.createdAt)
        XCTAssertNil(response.updatedAt)
    }

    func testStatusResponseDecodesWithErrorField() throws {
        let json = """
        {
            "jobId": "job-004",
            "status": "failed",
            "error": "Model too complex for slicing"
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(StatusResponse.self, from: json)
        XCTAssertEqual(response.jobId, "job-004")
        XCTAssertEqual(response.status, "failed")
        XCTAssertEqual(response.error, "Model too complex for slicing")
        XCTAssertNil(response.createdAt)
        XCTAssertNil(response.updatedAt)
    }

    func testStatusResponseFailsWithMissingRequiredFields() {
        let json = """
        {
            "status": "sliced"
        }
        """.data(using: .utf8)!

        XCTAssertThrowsError(try decoder.decode(StatusResponse.self, from: json))
    }

    // MARK: - PrintResponse decoding

    func testPrintResponseDecodesWithAllFields() throws {
        let json = """
        {
            "jobId": "job-005",
            "status": "printing",
            "message": "Print job started successfully"
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(PrintResponse.self, from: json)
        XCTAssertEqual(response.jobId, "job-005")
        XCTAssertEqual(response.status, "printing")
        XCTAssertEqual(response.message, "Print job started successfully")
    }

    func testPrintResponseDecodesWithoutOptionalMessage() throws {
        let json = """
        {
            "jobId": "job-006",
            "status": "printing"
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(PrintResponse.self, from: json)
        XCTAssertEqual(response.jobId, "job-006")
        XCTAssertEqual(response.status, "printing")
        XCTAssertNil(response.message)
    }

    func testPrintResponseFailsWithMissingRequiredFields() {
        let json = """
        {
            "message": "ok"
        }
        """.data(using: .utf8)!

        XCTAssertThrowsError(try decoder.decode(PrintResponse.self, from: json))
    }

    // MARK: - Round-trip encoding/decoding

    func testUploadResponseRoundTrip() throws {
        let original = UploadResponse(jobId: "round-trip-1", status: "uploaded")
        let data = try JSONEncoder().encode(original)
        let decoded = try decoder.decode(UploadResponse.self, from: data)
        XCTAssertEqual(decoded.jobId, original.jobId)
        XCTAssertEqual(decoded.status, original.status)
    }

    func testStatusResponseRoundTrip() throws {
        let original = StatusResponse(
            jobId: "round-trip-2",
            status: "sliced",
            error: nil,
            createdAt: 12345.0,
            updatedAt: 67890.0
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try decoder.decode(StatusResponse.self, from: data)
        XCTAssertEqual(decoded.jobId, original.jobId)
        XCTAssertEqual(decoded.status, original.status)
        XCTAssertNil(decoded.error)
        XCTAssertEqual(decoded.createdAt, original.createdAt)
        XCTAssertEqual(decoded.updatedAt, original.updatedAt)
    }

    func testPrintResponseRoundTrip() throws {
        let original = PrintResponse(jobId: "round-trip-3", status: "printing", message: "Started")
        let data = try JSONEncoder().encode(original)
        let decoded = try decoder.decode(PrintResponse.self, from: data)
        XCTAssertEqual(decoded.jobId, original.jobId)
        XCTAssertEqual(decoded.status, original.status)
        XCTAssertEqual(decoded.message, original.message)
    }
}
