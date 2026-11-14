import Foundation

public final class TakeawayAPIService: @unchecked Sendable {
    public static let shared = TakeawayAPIService()

    /// 后端地址保存在 UserDefaults 中：App 界面里修改后，Siri 在后台执行意图时也能读到同一地址。
    /// 真机调试不要用 127.0.0.1（它指向 iPhone 自身），应填电脑局域网 IP，如 http://192.168.1.100:8000
    public static let baseURLDefaultsKey = "serverBaseURL"
    public static let defaultBaseURL = "http://127.0.0.1:8000"

    private let cache: ComparisonCache

    public init(cache: ComparisonCache = .shared) {
        self.cache = cache
    }

    public var baseURL: String {
        UserDefaults.standard.string(forKey: Self.baseURLDefaultsKey) ?? Self.defaultBaseURL
    }

    /// 发起一次新的比价请求，并把结果写入缓存
    public func fetchComparison(keyword: String, address: String = "默认配送地址") async throws -> CompareResponse {
        let response = await requestOrFallback(keyword: keyword, address: address)
        await cache.store(response, for: keyword)
        return response
    }

    /// 优先读缓存（供 SnippetIntent 使用，保证与语音播报同源），未命中再请求
    public func cachedOrFetchComparison(keyword: String) async throws -> CompareResponse {
        if let cached = await cache.response(for: keyword) {
            return cached
        }
        return try await fetchComparison(keyword: keyword)
    }

    private func requestOrFallback(keyword: String, address: String) async -> CompareResponse {
        guard let url = URL(string: "\(baseURL)/api/v1/compare") else {
            return generateLocalFallbackQuote(keyword: keyword, reason: "后端地址格式错误")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 5.0

        do {
            request.httpBody = try JSONSerialization.data(
                withJSONObject: ["keyword": keyword, "address": address],
                options: []
            )
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                return generateLocalFallbackQuote(keyword: keyword, reason: "后端返回非 2xx 状态")
            }
            return try JSONDecoder().decode(CompareResponse.self, from: data)
        } catch {
            // 网络失败时进入离线演示数据，并显式标记 is_simulated = true，UI 会显示警告
            return generateLocalFallbackQuote(keyword: keyword, reason: "网络未连通：\(error.localizedDescription)")
        }
    }

    /// 本地离线演示数据（明确标识为仿真）
    private func generateLocalFallbackQuote(keyword: String, reason: String) -> CompareResponse {
        let kw = keyword.isEmpty ? "精选餐品" : keyword
        let encoded = kw.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        let meituanQuote = PlatformQuote(
            platform_id: .meituanWaimai,
            platform_name: "美团外卖",
            shop_name: "\(kw)专营店(美团专送)",
            item_name: kw,
            item_specs: "标准规格",
            item_image: nil,
            price: PriceBreakdown(origin_price: 25.0, shop_discount: 6.0, coupon_discount: 4.0, delivery_fee: 3.5, package_fee: 1.5, final_price: 20.0),
            delivery_eta_minutes: 28,
            shop_rating: 4.9,
            monthly_sales: 3200,
            deep_link: "imeituan://www.meituan.com/waimai/search?keyword=\(encoded)",
            web_fallback_url: "https://waimai.meituan.com",
            is_best_deal: false,
            saved_amount: 0.0,
            highlights: ["美团神券立减"]
        )

        let elemeQuote = PlatformQuote(
            platform_id: .eleme,
            platform_name: "饿了么",
            shop_name: "\(kw)旗舰店(蜂鸟即配)",
            item_name: kw,
            item_specs: "标准规格",
            item_image: nil,
            price: PriceBreakdown(origin_price: 25.0, shop_discount: 8.0, coupon_discount: 4.0, delivery_fee: 3.0, package_fee: 1.5, final_price: 17.5),
            delivery_eta_minutes: 25,
            shop_rating: 4.85,
            monthly_sales: 2900,
            deep_link: "eleme://search?keyword=\(encoded)",
            web_fallback_url: "https://h5.ele.me",
            is_best_deal: false,
            saved_amount: 2.5,
            highlights: ["超级吃货红包"]
        )

        let shangouQuote = PlatformQuote(
            platform_id: .meituanShangou,
            platform_name: "美团闪购",
            shop_name: "连锁便利闪购极速仓",
            item_name: kw,
            item_specs: "现货极速达",
            item_image: nil,
            price: PriceBreakdown(origin_price: 20.0, shop_discount: 6.0, coupon_discount: 3.0, delivery_fee: 2.0, package_fee: 0.5, final_price: 13.5),
            delivery_eta_minutes: 20,
            shop_rating: 4.95,
            monthly_sales: 4600,
            deep_link: "imeituan://www.meituan.com/takeaway/shangou/search?keyword=\(encoded)",
            web_fallback_url: "https://waimai.meituan.com/shangou",
            is_best_deal: true,
            saved_amount: 6.5,
            highlights: ["20分钟极速达", "包装仅0.5元"]
        )

        let taobaoQuote = PlatformQuote(
            platform_id: .taobaoShangou,
            platform_name: "淘宝闪购",
            shop_name: "淘鲜达小时达专营店",
            item_name: kw,
            item_specs: "正品小时达",
            item_image: nil,
            price: PriceBreakdown(origin_price: 22.0, shop_discount: 5.0, coupon_discount: 3.0, delivery_fee: 2.5, package_fee: 0.5, final_price: 17.0),
            delivery_eta_minutes: 22,
            shop_rating: 4.88,
            monthly_sales: 3800,
            deep_link: "taobao://s.taobao.com/search?q=\(encoded)&tab=takeaway",
            web_fallback_url: "https://s.taobao.com",
            is_best_deal: false,
            saved_amount: 3.0,
            highlights: ["淘金币立减"]
        )

        return CompareResponse(
            query: kw,
            timestamp: "离线本地时间",
            quotes: [shangouQuote, taobaoQuote, elemeQuote, meituanQuote],
            best_quote: shangouQuote,
            max_saved_amount: 6.5,
            voice_speech_text: "当前是离线演示数据。最划算的是美团闪购，到手13.5元，比美团外卖省6.5元。",
            summary: "【离线演示】美团闪购最低价 ¥13.5，最高节省 ¥6.5",
            is_simulated: true,
            failed_platforms: [reason]
        )
    }
}
