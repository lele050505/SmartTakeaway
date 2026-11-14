import AppIntents
import UIKit

enum OpenTakeawayError: Error, CustomLocalizedStringResourceConvertible {
    case invalidPlatform
    case rejectedURL

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .invalidPlatform: return "未知的外卖平台"
        case .rejectedURL: return "跳转链接不在允许范围内，已拦截"
        }
    }
}

/// 卡片中「去下单」按钮触发的意图（不在快捷指令中单独展示）
///
/// - 只接受与报价平台匹配的 Scheme（见 DeepLinkPolicy）
/// - App 打不开时，只回退到该报价自己的 web_fallback_url，不会把饿了么/淘宝回退到美团
public struct OpenTakeawayURLIntent: AppIntent {
    public static let title: LocalizedStringResource = "前往外卖平台下单"
    public static let isDiscoverable: Bool = false
    public static let openAppWhenRun: Bool = true

    @Parameter(title: "平台")
    public var platformID: String

    @Parameter(title: "App 链接")
    public var deepLink: String

    @Parameter(title: "网页兜底链接")
    public var fallbackURL: String

    public init() {}

    public init(quote: PlatformQuote) {
        self.platformID = quote.platform_id.rawValue
        self.deepLink = quote.deep_link
        self.fallbackURL = quote.web_fallback_url
    }

    @MainActor
    public func perform() async throws -> some IntentResult {
        guard let platform = PlatformType(rawValue: platformID) else {
            throw OpenTakeawayError.invalidPlatform
        }

        let decision = DeepLinkPolicy.plan(
            platform: platform,
            deepLink: deepLink,
            fallbackURL: fallbackURL,
            canOpenApp: { UIApplication.shared.canOpenURL($0) }
        )

        switch decision {
        case .openApp(let appURL):
            let opened = await UIApplication.shared.open(appURL)
            if !opened, let webURL = DeepLinkPolicy.validatedFallbackURL(fallbackURL, platform: platform) {
                _ = await UIApplication.shared.open(webURL)
            }
        case .openWeb(let webURL):
            _ = await UIApplication.shared.open(webURL)
        case .reject:
            throw OpenTakeawayError.rejectedURL
        }
        return .result()
    }
}
