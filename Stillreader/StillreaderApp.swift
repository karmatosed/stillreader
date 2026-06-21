import SwiftUI

@main
struct StillreaderApp: App {
    @StateObject private var appState = AppState()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .calmTheme()
                .task {
                    await appState.prepareOnFirstAppear()
                }
                .onChange(of: scenePhase) { _, phase in
                    guard phase == .active else { return }
                    Task { await appState.syncOnForeground() }
                }
        }
    }
}
