import Foundation

enum Config {
    /// Base URL for the Scan2Print backend server.
    /// Change this to your Mac's local IP when running on a real device.
    static let backendURL = URL(string: "http://192.168.1.100:3000")!
}
