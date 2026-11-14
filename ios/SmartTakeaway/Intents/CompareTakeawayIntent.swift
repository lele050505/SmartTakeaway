import AppIntents
import SwiftUI

// 注意：SnippetIntent / ShowsSnippetIntent 需要 iOS 26+，App 的 Deployment Target 请设为 iOS 26.0。

/// 承载可交互卡片的 SnippetIntent（按钮可点击的 Snippet 必须由 SnippetIntent 提供）
///
/// 读取 ComparisonCache 中主意图刚写入的同一份结果，
/// 保证卡片报价与 Siri 语音播报一致，且不重复请求后端。
public struct TakeawayComparisonSnippetIntent: SnippetIntent {
    public static let title: LocalizedStringResource = "外卖比价卡片"
    public static let isDiscoverable: Bool = false

    @Parameter(title: "搜索关键词")
    public var keyword: String

    public init() {}

    public init(keyword: String) {
        self.keyword = keyword
    }

    public func perform() async throws -> some IntentResult & ShowsSnippetView {
        let response = try await TakeawayAPIService.shared.cachedOrFetchComparison(keyword: keyword)
        return .result(view: ComparisonSnippetView(response: response))
    }
}

/// 自由输入的比价意图：Siri 会追问「你想比价什么？」
/// （App Shortcut 短语里不能直接放 String 参数，只能放 AppEnum / AppEntity）
public struct CompareTakeawayIntent: AppIntent {
    public static let title: LocalizedStringResource = "外卖比价下单"
    public static let description = IntentDescription("比对美团外卖、饿了么、美团闪购、淘宝闪购的到手价，并跳转到最划算的平台下单")

    @Parameter(
        title: "餐品或商品名称",
        requestValueDialog: IntentDialog("你想比价什么？比如生椰拿铁、可口可乐")
    )
    public var keyword: String

    public init() {}

    public init(keyword: String) {
        self.keyword = keyword
    }

    public func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetIntent {
        // 只在这里请求一次；结果写入缓存，SnippetIntent 复用
        let response = try await TakeawayAPIService.shared.fetchComparison(keyword: keyword)
        return .result(
            dialog: "\(response.voice_speech_text)",
            snippetIntent: TakeawayComparisonSnippetIntent(keyword: keyword)
        )
    }
}

/// 常点商品：用 AppEnum 才能在 Siri 短语里一句话带参数，例如「用外卖智能比价比价生椰拿铁」
public enum PopularItem: String, AppEnum {
    case coconutLatte = "生椰拿铁"
    case icedAmericano = "冰美式"
    case coke = "可口可乐"
    case mcdonalds = "麦当劳"
    case chagee = "霸王茶姬"
    case tissue = "抽纸"

    public static let typeDisplayRepresentation: TypeDisplayRepresentation = "常点商品"
    public static let caseDisplayRepresentations: [PopularItem: DisplayRepresentation] = [
        .coconutLatte: "生椰拿铁",
        .icedAmericano: "冰美式",
        .coke: "可口可乐",
        .mcdonalds: "麦当劳",
        .chagee: "霸王茶姬",
        .tissue: "抽纸"
    ]
}

public struct QuickCompareIntent: AppIntent {
    public static let title: LocalizedStringResource = "常点商品一键比价"
    public static let description = IntentDescription("一句话比价常点商品")

    @Parameter(title: "商品")
    public var item: PopularItem

    public init() {}

    public func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetIntent {
        let keyword = item.rawValue
        let response = try await TakeawayAPIService.shared.fetchComparison(keyword: keyword)
        return .result(
            dialog: "\(response.voice_speech_text)",
            snippetIntent: TakeawayComparisonSnippetIntent(keyword: keyword)
        )
    }
}
