import SwiftUI

struct RootView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        Group {
            if appState.isReady {
                Text("Stillreader")
            } else {
                ProgressView("Loading…")
            }
        }
        .task { await appState.bootstrap() }
    }
}
