import Foundation

/// 跳转安全策略（纯 Foundation，无 UIKit 依赖，可在 macOS 上用 `swift test` 单测）
///
/// 规则：
/// 1. App 链接的 Scheme 必须与报价所属平台一一对应（饿了么只能 eleme://，不能借道 imeituan://）。
/// 2. 网页兜底链接必须是 https，且域名属于该平台自己的白名单。
/// 3. App 打不开时，只回退到「该报价自己的」web_fallback_url，绝不回退到其他平台。
public enum DeepLinkPolicy {

    public enum Decision: Equatable {
        case openApp(URL)
        case openWeb(URL)
        case reject
    }

    public static let allowedSchemes: Set<String> = ["imeituan", "eleme", "taobao"]

    public static func expectedScheme(for platform: PlatformType) -> String {
        switch platform {
        case .meituanWaimai, .meituanShangou: return "imeituan"
        case .eleme: return "eleme"
        case .taobaoShangou: return "taobao"
        }
    }

    public static func allowedFallbackHosts(for platform: PlatformType) -> Set<String> {
        switch platform {
        case .meituanWaimai, .meituanShangou: return ["waimai.meituan.com"]
        case .eleme: return ["h5.ele.me"]
        case .taobaoShangou: return ["s.taobao.com"]
        }
    }

    /// 校验 App 链接：Scheme 必须等于该平台的专属 Scheme
    public static func validatedAppURL(_ raw: String, platform: PlatformType) -> URL? {
        guard let url = URL(string: raw),
              let scheme = url.scheme?.lowercased(),
              scheme == expectedScheme(for: platform) else {
            return nil
        }
        return url
    }

    /// 校验网页兜底链接：必须 https 且域名在该平台白名单内
    public static func validatedFallbackURL(_ raw: String, platform: PlatformType) -> URL? {
        guard let url = URL(string: raw),
              url.scheme?.lowercased() == "https",
              let host = url.host?.lowercased(),
              allowedFallbackHosts(for: platform).contains(host) else {
            return nil
        }
        return url
    }

    /// 决定最终跳转目标。`canOpenApp` 由调用方注入（真机上为 UIApplication.canOpenURL），便于单测。
    public static func plan(
        platform: PlatformType,
        deepLink: String,
        fallbackURL: String,
        canOpenApp: (URL) -> Bool
    ) -> Decision {
        if let appURL = validatedAppURL(deepLink, platform: platform), canOpenApp(appURL) {
            return .openApp(appURL)
        }
        if let webURL = validatedFallbackURL(fallbackURL, platform: platform) {
            return .openWeb(webURL)
        }
        return .reject
    }
}
