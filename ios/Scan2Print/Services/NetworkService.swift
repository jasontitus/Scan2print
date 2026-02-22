import Foundation

class NetworkService {
    private let baseURL = Config.backendURL

    // MARK: - Upload .obj file

    func upload(fileURL: URL) async throws -> UploadResponse {
        let url = baseURL.appending(path: "upload")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        let fileData = try Data(contentsOf: fileURL)
        let fileName = fileURL.lastPathComponent

        var body = Data()
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"model\"; filename=\"\(fileName)\"\r\n")
        body.append("Content-Type: application/octet-stream\r\n\r\n")
        body.append(fileData)
        body.append("\r\n--\(boundary)--\r\n")

        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 202 else {
            throw NetworkError.uploadFailed
        }

        return try JSONDecoder().decode(UploadResponse.self, from: data)
    }

    // MARK: - Poll status

    func pollUntilSliced(jobId: String) async throws -> StatusResponse {
        let url = baseURL.appending(path: "status/\(jobId)")

        while true {
            let (data, _) = try await URLSession.shared.data(from: url)
            let status = try JSONDecoder().decode(StatusResponse.self, from: data)

            switch status.status {
            case "sliced":
                return status
            case "failed":
                throw NetworkError.slicingFailed(status.error ?? "Unknown error")
            default:
                try await Task.sleep(for: .seconds(2))
            }
        }
    }

    // MARK: - Trigger print

    func triggerPrint(jobId: String) async throws -> PrintResponse {
        let url = baseURL.appending(path: "print/\(jobId)")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NetworkError.printFailed
        }

        return try JSONDecoder().decode(PrintResponse.self, from: data)
    }
}

enum NetworkError: LocalizedError {
    case uploadFailed
    case slicingFailed(String)
    case printFailed

    var errorDescription: String? {
        switch self {
        case .uploadFailed:
            return "Failed to upload model to server"
        case .slicingFailed(let reason):
            return "Slicing failed: \(reason)"
        case .printFailed:
            return "Failed to send print command"
        }
    }
}

private extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
