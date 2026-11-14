import 'package:flutter/material.dart';
import '../models/takeaway_models.dart';
import '../services/deep_link_policy.dart';

/// INS 极简风：平台比价卡片
class QuoteCard extends StatelessWidget {
  final PlatformQuote quote;
  final double maxFinalPrice;

  const QuoteCard({
    super.key,
    required this.quote,
    required this.maxFinalPrice,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: quote.isBestDeal ? const Color(0xFF111111) : const Color(0xFFEAEAEA),
          width: quote.isBestDeal ? 1.4 : 1.0,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _showBreakdownSheet(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    quote.platformName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111111),
                      letterSpacing: -0.2,
                    ),
                  ),
                  if (quote.isBestDeal) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF111111),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '性价比之王',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  Text(
                    '¥${quote.price.finalPrice.toStringAsFixed(1)}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111111),
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${quote.shopName} · ${quote.deliveryEtaMinutes}分钟',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF777777),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (quote.savedAmount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDF5F2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '省 ¥${quote.savedAmount.toStringAsFixed(1)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF2E6F5E),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '原价 ¥${quote.price.originPrice.toStringAsFixed(0)} · 优惠 -¥${quote.price.totalDiscount.toStringAsFixed(1)} · 运费 ¥${quote.price.deliveryFee.toStringAsFixed(1)}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF999999),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 32,
                    child: ElevatedButton(
                      onPressed: () => DeepLinkPolicy.openQuote(quote),
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: quote.isBestDeal
                            ? const Color(0xFF111111)
                            : const Color(0xFFF4F3EF),
                        foregroundColor: quote.isBestDeal
                            ? Colors.white
                            : const Color(0xFF111111),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        '去下单',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBreakdownSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E0DC),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${quote.platformName} · 费用明细',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111111),
              ),
            ),
            const SizedBox(height: 14),
            _line('商品原价', '¥${quote.price.originPrice.toStringAsFixed(2)}'),
            _line('店铺立减', '-¥${quote.price.shopDiscount.toStringAsFixed(2)}', highlight: true),
            _line('平台红包/神券', '-¥${quote.price.couponDiscount.toStringAsFixed(2)}', highlight: true),
            _line('预估配送费', '¥${quote.price.deliveryFee.toStringAsFixed(2)}'),
            _line('包装费', '¥${quote.price.packageFee.toStringAsFixed(2)}'),
            const Divider(height: 22, color: Color(0xFFEEEEEE)),
            _line('最终到手价', '¥${quote.price.finalPrice.toStringAsFixed(2)}', bold: true),
          ],
        ),
      ),
    );
  }

  Widget _line(String label, String value, {bool highlight = false, bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: bold ? 14.5 : 13,
              fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
              color: bold ? const Color(0xFF111111) : const Color(0xFF666666),
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: bold ? 16 : 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: highlight
                  ? const Color(0xFF2E6F5E)
                  : const Color(0xFF111111),
            ),
          ),
        ],
      ),
    );
  }
}
