import 'package:flutter/material.dart';
import '../models/takeaway_models.dart';
import '../services/api_service.dart';
import '../services/deep_link_policy.dart';
import '../services/history_service.dart';
import '../widgets/coupon_vault_card.dart';
import '../widgets/price_chart.dart';
import '../widgets/quote_card.dart';

class HomeScreen extends StatefulWidget {
  final String? initialKeyword;
  final VoidCallback? onHistoryUpdated;

  const HomeScreen({
    super.key,
    this.initialKeyword,
    this.onHistoryUpdated,
  });

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController =
      TextEditingController(text: '生椰拿铁');
  final TakeawayApiService _apiService = TakeawayApiService();
  final HistoryService _historyService = HistoryService();

  CompareResponse? _result;
  CouponClaimAllResponse? _couponResult;
  bool _isLoading = false;
  bool _isClaimingCoupons = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialKeyword != null && widget.initialKeyword!.isNotEmpty) {
      _searchController.text = widget.initialKeyword!;
    }
    runComparison();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// 供外部 Deep Link (如 smarttakeaway://compare?q=...) 直接触发比价
  void searchFromDeepLink(String keyword) {
    final kw = keyword.trim();
    if (kw.isEmpty) return;
    _searchController.text = kw;
    runComparison();
  }

  Future<void> runComparison() async {
    final kw = _searchController.text.trim();
    if (kw.isEmpty) return;

    setState(() => _isLoading = true);

    final resp = await _apiService.compare(keyword: kw);
    await _historyService.addRecord(resp);
    widget.onHistoryUpdated?.call();

    if (mounted) {
      setState(() {
        _result = resp;
        _isLoading = false;
      });
    }
  }

  Future<void> _claimAllCoupons() async {
    setState(() => _isClaimingCoupons = true);
    final resp = await _apiService.claimAllCoupons();
    if (!mounted) return;
    setState(() {
      _couponResult = resp;
      _isClaimingCoupons = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF111111),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(
          '已自动领取 ${resp.claimedCount} 个平台神券，合计 ¥${resp.totalClaimedAmount.toStringAsFixed(0)}',
          style: const TextStyle(fontSize: 13),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final res = _result;
    final maxPrice = res != null && res.quotes.isNotEmpty
        ? res.quotes
            .map((e) => e.price.finalPrice)
            .reduce((a, b) => a > b ? a : b)
        : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        titleSpacing: 20,
        title: Row(
          children: [
            const Text(
              'SmartTakeaway',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                color: Color(0xFF111111),
              ),
            ),
            if (res != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F1EC),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  res.isSimulated ? 'PoC 仿真' : '实时',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF777777),
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          IconButton(
            tooltip: '收藏关键词',
            icon: const Icon(Icons.bookmark_border_rounded, size: 21),
            onPressed: () async {
              final kw = _searchController.text.trim();
              if (kw.isEmpty) return;
              await _historyService.toggleFavorite(kw);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: const Color(0xFF111111),
                  content: Text('已更新常用词：$kw'),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFF111111),
        onRefresh: runComparison,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          children: [
            // 极简搜索框
            Container(
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE6E6E2)),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  const Icon(Icons.search_rounded, size: 19, color: Color(0xFF888888)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(fontSize: 14, color: Color(0xFF111111)),
                      textInputAction: TextInputAction.search,
                      onChanged: (_) => setState(() {}),
                      onSubmitted: (_) => runComparison(),
                      decoration: const InputDecoration(
                        hintText: '搜想吃的外卖或商品...',
                        hintStyle: TextStyle(fontSize: 13.5, color: Color(0xFFAAAAAA)),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 17, color: Color(0xFF999999)),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    ),
                  Padding(
                    padding: const EdgeInsets.only(right: 5),
                    child: SizedBox(
                      height: 36,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : runComparison,
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: const Color(0xFF111111),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.8,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                '比价',
                                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 全平台优惠券一键自动领取
            CouponVaultCard(
              claimResult: _couponResult,
              isClaiming: _isClaimingCoupons,
              onClaimAll: _claimAllCoupons,
            ),
            const SizedBox(height: 14),

            // 极简最优推荐摘要卡片
            if (res?.bestQuote != null) ...[
              _buildMinimalHeroCard(context, res!),
              const SizedBox(height: 14),
            ],

            // 极简到手价对比柱状图
            if (res != null && res.quotes.isNotEmpty) ...[
              PriceComparisonChart(quotes: res.quotes),
              const SizedBox(height: 16),
            ],

            // 报价列表
            if (res != null)
              ...res.quotes.map(
                (q) => QuoteCard(quote: q, maxFinalPrice: maxPrice),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMinimalHeroCard(BuildContext context, CompareResponse res) {
    final best = res.bestQuote!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F2EE),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '最优选择 · ${best.platformName}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF666666),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '¥${best.price.finalPrice.toStringAsFixed(1)}',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111111),
                        letterSpacing: -1,
                      ),
                    ),
                    if (res.maxSavedAmount > 0) ...[
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDF5F2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '立省 ¥${res.maxSavedAmount.toStringAsFixed(1)}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2E6F5E),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${best.shopName} · 预计 ${best.deliveryEtaMinutes} 分钟',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF777777)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            height: 40,
            child: ElevatedButton(
              onPressed: () => DeepLinkPolicy.openQuote(best),
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: const Color(0xFF111111),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
              child: const Text(
                '立即下单',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
