import Foundation

enum StatePruner {
    /// Prunes read entries by age and count. `read_later` entries are never removed.
    static func prune(
        _ state: FeedState,
        retentionDays: Int = StoragePath.stateReadRetentionDays,
        maxReadEntries: Int = StoragePath.stateMaxReadEntries,
        now: Date = Date()
    ) -> FeedState {
        var result = state
        let cutoff = Calendar.current.date(byAdding: .day, value: -retentionDays, to: now) ?? now

        let preserved = state.items.filter { $0.status != .read }
        var readItems = state.items.filter { $0.status == .read }

        readItems = readItems.filter { item in
            guard let readAt = item.readAt else { return true }
            return readAt >= cutoff
        }

        if readItems.count > maxReadEntries {
            readItems = readItems
                .sorted { ($0.readAt ?? .distantPast) > ($1.readAt ?? .distantPast) }
                .prefix(maxReadEntries)
                .map { $0 }
        }

        result.items = preserved + readItems
        result.updated = now
        return result
    }
}
