import urllib.parse
from typing import Optional
from app.adapters.base import BasePlatformAdapter
from app.schemas import PlatformType, PlatformQuote, PriceBreakdown


class MeituanWaimaiAdapter(BasePlatformAdapter):
    def __init__(self):
        super().__init__(PlatformType.MEITUAN_WAIMAI)

    def build_deep_link(self, keyword: str, shop_name: str) -> str:
        encoded_kw = urllib.parse.quote(keyword)
        # 美团官方标准 URL Scheme 深度搜索与直接调起店铺
        return f"imeituan://www.meituan.com/waimai/search?keyword={encoded_kw}&source=smart_takeaway"

    def build_web_url(self, keyword: str) -> str:
        encoded_kw = urllib.parse.quote(keyword)
        return f"https://waimai.meituan.com/search?q={encoded_kw}"

    async def fetch_quote(
        self,
        keyword: str,
        address: Optional[str] = None,
        latitude: Optional[float] = None,
        longitude: Optional[float] = None
    ) -> Optional[PlatformQuote]:
        # 智能价格估算引擎：模拟美团外卖专送与会员大额神券生态
        kw = keyword.strip()
        shop_name = f"{kw[:4]}精选料理(美团旗舰店)"
        if any(b in kw for b in ["咖啡", "拿铁", "美式", "瑞幸"]):
            origin_price = 20.0
            shop_discount = 6.0
            coupon_discount = 4.0
            delivery_fee = 3.5
            package_fee = 1.0
            shop_name = "瑞幸咖啡(就近配送店)"
        elif any(b in kw for b in ["汉堡", "麦当劳", "肯德基", "薯条"]):
            origin_price = 38.0
            shop_discount = 10.0
            coupon_discount = 5.0
            delivery_fee = 4.0
            package_fee = 2.0
            shop_name = "麦当劳外送官方店"
        elif any(b in kw for b in ["奶茶", "蜜雪", "霸王茶姬"]):
            origin_price = 18.0
            shop_discount = 3.0
            coupon_discount = 3.0
            delivery_fee = 3.0
            package_fee = 1.0
            shop_name = "霸王茶姬(美团专送)"
        else:
            origin_price = 30.0
            shop_discount = 8.0
            coupon_discount = 4.0
            delivery_fee = 3.5
            package_fee = 1.5

        final_price = round(origin_price - shop_discount - coupon_discount + delivery_fee + package_fee, 2)
        if final_price < 5.0:
            final_price = 5.0

        return PlatformQuote(
            platform_id=self.platform_type,
            platform_name=self.display_info.name,
            shop_name=shop_name,
            item_name=kw,
            item_specs="标准大份/热",
            price=PriceBreakdown(
                origin_price=origin_price,
                shop_discount=shop_discount,
                coupon_discount=coupon_discount,
                delivery_fee=delivery_fee,
                package_fee=package_fee,
                final_price=final_price
            ),
            delivery_eta_minutes=28,
            shop_rating=4.9,
            monthly_sales=2890,
            deep_link=self.build_deep_link(kw, shop_name),
            web_fallback_url=self.build_web_url(kw),
            highlights=["美团神券立减", "美团专送准时保"]
        )
