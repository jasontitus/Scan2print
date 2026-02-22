import XCTest
@testable import Scan2Print

final class SavedScanTests: XCTestCase {

    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    // MARK: - SavedScan round-trip

    func testSavedScanRoundTrip() throws {
        let original = SavedScan(
            id: UUID(),
            name: "Test Scan",
            dateCreated: Date(),
            uploadStatus: .local
        )
        let data = try encoder.encode(original)
        let decoded = try decoder.decode(SavedScan.self, from: data)
        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.name, original.name)
        XCTAssertEqual(decoded.uploadStatus, .local)
    }

    // MARK: - UploadStatus encoding/decoding

    func testLocalStatusRoundTrip() throws {
        let status = UploadStatus.local
        let data = try encoder.encode(status)
        let decoded = try decoder.decode(UploadStatus.self, from: data)
        XCTAssertEqual(decoded, status)
    }

    func testUploadingStatusRoundTrip() throws {
        let status = UploadStatus.uploading
        let data = try encoder.encode(status)
        let decoded = try decoder.decode(UploadStatus.self, from: data)
        XCTAssertEqual(decoded, status)
    }

    func testSlicingStatusRoundTrip() throws {
        let status = UploadStatus.slicing(jobId: "job-123")
        let data = try encoder.encode(status)
        let decoded = try decoder.decode(UploadStatus.self, from: data)
        XCTAssertEqual(decoded, status)
    }

    func testReadyToPrintStatusRoundTrip() throws {
        let status = UploadStatus.readyToPrint(jobId: "job-456")
        let data = try encoder.encode(status)
        let decoded = try decoder.decode(UploadStatus.self, from: data)
        XCTAssertEqual(decoded, status)
    }

    func testPrintingStatusRoundTrip() throws {
        let status = UploadStatus.printing(jobId: "job-789")
        let data = try encoder.encode(status)
        let decoded = try decoder.decode(UploadStatus.self, from: data)
        XCTAssertEqual(decoded, status)
    }

    func testPrintedStatusRoundTrip() throws {
        let status = UploadStatus.printed
        let data = try encoder.encode(status)
        let decoded = try decoder.decode(UploadStatus.self, from: data)
        XCTAssertEqual(decoded, status)
    }

    func testFailedStatusRoundTrip() throws {
        let status = UploadStatus.failed(message: "Network error")
        let data = try encoder.encode(status)
        let decoded = try decoder.decode(UploadStatus.self, from: data)
        XCTAssertEqual(decoded, status)
    }

    // MARK: - resetIfTransient

    func testUploadingResetsToLocal() {
        XCTAssertEqual(UploadStatus.uploading.resetIfTransient, .local)
    }

    func testLocalDoesNotReset() {
        XCTAssertEqual(UploadStatus.local.resetIfTransient, .local)
    }

    func testSlicingDoesNotReset() {
        let status = UploadStatus.slicing(jobId: "job-1")
        XCTAssertEqual(status.resetIfTransient, status)
    }

    func testPrintedDoesNotReset() {
        XCTAssertEqual(UploadStatus.printed.resetIfTransient, .printed)
    }

    func testFailedDoesNotReset() {
        let status = UploadStatus.failed(message: "err")
        XCTAssertEqual(status.resetIfTransient, status)
    }

    // MARK: - Equatable

    func testEqualLocalStatuses() {
        XCTAssertEqual(UploadStatus.local, UploadStatus.local)
    }

    func testNotEqualDifferentStatuses() {
        XCTAssertNotEqual(UploadStatus.local, UploadStatus.printed)
    }

    func testEqualSlicingWithSameJobId() {
        XCTAssertEqual(
            UploadStatus.slicing(jobId: "abc"),
            UploadStatus.slicing(jobId: "abc")
        )
    }

    func testNotEqualSlicingWithDifferentJobId() {
        XCTAssertNotEqual(
            UploadStatus.slicing(jobId: "abc"),
            UploadStatus.slicing(jobId: "xyz")
        )
    }

    // MARK: - Array encoding (simulates scans.json)

    func testSavedScanArrayRoundTrip() throws {
        let scans = [
            SavedScan(id: UUID(), name: "Scan 1", dateCreated: Date(), uploadStatus: .local),
            SavedScan(id: UUID(), name: "Scan 2", dateCreated: Date(), uploadStatus: .printed),
            SavedScan(id: UUID(), name: "Scan 3", dateCreated: Date(), uploadStatus: .failed(message: "timeout")),
        ]
        let data = try encoder.encode(scans)
        let decoded = try decoder.decode([SavedScan].self, from: data)
        XCTAssertEqual(decoded.count, 3)
        XCTAssertEqual(decoded[0].name, "Scan 1")
        XCTAssertEqual(decoded[1].uploadStatus, .printed)
        XCTAssertEqual(decoded[2].uploadStatus, .failed(message: "timeout"))
    }
}
