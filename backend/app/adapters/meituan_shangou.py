import urllib.parse
from typing import Optional
from app.adapters.base import BasePlatformAdapter
from app.schemas import PlatformType, PlatformQuote, PriceBreakdown


class MeituanShangouAdapter(BasePlatformAdapter):
    def __init__(self):
        super().__init__(PlatformType.MEITUAN_SHANGOU)

    def build_deep_link(self, keyword: str, shop_name: str) -> str:
        encoded_kw = urllib.parse.quote(keyword)
        # 美团闪购（即时零售超市便利）专属 Scheme 深度链接
        return f"imeituan://www.meituan.com/takeaway/shangou/search?keyword={encoded_kw}&source=smart_takeaway"

    def build_web_url(self, keyword: str) -> str:
        encoded_kw = urllib.parse.quote(keyword)
        return f"https://waimai.meituan.com/shangou/search?keyword={encoded_kw}"

    async def fetch_quote(
        self,
        keyword: str,
        address: Optional[str] = None,
        latitude: Optional[float] = None,
        longitude: Optional[float] = None
    ) -> Optional[PlatformQuote]:
        kw = keyword.strip()
        shop_name = "美团闪购·罗森便利店/全家"
        # 闪购（即时零售）在零售快消、瓶装饮料、应急百货、生鲜零食往往有超低秒杀价，且打包费极低
        if any(b in kw for b in ["咖啡", "拿铁", "美式"]):
            origin_price = 15.0  # 现磨或冷萃瓶装/即饮
            shop_discount = 5.0
            coupon_discount = 3.0
            delivery_fee = 2.0
            package_fee = 0.5
            shop_name = "7-Eleven便利店(现磨现萃)"
        elif any(b in kw for b in ["可乐", "饮料", "矿泉水", "零食", "纸巾"]):
            origin_price = 12.0
            shop_discount = 4.0
            coupon_discount = 2.0
            delivery_fee = 2.5
            package_fee = 0.5
            shop_name = "美团买菜·即时闪购仓"
        elif any(b in kw for b in ["汉堡", "麦当劳", "炸鸡"]):
            origin_price = 36.0
            shop_discount = 8.0
            coupon_discount = 4.0
            delivery_fee = 3.0
            package_fee = 1.0
            shop_name = "好邻居连锁熟食工坊"
        else:
            origin_price = 28.0
            shop_discount = 9.0
            coupon_discount = 3.5
            delivery_fee = 2.5
            package_fee = 0.5
            shop_name = "华润万家·闪购极速达"

        final_price = round(origin_price - shop_discount - coupon_discount + delivery_fee + package_fee, 2)
        if final_price < 4.0:
            final_price = 4.0

        return PlatformQuote(
            platform_id=self.platform_type,
            platform_name=self.display_info.name,
            shop_name=shop_name,
            item_name=kw,
            item_specs="现货极速达",
            price=PriceBreakdown(
                origin_price=origin_price,
                shop_discount=shop_discount,
                coupon_discount=coupon_discount,
                delivery_fee=delivery_fee,
                package_fee=package_fee,
                final_price=final_price
            ),
            delivery_eta_minutes=20,
            shop_rating=4.92,
            monthly_sales=4500,
            deep_link=self.build_deep_link(kw, shop_name),
            web_fallback_url=self.build_web_url(kw),
            highlights=["20分钟极速达", "包装费仅0.5元", "闪购百亿补贴"]
        )
