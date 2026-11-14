import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/takeaway_models.dart';

class TakeawayApiService {
  static const String _baseUrlKey = 'server_base_url';
  static const String _addressKey = 'default_delivery_address';

  /// Android 模拟器访问宿主机 (Windows) 默认地址为 10.0.2.2
  /// 真机调试请改为宿主机局域网 IP（如 http://192.168.1.100:8000）
  static const String defaultEmulatorUrl = 'http://10.0.2.2:8000';

  Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_baseUrlKey) ?? defaultEmulatorUrl;
  }

  Future<void> setBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlKey, url.trim());
  }

  Future<String> getAddress() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_addressKey) ?? '默认配送地址';
  }

  Future<void> setAddress(String address) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_addressKey, address.trim());
  }

  Future<bool> checkHealth(String baseUrl) async {
    try {
      final uri = Uri.parse('$baseUrl/api/v1/health');
      final res = await http.get(uri).timeout(const Duration(seconds: 3));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<CompareResponse> compare({
    required String keyword,
    String? address,
  }) async {
    final baseUrl = await getBaseUrl();
    final targetAddress = address ?? await getAddress();

    try {
      final uri = Uri.parse('$baseUrl/api/v1/compare');
      final res = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'keyword': keyword.trim(),
              'address': targetAddress,
            }),
          )
          .timeout(const Duration(seconds: 5));

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final decoded = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        return CompareResponse.fromJson(decoded);
      }
      return _offlineFallback(keyword, '后端返回状态码 ${res.statusCode}');
    } catch (e) {
      return _offlineFallback(keyword, '未连通后端 ($baseUrl): $e');
    }
  }

  CompareResponse _offlineFallback(String keyword, String reason) {
    final kw = keyword.trim().isEmpty ? '精选餐品' : keyword.trim();
    final encoded = Uri.encodeQueryComponent(kw);

    const pMeituan = PriceBreakdown(
      originPrice: 25.0,
      shopDiscount: 6.0,
      couponDiscount: 4.0,
      deliveryFee: 3.5,
      packageFee: 1.5,
      finalPrice: 20.0,
    );
    const pEleme = PriceBreakdown(
      originPrice: 25.0,
      shopDiscount: 8.0,
      couponDiscount: 4.0,
      deliveryFee: 3.0,
      packageFee: 1.5,
      finalPrice: 17.5,
    );
    const pShangou = PriceBreakdown(
      originPrice: 20.0,
      shopDiscount: 6.0,
      couponDiscount: 3.0,
      deliveryFee: 2.0,
      packageFee: 0.5,
      finalPrice: 13.5,
    );
    const pTaobao = PriceBreakdown(
      originPrice: 22.0,
      shopDiscount: 5.0,
      couponDiscount: 3.0,
      deliveryFee: 2.5,
      packageFee: 0.5,
      finalPrice: 17.0,
    );

    final quotes = [
      PlatformQuote(
        platformId: PlatformType.meituanShangou,
        platformName: '美团闪购',
        shopName: '连锁便利闪购极速仓',
        itemName: kw,
        itemSpecs: '现货极速达',
        price: pShangou,
        deliveryEtaMinutes: 20,
        shopRating: 4.95,
        monthlySales: 4600,
        deepLink: 'imeituan://www.meituan.com/takeaway/shangou/search?keyword=$encoded',
        webFallbackUrl: 'https://waimai.meituan.com/shangou/search?keyword=$encoded',
        isBestDeal: true,
        savedAmount: 6.5,
        highlights: const ['20分钟极速达', '包装费仅0.5元'],
      ),
      PlatformQuote(
        platformId: PlatformType.taobaoShangou,
        platformName: '淘宝闪购',
        shopName: '淘鲜达小时达专营店',
        itemName: kw,
        itemSpecs: '正品小时达',
        price: pTaobao,
        deliveryEtaMinutes: 22,
        shopRating: 4.88,
        monthlySales: 3800,
        deepLink: 'taobao://s.taobao.com/search?q=$encoded&tab=takeaway',
        webFallbackUrl: 'https://s.taobao.com/search?q=$encoded',
        isBestDeal: false,
        savedAmount: 3.0,
        highlights: const ['淘金币立减'],
      ),
      PlatformQuote(
        platformId: PlatformType.eleme,
        platformName: '饿了么',
        shopName: '$kw旗舰店(蜂鸟即配)',
        itemName: kw,
        itemSpecs: '标准规格',
        price: pEleme,
        deliveryEtaMinutes: 25,
        shopRating: 4.85,
        monthlySales: 2900,
        deepLink: 'eleme://search?keyword=$encoded',
        webFallbackUrl: 'https://h5.ele.me/msite/search?keyword=$encoded',
        isBestDeal: false,
        savedAmount: 2.5,
        highlights: const ['超级吃货红包'],
      ),
      PlatformQuote(
        platformId: PlatformType.meituanWaimai,
        platformName: '美团外卖',
        shopName: '$kw专营店(美团专送)',
        itemName: kw,
        itemSpecs: '标准规格',
        price: pMeituan,
        deliveryEtaMinutes: 28,
        shopRating: 4.90,
        monthlySales: 3200,
        deepLink: 'imeituan://www.meituan.com/waimai/search?keyword=$encoded',
        webFallbackUrl: 'https://waimai.meituan.com/search?q=$encoded',
        isBestDeal: false,
        savedAmount: 0.0,
        highlights: const ['美团神券立减'],
      ),
    ];

    return CompareResponse(
      query: kw,
      timestamp: '本地离线时间',
      quotes: quotes,
      bestQuote: quotes.first,
      maxSavedAmount: 6.5,
      voiceSpeechText: '当前为离线演示数据。最划算的是美团闪购，到手13.5元，比美团外卖省6.5元。',
      summary: '【离线演示】美团闪购最低价 ¥13.5，最高节省 ¥6.5',
      isSimulated: true,
      failedPlatforms: [reason],
    );
  }

  Future<CouponClaimAllResponse> claimAllCoupons() async {
    final baseUrl = await getBaseUrl();
    try {
      final uri = Uri.parse('$baseUrl/api/v1/coupons/claim-all');
      final res = await http
          .post(uri, headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 5));
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final decoded =
            jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        return CouponClaimAllResponse.fromJson(decoded);
      }
    } catch (_) {}

    return const CouponClaimAllResponse(
      timestamp: '本地离线领券',
      totalClaimedAmount: 29.0,
      claimedCount: 4,
      isSimulated: true,
      coupons: [
        CouponClaimItem(
          platformId: PlatformType.meituanWaimai,
          platformName: '美团外卖',
          couponTitle: '美团神券 · 满25减8',
          discountAmount: 8.0,
          minSpend: 25.0,
          claimed: true,
          message: '已自动放入卡包',
          deepLink: 'imeituan://www.meituan.com/waimai/coupon',
          webFallbackUrl: 'https://waimai.meituan.com/',
        ),
        CouponClaimItem(
          platformId: PlatformType.eleme,
          platformName: '饿了么',
          couponTitle: '吃货红包 · 满28减10',
          discountAmount: 10.0,
          minSpend: 28.0,
          claimed: true,
          message: '已自动领取',
          deepLink: 'eleme://coupon',
          webFallbackUrl: 'https://h5.ele.me/',
        ),
        CouponClaimItem(
          platformId: PlatformType.meituanShangou,
          platformName: '美团闪购',
          couponTitle: '闪购补贴 · 满20减6',
          discountAmount: 6.0,
          minSpend: 20.0,
          claimed: true,
          message: '已激活免配叠加',
          deepLink: 'imeituan://www.meituan.com/takeaway/shangou',
          webFallbackUrl: 'https://waimai.meituan.com/',
        ),
        CouponClaimItem(
          platformId: PlatformType.taobaoShangou,
          platformName: '淘宝闪购',
          couponTitle: '小时达券 · 满19减5',
          discountAmount: 5.0,
          minSpend: 19.0,
          claimed: true,
          message: '已自动绑定',
          deepLink: 'taobao://s.taobao.com/search?tab=takeaway',
          webFallbackUrl: 'https://s.taobao.com/',
        ),
      ],
    );
  }
}
