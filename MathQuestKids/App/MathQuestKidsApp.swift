import AVFoundation
import SwiftUI

@main
struct MathQuestKidsApp: App {
    @StateObject private var appState = AppState()

    init() {
        configureAudioSession()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .preferredColorScheme(.light)
        }
    }

    private func configureAudioSession() {
        #if os(iOS)
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, options: [.mixWithOthers, .duckOthers])
            try session.setActive(true)
        } catch {
            // Audio will use default session; non-fatal on simulator
        }
        #endif
    }
}
