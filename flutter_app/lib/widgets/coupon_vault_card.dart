import 'package:flutter/material.dart';
import '../models/takeaway_models.dart';
import '../services/deep_link_policy.dart';

/// INS 极简风：全平台优惠券一键自动领取卡片
class CouponVaultCard extends StatelessWidget {
  final CouponClaimAllResponse? claimResult;
  final bool isClaiming;
  final VoidCallback onClaimAll;

  const CouponVaultCard({
    super.key,
    required this.claimResult,
    required this.isClaiming,
    required this.onClaimAll,
  });

  @override
  Widget build(BuildContext context) {
    final claimed = claimResult != null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: claimed ? const Color(0xFF2E6F5E).withValues(alpha: 0.35) : const Color(0xFFEAEAEA),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: claimed ? const Color(0xFFEDF5F2) : const Color(0xFFF5F4F0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  claimed ? Icons.verified_outlined : Icons.confirmation_num_outlined,
                  size: 18,
                  color: claimed ? const Color(0xFF2E6F5E) : const Color(0xFF111111),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      claimed
                          ? '已自动领取 ¥${claimResult!.totalClaimedAmount.toStringAsFixed(0)} 神券'
                          : '全平台优惠券自动领',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111111),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      claimed
                          ? '已同步至 ${claimResult!.claimedCount} 个平台账户 · 点击可直达卡包'
                          : '美团 · 饿了么 · 美团闪购 · 淘宝闪购',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF888888),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 34,
                child: ElevatedButton(
                  onPressed: isClaiming ? null : onClaimAll,
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: claimed ? const Color(0xFFF5F4F0) : const Color(0xFF111111),
                    foregroundColor: claimed ? const Color(0xFF111111) : Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: isClaiming
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.8,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          claimed ? '再领一次' : '一键领取',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
          if (claimed && claimResult!.coupons.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF0F0EE)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: claimResult!.coupons.map((c) {
                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => DeepLinkPolicy.openTarget(
                    platform: c.platformId,
                    deepLink: c.deepLink,
                    fallbackUrl: c.webFallbackUrl,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF9F6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFECEAE4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          size: 13,
                          color: Color(0xFF2E6F5E),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '${c.platformName} -¥${c.discountAmount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF222222),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
