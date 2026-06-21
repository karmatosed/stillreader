import UIKit
import UniformTypeIdentifiers

final class ShareViewController: UIViewController {
    private let statusLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        statusLabel.text = "Saving to Stillreader…"
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statusLabel)

        NSLayoutConstraint.activate([
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            statusLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])

        Task { await handleShare() }
    }

    @MainActor
    private func handleShare() async {
        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
              let provider = extensionItem.attachments?.first(where: {
                  $0.hasItemConformingToTypeIdentifier(UTType.url.identifier)
              })
        else {
            finish(message: "No URL found")
            return
        }

        do {
            let item = try await provider.loadItem(forTypeIdentifier: UTType.url.identifier)
            guard let url = extractURL(from: item) else {
                finish(message: "Could not read URL")
                return
            }

            let title = await fetchTitle(for: url) ?? url.host ?? "Saved link"
            let (storage, _) = SharedStorageRoot.makeStorage()
            _ = try await LinkSaver.save(url: url, title: title, storage: storage)
            finish(message: "Saved to Stillreader")
        } catch {
            finish(message: error.localizedDescription)
        }
    }

    private func extractURL(from item: NSSecureCoding?) -> URL? {
        if let url = item as? URL { return url }
        if let string = item as? String { return URL(string: string) }
        return nil
    }

    private func fetchTitle(for url: URL) async -> String? {
        var request = URLRequest(url: url)
        request.setValue("Stillreader/1.0", forHTTPHeaderField: "User-Agent")
        guard let (data, _) = try? await URLSession.shared.data(for: request),
              let html = String(data: data, encoding: .utf8)
        else { return nil }

        if let range = html.range(of: "<title>", options: .caseInsensitive),
           let end = html.range(of: "</title>", options: .caseInsensitive, range: range.upperBound..<html.endIndex) {
            return String(html[range.upperBound..<end.lowerBound])
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return nil
    }

    @MainActor
    private func finish(message: String) {
        statusLabel.text = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            self.extensionContext?.completeRequest(returningItems: nil)
        }
    }
}
