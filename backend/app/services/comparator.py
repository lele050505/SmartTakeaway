import asyncio
import logging
from datetime import datetime
from typing import List, Optional
from app.adapters.meituan import MeituanWaimaiAdapter
from app.adapters.eleme import ElemeAdapter
from app.adapters.meituan_shangou import MeituanShangouAdapter
from app.adapters.taobao_shangou import TaobaoShangouAdapter
from app.schemas import CompareRequest, CompareResponse, PlatformQuote
from app.config import MOCK_SIMULATION_ENABLED

logger = logging.getLogger("SmartTakeaway.Comparator")


class TakeawayComparatorService:
    def __init__(self):
        self.adapters = [
            MeituanWaimaiAdapter(),
            ElemeAdapter(),
            MeituanShangouAdapter(),
            TaobaoShangouAdapter()
        ]

    async def compare(self, req: CompareRequest) -> CompareResponse:
        keyword = req.keyword.strip()

        # 并发并行向各大平台发起查询
        tasks = [
            adapter.fetch_quote(
                keyword=keyword,
                address=req.address,
                latitude=req.latitude,
                longitude=req.longitude
            )
            for adapter in self.adapters
        ]

        raw_results = await asyncio.gather(*tasks, return_exceptions=True)

        valid_quotes: List[PlatformQuote] = []
        failed_platforms: List[str] = []

        for adapter, res in zip(self.adapters, raw_results):
            if isinstance(res, Exception):
                platform_name = adapter.display_info.name
                logger.warning(f"平台【{platform_name}】抓取失败: {str(res)}")
                failed_platforms.append(f"{platform_name}: {str(res)}")
            elif isinstance(res, PlatformQuote):
                valid_quotes.append(res)
            else:
                platform_name = adapter.display_info.name
                failed_platforms.append(f"{platform_name}: 未返回有效商品报价")

        if not valid_quotes:
            return CompareResponse(
                query=keyword,
                timestamp=datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
                quotes=[],
                best_quote=None,
                max_saved_amount=0.0,
                voice_speech_text=f"抱歉，暂时未能从各大平台找到与【{keyword}】相关的价格信息。",
                summary="未能获取有效比价数据",
                is_simulated=MOCK_SIMULATION_ENABLED,
                failed_platforms=failed_platforms
            )

        # 核心排序：最终预估到手总价 (final_price) 升序排列
        valid_quotes.sort(key=lambda q: q.price.final_price)

        best_quote = valid_quotes[0]
        worst_quote = valid_quotes[-1]
        best_quote.is_best_deal = True

        max_saved = round(worst_quote.price.final_price - best_quote.price.final_price, 2)
        if max_saved < 0:
            max_saved = 0.0

        for quote in valid_quotes:
            quote.saved_amount = round(worst_quote.price.final_price - quote.price.final_price, 2)

        # 针对 Siri 场景优化的高自然度中文语音应答
        if max_saved > 0:
            voice_text = (
                f"已为您比对{len(valid_quotes)}个平台：最划算的是【{best_quote.platform_name}】，"
                f"到手仅需 {best_quote.price.final_price} 元，比【{worst_quote.platform_name}】立省 {max_saved} 元！"
                f"是否立即为您打开？"
            )
        else:
            voice_text = (
                f"已比对{len(valid_quotes)}个平台：各平台价格相近，推荐选择【{best_quote.platform_name}】，"
                f"预估到手 {best_quote.price.final_price} 元，送达仅需 {best_quote.delivery_eta_minutes} 分钟。"
            )

        summary_lines = [
            f"🔍 搜索关键词：{keyword}",
            f"🏆 最具性价比平台：{best_quote.platform_name} (到手价: ¥{best_quote.price.final_price})",
            f"💰 最高可省金额：¥{max_saved}",
            f"📊 各平台报价榜单："
        ]
        for idx, q in enumerate(valid_quotes, 1):
            tag = " [🌟最优推荐]" if q.is_best_deal else ""
            summary_lines.append(
                f"  {idx}. {q.platform_name} - 到手 ¥{q.price.final_price} (原价¥{q.price.origin_price}, 减¥{q.price.total_discount}, 配送¥{q.price.delivery_fee}){tag}"
            )

        if failed_platforms:
            summary_lines.append(f"⚠️ 异常或无结果平台: {', '.join(failed_platforms)}")

        return CompareResponse(
            query=keyword,
            timestamp=datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
            quotes=valid_quotes,
            best_quote=best_quote,
            max_saved_amount=max_saved,
            voice_speech_text=voice_text,
            summary="\n".join(summary_lines),
            is_simulated=MOCK_SIMULATION_ENABLED,
            failed_platforms=failed_platforms
        )
