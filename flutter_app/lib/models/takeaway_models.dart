import 'package:flutter/material.dart';

enum PlatformType {
  meituanWaimai('meituan_waimai', '美团外卖', Color(0xFFFFB800)),
  eleme('eleme', '饿了么', Color(0xFF0092FF)),
  meituanShangou('meituan_shangou', '美团闪购', Color(0xFFFF8800)),
  taobaoShangou('taobao_shangou', '淘宝闪购', Color(0xFFFF5000));

  final String id;
  final String displayName;
  final Color brandColor;

  const PlatformType(this.id, this.displayName, this.brandColor);

  static PlatformType fromId(String id) {
    return PlatformType.values.firstWhere(
      (e) => e.id == id,
      orElse: () => PlatformType.meituanWaimai,
    );
  }
}

class PriceBreakdown {
  final double originPrice;
  final double shopDiscount;
  final double couponDiscount;
  final double deliveryFee;
  final double packageFee;
  final double finalPrice;

  const PriceBreakdown({
    required this.originPrice,
    required this.shopDiscount,
    required this.couponDiscount,
    required this.deliveryFee,
    required this.packageFee,
    required this.finalPrice,
  });

  /// 先相加再按分舍入，避免浮点精度漂移
  double get totalDiscount => ((shopDiscount + couponDiscount) * 100).round() / 100;

  factory PriceBreakdown.fromJson(Map<String, dynamic> json) {
    return PriceBreakdown(
      originPrice: (json['origin_price'] as num).toDouble(),
      shopDiscount: (json['shop_discount'] as num? ?? 0).toDouble(),
      couponDiscount: (json['coupon_discount'] as num? ?? 0).toDouble(),
      deliveryFee: (json['delivery_fee'] as num? ?? 0).toDouble(),
      packageFee: (json['package_fee'] as num? ?? 0).toDouble(),
      finalPrice: (json['final_price'] as num).toDouble(),
    );
  }
}

class PlatformQuote {
  final PlatformType platformId;
  final String platformName;
  final String shopName;
  final String itemName;
  final String? itemSpecs;
  final PriceBreakdown price;
  final int deliveryEtaMinutes;
  final double shopRating;
  final int monthlySales;
  final String deepLink;
  final String webFallbackUrl;
  final bool isBestDeal;
  final double savedAmount;
  final List<String> highlights;

  const PlatformQuote({
    required this.platformId,
    required this.platformName,
    required this.shopName,
    required this.itemName,
    this.itemSpecs,
    required this.price,
    required this.deliveryEtaMinutes,
    required this.shopRating,
    required this.monthlySales,
    required this.deepLink,
    required this.webFallbackUrl,
    required this.isBestDeal,
    required this.savedAmount,
    required this.highlights,
  });

  factory PlatformQuote.fromJson(Map<String, dynamic> json) {
    return PlatformQuote(
      platformId: PlatformType.fromId(json['platform_id'] as String? ?? ''),
      platformName: json['platform_name'] as String? ?? '',
      shopName: json['shop_name'] as String? ?? '',
      itemName: json['item_name'] as String? ?? '',
      itemSpecs: json['item_specs'] as String?,
      price: PriceBreakdown.fromJson(json['price'] as Map<String, dynamic>),
      deliveryEtaMinutes: (json['delivery_eta_minutes'] as num? ?? 30).toInt(),
      shopRating: (json['shop_rating'] as num? ?? 4.8).toDouble(),
      monthlySales: (json['monthly_sales'] as num? ?? 0).toInt(),
      deepLink: json['deep_link'] as String? ?? '',
      webFallbackUrl: json['web_fallback_url'] as String? ?? '',
      isBestDeal: json['is_best_deal'] as bool? ?? false,
      savedAmount: (json['saved_amount'] as num? ?? 0).toDouble(),
      highlights: (json['highlights'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}

class CompareResponse {
  final String query;
  final String timestamp;
  final List<PlatformQuote> quotes;
  final PlatformQuote? bestQuote;
  final double maxSavedAmount;
  final String voiceSpeechText;
  final String summary;
  final bool isSimulated;
  final List<String> failedPlatforms;

  const CompareResponse({
    required this.query,
    required this.timestamp,
    required this.quotes,
    this.bestQuote,
    required this.maxSavedAmount,
    required this.voiceSpeechText,
    required this.summary,
    required this.isSimulated,
    required this.failedPlatforms,
  });

  factory CompareResponse.fromJson(Map<String, dynamic> json) {
    final quotesList = (json['quotes'] as List<dynamic>? ?? [])
        .map((e) => PlatformQuote.fromJson(e as Map<String, dynamic>))
        .toList();
    final bestJson = json['best_quote'] as Map<String, dynamic>?;

    return CompareResponse(
      query: json['query'] as String? ?? '',
      timestamp: json['timestamp'] as String? ?? '',
      quotes: quotesList,
      bestQuote: bestJson != null ? PlatformQuote.fromJson(bestJson) : null,
      maxSavedAmount: (json['max_saved_amount'] as num? ?? 0).toDouble(),
      voiceSpeechText: json['voice_speech_text'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      // 防御性策略：若缺失 is_simulated 字段，默认视为仿真数据，不冒充实时响应
      isSimulated: json['is_simulated'] as bool? ?? true,
      failedPlatforms: (json['failed_platforms'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}

class HistoryRecord {
  final String keyword;
  final String bestPlatform;
  final double bestPrice;
  final double savedAmount;
  final String timestamp;
  final bool isSimulated;

  const HistoryRecord({
    required this.keyword,
    required this.bestPlatform,
    required this.bestPrice,
    required this.savedAmount,
    required this.timestamp,
    required this.isSimulated,
  });

  Map<String, dynamic> toJson() => {
        'keyword': keyword,
        'bestPlatform': bestPlatform,
        'bestPrice': bestPrice,
        'savedAmount': savedAmount,
        'timestamp': timestamp,
        'isSimulated': isSimulated,
      };

  factory HistoryRecord.fromJson(Map<String, dynamic> json) {
    return HistoryRecord(
      keyword: json['keyword'] as String? ?? '',
      bestPlatform: json['bestPlatform'] as String? ?? '',
      bestPrice: (json['bestPrice'] as num? ?? 0).toDouble(),
      savedAmount: (json['savedAmount'] as num? ?? 0).toDouble(),
      timestamp: json['timestamp'] as String? ?? '',
      isSimulated: json['isSimulated'] as bool? ?? true,
    );
  }
}

class CouponClaimItem {
  final PlatformType platformId;
  final String platformName;
  final String couponTitle;
  final double discountAmount;
  final double minSpend;
  final bool claimed;
  final String message;
  final String deepLink;
  final String webFallbackUrl;

  const CouponClaimItem({
    required this.platformId,
    required this.platformName,
    required this.couponTitle,
    required this.discountAmount,
    required this.minSpend,
    required this.claimed,
    required this.message,
    required this.deepLink,
    required this.webFallbackUrl,
  });

  factory CouponClaimItem.fromJson(Map<String, dynamic> json) {
    return CouponClaimItem(
      platformId: PlatformType.fromId(json['platform_id'] as String? ?? ''),
      platformName: json['platform_name'] as String? ?? '',
      couponTitle: json['coupon_title'] as String? ?? '',
      discountAmount: (json['discount_amount'] as num? ?? 0).toDouble(),
      minSpend: (json['min_spend'] as num? ?? 0).toDouble(),
      claimed: json['claimed'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      deepLink: json['deep_link'] as String? ?? '',
      webFallbackUrl: json['web_fallback_url'] as String? ?? '',
    );
  }
}

class CouponClaimAllResponse {
  final String timestamp;
  final double totalClaimedAmount;
  final int claimedCount;
  final List<CouponClaimItem> coupons;
  final bool isSimulated;

  const CouponClaimAllResponse({
    required this.timestamp,
    required this.totalClaimedAmount,
    required this.claimedCount,
    required this.coupons,
    required this.isSimulated,
  });

  factory CouponClaimAllResponse.fromJson(Map<String, dynamic> json) {
    final list = (json['coupons'] as List<dynamic>? ?? [])
        .map((e) => CouponClaimItem.fromJson(e as Map<String, dynamic>))
        .toList();
    return CouponClaimAllResponse(
      timestamp: json['timestamp'] as String? ?? '',
      totalClaimedAmount: (json['total_claimed_amount'] as num? ?? 0).toDouble(),
      claimedCount: json['claimed_count'] as int? ?? 0,
      coupons: list,
      isSimulated: json['is_simulated'] as bool? ?? true,
    );
  }
}
