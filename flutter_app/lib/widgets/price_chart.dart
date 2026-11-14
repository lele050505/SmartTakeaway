import 'package:flutter/material.dart';
import '../models/takeaway_models.dart';

/// INS 极简风：四平台到手价视觉对比条
class PriceComparisonChart extends StatelessWidget {
  final List<PlatformQuote> quotes;

  const PriceComparisonChart({super.key, required this.quotes});

  @override
  Widget build(BuildContext context) {
    if (quotes.isEmpty) return const SizedBox.shrink();

    final maxPrice = quotes
        .map((q) => q.price.finalPrice)
        .reduce((a, b) => a > b ? a : b);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEAEAEA)),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '到手价对比',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Color(0xFF111111),
                  letterSpacing: -0.2,
                ),
              ),
              const Spacer(),
              _legendDot(const Color(0xFF111111), '最优'),
              const SizedBox(width: 10),
              _legendDot(const Color(0xFFD8B98A), '配送/包装'),
            ],
          ),
          const SizedBox(height: 16),
          ...quotes.map((q) => _ChartBarRow(quote: q, maxPrice: maxPrice)),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10.5, color: Color(0xFF888888)),
        ),
      ],
    );
  }
}

class _ChartBarRow extends StatelessWidget {
  final PlatformQuote quote;
  final double maxPrice;

  const _ChartBarRow({required this.quote, required this.maxPrice});

  @override
  Widget build(BuildContext context) {
    final totalRatio =
        maxPrice > 0 ? (quote.price.finalPrice / maxPrice).clamp(0.18, 1.0) : 1.0;
    final extraFee = quote.price.deliveryFee + quote.price.packageFee;
    final feeRatio = quote.price.finalPrice > 0
        ? (extraFee / quote.price.finalPrice).clamp(0.0, 0.55)
        : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 62,
            child: Text(
              quote.platformName,
              style: TextStyle(
                fontSize: 12,
                fontWeight: quote.isBestDeal ? FontWeight.w600 : FontWeight.w400,
                color: quote.isBestDeal
                    ? const Color(0xFF111111)
                    : const Color(0xFF666666),
              ),
            ),
          ),
          Expanded(
            child: SizedBox(
              height: 10,
              child: CustomPaint(
                painter: _StackedBarPainter(
                  totalRatio: totalRatio,
                  feeRatio: feeRatio,
                  primaryColor: quote.isBestDeal
                      ? const Color(0xFF111111)
                      : const Color(0xFFDCDCD6),
                  feeColor: const Color(0xFFD8B98A),
                  trackColor: const Color(0xFFF5F4F0),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 48,
            child: Text(
              '¥${quote.price.finalPrice.toStringAsFixed(1)}',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13,
                fontWeight: quote.isBestDeal ? FontWeight.w700 : FontWeight.w500,
                color: quote.isBestDeal
                    ? const Color(0xFF111111)
                    : const Color(0xFF555555),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StackedBarPainter extends CustomPainter {
  final double totalRatio;
  final double feeRatio;
  final Color primaryColor;
  final Color feeColor;
  final Color trackColor;

  _StackedBarPainter({
    required this.totalRatio,
    required this.feeRatio,
    required this.primaryColor,
    required this.feeColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final radius = Radius.circular(size.height / 2);
    final trackRect = RRect.fromRectAndRadius(Offset.zero & size, radius);
    canvas.drawRRect(trackRect, Paint()..color = trackColor);

    final totalWidth = (size.width * totalRatio).clamp(size.height, size.width);
    final feeWidth = (totalWidth * feeRatio).clamp(0.0, totalWidth * 0.6);
    final goodsWidth = (totalWidth - feeWidth).clamp(0.0, totalWidth);

    final fullBarRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, totalWidth, size.height),
      radius,
    );
    canvas.save();
    canvas.clipRRect(fullBarRect);

    if (goodsWidth > 0) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, goodsWidth, size.height),
        Paint()..color = primaryColor,
      );
    }
    if (feeWidth > 0) {
      canvas.drawRect(
        Rect.fromLTWH(goodsWidth, 0, feeWidth, size.height),
        Paint()..color = feeColor,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _StackedBarPainter oldDelegate) {
    return oldDelegate.totalRatio != totalRatio ||
        oldDelegate.feeRatio != feeRatio ||
        oldDelegate.primaryColor != primaryColor;
  }
}
