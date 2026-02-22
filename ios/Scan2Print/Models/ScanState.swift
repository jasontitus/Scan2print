import Foundation

enum ScanState: Equatable {
    case idle
    case scanning
    case reconstructing(progress: Double)
    case uploading
    case slicing(jobId: String)
    case readyToPrint(jobId: String)
    case printing(jobId: String)
    case saved(scanId: UUID)
    case completed
    case failed(message: String)

    var isTerminal: Bool {
        switch self {
        case .completed, .failed:
            return true
        default:
            return false
        }
    }
}
