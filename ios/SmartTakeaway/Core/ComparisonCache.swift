import Foundation

/// 比价结果短期缓存
///
/// 作用：主意图（CompareTakeawayIntent）请求一次比价后写入缓存，
/// SnippetIntent 渲染卡片时优先读取同一份结果，
/// 从而避免重复请求，并保证「Siri 语音播报」与「卡片报价」来自同一次响应。
public actor ComparisonCache {
    public static let shared = ComparisonCache()

    private struct Entry {
        let response: CompareResponse
        let storedAt: Date
    }

    private var entries: [String: Entry] = [:]
    private let ttl: TimeInterval
    private let now: @Sendable () -> Date

    public init(ttl: TimeInterval = 120, now: @escaping @Sendable () -> Date = { Date() }) {
        self.ttl = ttl
        self.now = now
    }

    public static func key(for keyword: String) -> String {
        keyword.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    public func store(_ response: CompareResponse, for keyword: String) {
        entries[Self.key(for: keyword)] = Entry(response: response, storedAt: now())
    }

    /// 命中且未过期则返回；过期条目会被清除
    public func response(for keyword: String) -> CompareResponse? {
        let k = Self.key(for: keyword)
        guard let entry = entries[k] else { return nil }
        if now().timeIntervalSince(entry.storedAt) > ttl {
            entries[k] = nil
            return nil
        }
        return entry.response
    }
}
