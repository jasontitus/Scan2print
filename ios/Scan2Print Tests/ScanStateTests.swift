import XCTest
@testable import Scan2Print

final class ScanStateTests: XCTestCase {

    // MARK: - State creation

    func testIdleStateCanBeCreated() {
        let state = ScanState.idle
        XCTAssertEqual(state, .idle)
    }

    func testScanningStateCanBeCreated() {
        let state = ScanState.scanning
        XCTAssertEqual(state, .scanning)
    }

    func testReconstructingStateCanBeCreated() {
        let state = ScanState.reconstructing(progress: 0.5)
        XCTAssertEqual(state, .reconstructing(progress: 0.5))
    }

    func testUploadingStateCanBeCreated() {
        let state = ScanState.uploading
        XCTAssertEqual(state, .uploading)
    }

    func testSlicingStateCanBeCreated() {
        let state = ScanState.slicing(jobId: "job-123")
        XCTAssertEqual(state, .slicing(jobId: "job-123"))
    }

    func testReadyToPrintStateCanBeCreated() {
        let state = ScanState.readyToPrint(jobId: "job-456")
        XCTAssertEqual(state, .readyToPrint(jobId: "job-456"))
    }

    func testPrintingStateCanBeCreated() {
        let state = ScanState.printing(jobId: "job-789")
        XCTAssertEqual(state, .printing(jobId: "job-789"))
    }

    func testCompletedStateCanBeCreated() {
        let state = ScanState.completed
        XCTAssertEqual(state, .completed)
    }

    func testSavedStateCanBeCreated() {
        let id = UUID()
        let state = ScanState.saved(scanId: id)
        XCTAssertEqual(state, .saved(scanId: id))
    }

    func testFailedStateCanBeCreated() {
        let state = ScanState.failed(message: "Something went wrong")
        XCTAssertEqual(state, .failed(message: "Something went wrong"))
    }

    // MARK: - isTerminal

    func testIdleIsNotTerminal() {
        XCTAssertFalse(ScanState.idle.isTerminal)
    }

    func testScanningIsNotTerminal() {
        XCTAssertFalse(ScanState.scanning.isTerminal)
    }

    func testReconstructingIsNotTerminal() {
        XCTAssertFalse(ScanState.reconstructing(progress: 0.75).isTerminal)
    }

    func testUploadingIsNotTerminal() {
        XCTAssertFalse(ScanState.uploading.isTerminal)
    }

    func testSlicingIsNotTerminal() {
        XCTAssertFalse(ScanState.slicing(jobId: "job-1").isTerminal)
    }

    func testReadyToPrintIsNotTerminal() {
        XCTAssertFalse(ScanState.readyToPrint(jobId: "job-1").isTerminal)
    }

    func testPrintingIsNotTerminal() {
        XCTAssertFalse(ScanState.printing(jobId: "job-1").isTerminal)
    }

    func testSavedIsNotTerminal() {
        XCTAssertFalse(ScanState.saved(scanId: UUID()).isTerminal)
    }

    func testCompletedIsTerminal() {
        XCTAssertTrue(ScanState.completed.isTerminal)
    }

    func testFailedIsTerminal() {
        XCTAssertTrue(ScanState.failed(message: "error").isTerminal)
    }

    // MARK: - Equatable conformance

    func testEqualIdleStates() {
        XCTAssertEqual(ScanState.idle, ScanState.idle)
    }

    func testEqualReconstructingStatesWithSameProgress() {
        XCTAssertEqual(
            ScanState.reconstructing(progress: 0.42),
            ScanState.reconstructing(progress: 0.42)
        )
    }

    func testNotEqualReconstructingStatesWithDifferentProgress() {
        XCTAssertNotEqual(
            ScanState.reconstructing(progress: 0.1),
            ScanState.reconstructing(progress: 0.9)
        )
    }

    func testEqualSlicingStatesWithSameJobId() {
        XCTAssertEqual(
            ScanState.slicing(jobId: "abc"),
            ScanState.slicing(jobId: "abc")
        )
    }

    func testNotEqualSlicingStatesWithDifferentJobId() {
        XCTAssertNotEqual(
            ScanState.slicing(jobId: "abc"),
            ScanState.slicing(jobId: "xyz")
        )
    }

    func testNotEqualDifferentVariants() {
        XCTAssertNotEqual(ScanState.idle, ScanState.scanning)
        XCTAssertNotEqual(ScanState.uploading, ScanState.completed)
        XCTAssertNotEqual(ScanState.completed, ScanState.failed(message: "err"))
    }

    func testEqualFailedStatesWithSameMessage() {
        XCTAssertEqual(
            ScanState.failed(message: "oops"),
            ScanState.failed(message: "oops")
        )
    }

    func testNotEqualFailedStatesWithDifferentMessage() {
        XCTAssertNotEqual(
            ScanState.failed(message: "error A"),
            ScanState.failed(message: "error B")
        )
    }
}
