import Foundation

struct UploadResponse: Codable {
    let jobId: String
    let status: String
}

struct StatusResponse: Codable {
    let jobId: String
    let status: String
    let error: String?
    let createdAt: Double?
    let updatedAt: Double?
}

struct PrintResponse: Codable {
    let jobId: String
    let status: String
    let message: String?
}
