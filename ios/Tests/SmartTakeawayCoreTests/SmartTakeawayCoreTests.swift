import XCTest
@testable import SmartTakeawayCore

final class PriceBreakdownTests: XCTestCase {
    private func make(shop: Double, coupon: Double) -> PriceBreakdown {
        PriceBreakdown(
            origin_price: 30,
            shop_discount: shop,
            coupon_discount: coupon,
            delivery_fee: 3,
            package_fee: 1,
            final_price: 30 - shop - coupon + 3 + 1
        )
    }

    /// 回归用例：旧实现 shop + coupon * 100 会把 6 + 4 算成约 4.06
    func testTotalDiscountAddsBeforeRounding() {
        XCTAssertEqual(make(shop: 6, coupon: 4).totalDiscount, 10, accuracy: 0.0001)
    }

    func testTotalDiscountFloatingPrecision() {
        XCTAssertEqual(make(shop: 5.25, coupon: 3.35).totalDiscount, 8.6, accuracy: 0.0001)
    }

    func testTotalDiscountZeroAndSingleSide() {
        XCTAssertEqual(make(shop: 0, coupon: 0).totalDiscount, 0, accuracy: 0.0001)
        XCTAssertEqual(make(shop: 0, coupon: 5).totalDiscount, 5, accuracy: 0.0001)
        XCTAssertEqual(make(shop: 7.5, coupon: 0).totalDiscount, 7.5, accuracy: 0.0001)
    }

    func testCompareResponseDecodesWithoutOptionalFields() throws {
        // 旧版后端没有 is_simulated / failed_platforms 字段时也应能解码
        let json = """
        {"query":"可乐","timestamp":"t","quotes":[],"best_quote":null,
         "max_saved_amount":0,"voice_speech_text":"v","summary":"s"}
        """.data(using: .utf8)!
        let resp = try JSONDecoder().decode(CompareResponse.self, from: json)
        XCTAssertTrue(resp.is_simulated)
        XCTAssertTrue(resp.failed_platforms.isEmpty)
    }
}

final class DeepLinkPolicyTests: XCTestCase {
    private let always: (URL) -> Bool = { _ in true }
    private let never: (URL) -> Bool = { _ in false }

    func testOpensAppWhenSchemeMatchesPlatformAndInstalled() {
        let d = DeepLinkPolicy.plan(platform: .eleme,
                                    deepLink: "eleme://search?keyword=a",
                                    fallbackURL: "https://h5.ele.me",
                                    canOpenApp: always)
        XCTAssertEqual(d, .openApp(URL(string: "eleme://search?keyword=a")!))
    }

    /// 回归用例：饿了么 App 未安装时必须回退到饿了么网页，而不是美团
    func testElemeFallsBackToOwnWebNotMeituan() {
        let d = DeepLinkPolicy.plan(platform: .eleme,
                                    deepLink: "eleme://search?keyword=a",
                                    fallbackURL: "https://h5.ele.me/msite/search",
                                    canOpenApp: never)
        XCTAssertEqual(d, .openWeb(URL(string: "https://h5.ele.me/msite/search")!))
    }

    func testTaobaoFallsBackToOwnWeb() {
        let d = DeepLinkPolicy.plan(platform: .taobaoShangou,
                                    deepLink: "taobao://s.taobao.com/search?q=a",
                                    fallbackURL: "https://s.taobao.com/search?q=a",
                                    canOpenApp: never)
        XCTAssertEqual(d, .openWeb(URL(string: "https://s.taobao.com/search?q=a")!))
    }

    func testRejectsSchemeOfAnotherPlatform() {
        // 饿了么报价却给了美团 Scheme：不允许打开，且兜底域名也不匹配 → 拒绝
        let d = DeepLinkPolicy.plan(platform: .eleme,
                                    deepLink: "imeituan://www.meituan.com/waimai",
                                    fallbackURL: "https://waimai.meituan.com",
                                    canOpenApp: always)
        XCTAssertEqual(d, .reject)
    }

    func testRejectsArbitraryAndDangerousURLs() {
        for raw in ["javascript:alert(1)", "http://h5.ele.me", "https://evil.example.com", "tel:110", ""] {
            XCTAssertNil(DeepLinkPolicy.validatedAppURL(raw, platform: .eleme), raw)
            XCTAssertNil(DeepLinkPolicy.validatedFallbackURL(raw, platform: .eleme), raw)
        }
    }

    func testMeituanShangouSharesMeituanScheme() {
        XCTAssertNotNil(DeepLinkPolicy.validatedAppURL("imeituan://www.meituan.com/takeaway/shangou/search", platform: .meituanShangou))
        XCTAssertNotNil(DeepLinkPolicy.validatedFallbackURL("https://waimai.meituan.com/shangou", platform: .meituanShangou))
    }
}

final class ComparisonCacheTests: XCTestCase {
    private func response(_ q: String) -> CompareResponse {
        CompareResponse(query: q, timestamp: "t", quotes: [], best_quote: nil,
                        max_saved_amount: 0, voice_speech_text: "v-\(q)", summary: "s",
                        is_simulated: true, failed_platforms: [])
    }

    func testHitReturnsSameResponseForNormalizedKeyword() async {
        let cache = ComparisonCache(ttl: 60)
        await cache.store(response("生椰拿铁"), for: "  生椰拿铁 ")
        let hit = await cache.response(for: "生椰拿铁")
        XCTAssertEqual(hit?.voice_speech_text, "v-生椰拿铁")
    }

    func testExpiredEntryIsEvicted() async {
        let clock = MutableClock()
        let cache = ComparisonCache(ttl: 10, now: { clock.now })
        await cache.store(response("可乐"), for: "可乐")
        clock.advance(by: 11)
        let hit = await cache.response(for: "可乐")
        XCTAssertNil(hit)
    }

    func testMissForUnknownKeyword() async {
        let cache = ComparisonCache()
        let hit = await cache.response(for: "不存在")
        XCTAssertNil(hit)
    }
}

/// 测试用可控时钟
final class MutableClock: @unchecked Sendable {
    private let lock = NSLock()
    private var current = Date(timeIntervalSince1970: 0)

    var now: Date {
        lock.lock(); defer { lock.unlock() }
        return current
    }

    func advance(by seconds: TimeInterval) {
        lock.lock(); defer { lock.unlock() }
        current = current.addingTimeInterval(seconds)
    }
}
