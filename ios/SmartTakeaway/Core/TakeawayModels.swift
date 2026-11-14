import Foundation

public enum PlatformType: String, Codable, CaseIterable, Sendable {
    case meituanWaimai = "meituan_waimai"
    case eleme = "eleme"
    case meituanShangou = "meituan_shangou"
    case taobaoShangou = "taobao_shangou"
    
    public var displayName: String {
        switch self {
        case .meituanWaimai: return "美团外卖"
        case .eleme: return "饿了么"
        case .meituanShangou: return "美团闪购"
        case .taobaoShangou: return "淘宝闪购"
        }
    }
    
    public var themeColorHex: String {
        switch self {
        case .meituanWaimai: return "#FFD101"
        case .eleme: return "#0092FF"
        case .meituanShangou: return "#FF9900"
        case .taobaoShangou: return "#FF5000"
        }
    }
}

public struct PriceBreakdown: Codable, Hashable, Sendable {
    public let origin_price: Double
    public let shop_discount: Double
    public let coupon_discount: Double
    public let delivery_fee: Double
    public let package_fee: Double
    public let final_price: Double
    
    public var totalDiscount: Double {
        // 严格保证先相加再按分舍入，避免运算符优先级导致的乘除错误
        return ((shop_discount + coupon_discount) * 100).rounded() / 100
    }
}

public struct PlatformQuote: Codable, Identifiable, Hashable, Sendable {
    public var id: String { platform_id.rawValue + shop_name }
    public let platform_id: PlatformType
    public let platform_name: String
    public let shop_name: String
    public let item_name: String
    public let item_specs: String?
    public let item_image: String?
    public let price: PriceBreakdown
    public let delivery_eta_minutes: Int
    public let shop_rating: Double
    public let monthly_sales: Int
    public let deep_link: String
    public let web_fallback_url: String
    public let is_best_deal: Bool
    public let saved_amount: Double
    public let highlights: [String]
}

public struct CompareResponse: Codable, Sendable {
    public let query: String
    public let timestamp: String
    public let quotes: [PlatformQuote]
    public let best_quote: PlatformQuote?
    public let max_saved_amount: Double
    public let voice_speech_text: String
    public let summary: String
    public let is_simulated: Bool
    public let failed_platforms: [String]
    
    enum CodingKeys: String, CodingKey {
        case query, timestamp, quotes, best_quote, max_saved_amount, voice_speech_text, summary
        case is_simulated = "is_simulated"
        case failed_platforms = "failed_platforms"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        query = try container.decode(String.self, forKey: .query)
        timestamp = try container.decode(String.self, forKey: .timestamp)
        quotes = try container.decode([PlatformQuote].self, forKey: .quotes)
        best_quote = try container.decodeIfPresent(PlatformQuote.self, forKey: .best_quote)
        max_saved_amount = try container.decode(Double.self, forKey: .max_saved_amount)
        voice_speech_text = try container.decode(String.self, forKey: .voice_speech_text)
        summary = try container.decode(String.self, forKey: .summary)
        is_simulated = try container.decodeIfPresent(Bool.self, forKey: .is_simulated) ?? true
        failed_platforms = try container.decodeIfPresent([String].self, forKey: .failed_platforms) ?? []
    }
    
    public init(
        query: String,
        timestamp: String,
        quotes: [PlatformQuote],
        best_quote: PlatformQuote?,
        max_saved_amount: Double,
        voice_speech_text: String,
        summary: String,
        is_simulated: Bool,
        failed_platforms: [String]
    ) {
        self.query = query
        self.timestamp = timestamp
        self.quotes = quotes
        self.best_quote = best_quote
        self.max_saved_amount = max_saved_amount
        self.voice_speech_text = voice_speech_text
        self.summary = summary
        self.is_simulated = is_simulated
        self.failed_platforms = failed_platforms
    }
}
