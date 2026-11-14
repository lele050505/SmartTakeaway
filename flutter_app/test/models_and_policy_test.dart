import 'package:flutter_test/flutter_test.dart';
import 'package:smart_takeaway/models/takeaway_models.dart';
import 'package:smart_takeaway/services/deep_link_policy.dart';

void main() {
  group('PriceBreakdown', () {
    test('totalDiscount adds before rounding', () {
      const p = PriceBreakdown(
        originPrice: 30,
        shopDiscount: 6,
        couponDiscount: 4,
        deliveryFee: 3,
        packageFee: 1,
        finalPrice: 24,
      );
      expect(p.totalDiscount, closeTo(10.0, 0.0001));
    });

    test('totalDiscount handles floating precision', () {
      const p = PriceBreakdown(
        originPrice: 30,
        shopDiscount: 5.25,
        couponDiscount: 3.35,
        deliveryFee: 3,
        packageFee: 1,
        finalPrice: 25.4,
      );
      expect(p.totalDiscount, closeTo(8.6, 0.0001));
    });
  });

  group('CompareResponse.fromJson', () {
    test('defaults isSimulated to true when missing', () {
      final resp = CompareResponse.fromJson({
        'query': '可乐',
        'timestamp': 't',
        'quotes': [],
        'max_saved_amount': 0,
        'voice_speech_text': 'v',
        'summary': 's',
      });
      expect(resp.isSimulated, isTrue);
      expect(resp.failedPlatforms, isEmpty);
    });
  });

  group('DeepLinkPolicy', () {
    test('opens app when scheme matches platform and installed', () async {
      final d = await DeepLinkPolicy.plan(
        platform: PlatformType.eleme,
        deepLink: 'eleme://search?keyword=a',
        fallbackUrl: 'https://h5.ele.me',
        canOpenApp: (_) async => true,
      );
      expect(d.type, DeepLinkDecisionType.openApp);
      expect(d.uri.toString(), 'eleme://search?keyword=a');
    });

    test('falls back to own https web when app missing', () async {
      final d = await DeepLinkPolicy.plan(
        platform: PlatformType.eleme,
        deepLink: 'eleme://search?keyword=a',
        fallbackUrl: 'https://h5.ele.me/msite/search',
        canOpenApp: (_) async => false,
      );
      expect(d.type, DeepLinkDecisionType.openWeb);
      expect(d.uri.toString(), 'https://h5.ele.me/msite/search');
    });

    test('rejects mismatched scheme and untrusted domain', () async {
      final d = await DeepLinkPolicy.plan(
        platform: PlatformType.eleme,
        deepLink: 'imeituan://www.meituan.com/waimai',
        fallbackUrl: 'https://evil.example.com',
        canOpenApp: (_) async => true,
      );
      expect(d.type, DeepLinkDecisionType.reject);
    });
  });
}
