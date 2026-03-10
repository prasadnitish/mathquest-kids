import Foundation

enum NetworkGuard {
    static func assertOfflineOnly() {
        precondition(FeatureFlags.networkDisabled, "V1 requires offline-only mode.")
    }
}
