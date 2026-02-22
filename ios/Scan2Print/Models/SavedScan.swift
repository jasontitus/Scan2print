import Foundation

enum UploadStatus: Codable, Equatable {
    case local
    case uploading
    case slicing(jobId: String)
    case readyToPrint(jobId: String)
    case printing(jobId: String)
    case printed
    case failed(message: String)

    /// Resets transient states (uploading) back to local on app launch.
    var resetIfTransient: UploadStatus {
        switch self {
        case .uploading:
            return .local
        default:
            return self
        }
    }
}

struct SavedScan: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    let dateCreated: Date
    var uploadStatus: UploadStatus
}
