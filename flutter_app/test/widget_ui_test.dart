import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_takeaway/main.dart';
import 'package:smart_takeaway/models/takeaway_models.dart';
import 'package:smart_takeaway/widgets/coupon_vault_card.dart';
import 'package:smart_takeaway/widgets/price_chart.dart';
import 'package:smart_takeaway/widgets/quote_card.dart';

void main() {
  testWidgets('SmartTakeawayApp renders shell and bottom navigation without overflow',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const SmartTakeawayApp());
    await tester.pump();

    expect(find.text('比价'), findsOneWidget);
    expect(find.text('历史'), findsOneWidget);
    expect(find.text('设置'), findsOneWidget);
  });

  testWidgets('PriceComparisonChart and QuoteCard render 4 platforms and best deal badge',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final quotes = [
      const PlatformQuote(
        platformId: PlatformType.meituanShangou,
        platformName: '美团闪购',
        shopName: '华润万家·闪购极速达',
        itemName: '生椰拿铁',
        itemSpecs: '大杯/冰',
        price: PriceBreakdown(
          originPrice: 28.0,
          shopDiscount: 9.0,
          couponDiscount: 3.5,
          deliveryFee: 2.5,
          packageFee: 0.5,
          finalPrice: 18.5,
        ),
        deliveryEtaMinutes: 20,
        shopRating: 4.92,
        monthlySales: 4500,
        deepLink: 'imeituan://www.meituan.com/takeaway/shangou/search?keyword=test',
        webFallbackUrl: 'https://waimai.meituan.com/shangou/search?keyword=test',
        isBestDeal: true,
        savedAmount: 4.5,
        highlights: ['20分钟极速达', '包装费仅0.5元'],
      ),
      const PlatformQuote(
        platformId: PlatformType.eleme,
        platformName: '饿了么',
        shopName: '瑞幸咖啡(蜂鸟店)',
        itemName: '生椰拿铁',
        itemSpecs: '大杯/冰',
        price: PriceBreakdown(
          originPrice: 30.0,
          shopDiscount: 8.0,
          couponDiscount: 4.0,
          deliveryFee: 3.5,
          packageFee: 1.5,
          finalPrice: 23.0,
        ),
        deliveryEtaMinutes: 28,
        shopRating: 4.85,
        monthlySales: 3120,
        deepLink: 'eleme://search?keyword=test',
        webFallbackUrl: 'https://h5.ele.me/msite/search?keyword=test',
        isBestDeal: false,
        savedAmount: 0.0,
        highlights: ['吃货红包已抵扣'],
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                PriceComparisonChart(quotes: quotes),
                const SizedBox(height: 12),
                QuoteCard(quote: quotes.first, maxFinalPrice: 23.0),
                QuoteCard(quote: quotes.last, maxFinalPrice: 23.0),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('到手价对比'), findsOneWidget);
    expect(find.text('性价比之王'), findsOneWidget);
    expect(find.text('¥18.5'), findsAtLeastNWidgets(2));
    expect(find.text('省 ¥4.5'), findsOneWidget);
    expect(find.text('美团闪购'), findsAtLeastNWidgets(2));
    expect(find.text('饿了么'), findsAtLeastNWidgets(2));
  });

  testWidgets('CouponVaultCard shows 1-tap claim and claimed coupons',
      (WidgetTester tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CouponVaultCard(
            claimResult: null,
            isClaiming: false,
            onClaimAll: () => tapped = true,
          ),
        ),
      ),
    );
    expect(find.text('全平台优惠券自动领'), findsOneWidget);
    await tester.tap(find.text('一键领取'));
    expect(tapped, isTrue);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CouponVaultCard(
            claimResult: const CouponClaimAllResponse(
              timestamp: '2026-11-14 23:30:00',
              totalClaimedAmount: 29.0,
              claimedCount: 4,
              isSimulated: true,
              coupons: [
                CouponClaimItem(
                  platformId: PlatformType.eleme,
                  platformName: '饿了么',
                  couponTitle: '吃货红包',
                  discountAmount: 10.0,
                  minSpend: 28.0,
                  claimed: true,
                  message: '已自动领取',
                  deepLink: 'eleme://coupon',
                  webFallbackUrl: 'https://h5.ele.me/',
                ),
              ],
            ),
            isClaiming: false,
            onClaimAll: () {},
          ),
        ),
      ),
    );
    expect(find.text('已自动领取 ¥29 神券'), findsOneWidget);
    expect(find.text('饿了么 -¥10'), findsOneWidget);
  });
}
