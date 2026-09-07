import Foundation

/// A device-local identity. It deliberately is not an account system; it gives local records a
/// stable owner until a future sync/authentication layer is introduced.
enum LocalIdentity {
    private static let key = "lostandfound.local-user-id"

    static var userID: String {
        if let id = UserDefaults.standard.string(forKey: key) { return id }
        let id = UUID().uuidString
        UserDefaults.standard.set(id, forKey: key)
        return id
    }
}
