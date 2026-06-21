import Combine
import Foundation

@MainActor
final class AppState: ObservableObject {
    @Published var isReady = false
    @Published var syncIssues: [String] = []

    // Wired in Task 8
    func bootstrap() async {
        isReady = true
    }
}
