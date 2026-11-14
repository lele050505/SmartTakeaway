import 'package:url_launcher/url_launcher.dart';
import '../models/takeaway_models.dart';

enum DeepLinkDecisionType { openApp, openWeb, reject }

class DeepLinkDecision {
  final DeepLinkDecisionType type;
  final Uri? uri;

  const DeepLinkDecision(this.type, [this.uri]);
}

/// 跨平台跳转安全校验与执行策略
/// 规则：
/// 1. App 链接 Scheme 必须与报价所属平台一一对应
/// 2. 网页兜底链接必须为 https 且域名属于该平台白名单
/// 3. App 打不开时仅回退至该平台自身网页，绝不跳转到其他平台
class DeepLinkPolicy {
  static String expectedScheme(PlatformType platform) {
    switch (platform) {
      case PlatformType.meituanWaimai:
      case PlatformType.meituanShangou:
        return 'imeituan';
      case PlatformType.eleme:
        return 'eleme';
      case PlatformType.taobaoShangou:
        return 'taobao';
    }
  }

  static Set<String> allowedFallbackHosts(PlatformType platform) {
    switch (platform) {
      case PlatformType.meituanWaimai:
      case PlatformType.meituanShangou:
        return {'waimai.meituan.com'};
      case PlatformType.eleme:
        return {'h5.ele.me'};
      case PlatformType.taobaoShangou:
        return {'s.taobao.com'};
    }
  }

  static Uri? validatedAppUri(String raw, PlatformType platform) {
    final uri = Uri.tryParse(raw);
    if (uri == null) return null;
    if (uri.scheme.toLowerCase() != expectedScheme(platform)) return null;
    return uri;
  }

  static Uri? validatedFallbackUri(String raw, PlatformType platform) {
    final uri = Uri.tryParse(raw);
    if (uri == null) return null;
    if (uri.scheme.toLowerCase() != 'https') return null;
    if (!allowedFallbackHosts(platform).contains(uri.host.toLowerCase())) {
      return null;
    }
    return uri;
  }

  static Future<DeepLinkDecision> plan({
    required PlatformType platform,
    required String deepLink,
    required String fallbackUrl,
    required Future<bool> Function(Uri) canOpenApp,
  }) async {
    final appUri = validatedAppUri(deepLink, platform);
    if (appUri != null && await canOpenApp(appUri)) {
      return DeepLinkDecision(DeepLinkDecisionType.openApp, appUri);
    }
    final webUri = validatedFallbackUri(fallbackUrl, platform);
    if (webUri != null) {
      return DeepLinkDecision(DeepLinkDecisionType.openWeb, webUri);
    }
    return const DeepLinkDecision(DeepLinkDecisionType.reject);
  }

  /// 实际执行平台跳转（先尝试原生 App，失败则使用该平台自己的 HTTPS 网页）
  static Future<bool> openQuote(PlatformQuote quote) => openTarget(
        platform: quote.platformId,
        deepLink: quote.deepLink,
        fallbackUrl: quote.webFallbackUrl,
      );

  static Future<bool> openTarget({
    required PlatformType platform,
    required String deepLink,
    required String fallbackUrl,
  }) async {
    final decision = await plan(
      platform: platform,
      deepLink: deepLink,
      fallbackUrl: fallbackUrl,
      canOpenApp: canLaunchUrl,
    );

    if (decision.type == DeepLinkDecisionType.reject || decision.uri == null) {
      return false;
    }

    final launched = await launchUrl(
      decision.uri!,
      mode: LaunchMode.externalApplication,
    );

    if (!launched && decision.type == DeepLinkDecisionType.openApp) {
      final webUri = validatedFallbackUri(fallbackUrl, platform);
      if (webUri != null) {
        return launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    }
    return launched;
  }
}
