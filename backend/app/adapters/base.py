from abc import ABC, abstractmethod
from typing import Optional
from app.schemas import PlatformType, PlatformQuote, PriceBreakdown
from app.config import PLATFORM_METADATA
from app.services.merchant_provider import MerchantStoreCandidate, fetch_real_store_candidate


class BasePlatformAdapter(ABC):
    def __init__(self, platform_type: PlatformType):
        self.platform_type = platform_type
        self.display_info = PLATFORM_METADATA[platform_type]

    async def try_fetch_real_quote(
        self,
        keyword: str,
        latitude: Optional[float],
        longitude: Optional[float],
    ) -> Optional[PlatformQuote]:
        """若已配置真实商家/联盟接口，优先返回按距离+价格筛选出的真实门店报价"""
        if latitude is None or longitude is None:
            return None
        candidate: Optional[MerchantStoreCandidate] = await fetch_real_store_candidate(
            platform_id=self.platform_type,
            keyword=keyword,
            latitude=latitude,
            longitude=longitude,
        )
        if candidate is None:
            return None
        return PlatformQuote(
            platform_id=self.platform_type,
            platform_name=self.display_info.name,
            shop_id=candidate.shop_id,
            shop_name=candidate.shop_name,
            distance_km=candidate.distance_km,
            item_name=candidate.item_name,
            item_specs=candidate.item_specs,
            price=PriceBreakdown(
                origin_price=candidate.origin_price,
                shop_discount=candidate.shop_discount,
                coupon_discount=candidate.coupon_discount,
                delivery_fee=candidate.delivery_fee,
                package_fee=candidate.package_fee,
                final_price=candidate.final_price,
            ),
            delivery_eta_minutes=candidate.delivery_eta_minutes,
            shop_rating=candidate.shop_rating,
            monthly_sales=candidate.monthly_sales,
            deep_link=self.build_deep_link(keyword, candidate.shop_name, shop_id=candidate.shop_id),
            web_fallback_url=self.build_web_url(keyword, shop_id=candidate.shop_id),
            highlights=candidate.highlights,
        )

    @abstractmethod
    async def fetch_quote(
        self,
        keyword: str,
        address: Optional[str] = None,
        latitude: Optional[float] = None,
        longitude: Optional[float] = None
    ) -> Optional[PlatformQuote]:
        """
        拉取特定平台下该关键词的真实或仿真商品价格与店铺信息
        """
        pass

    @abstractmethod
    def build_deep_link(self, keyword: str, shop_name: str, shop_id: Optional[str] = None) -> str:
        """
        构建用于在 iOS 上调起对应原生 App 并在店内/搜索页待支付的 URL Scheme
        """
        pass

    @abstractmethod
    def build_web_url(self, keyword: str, shop_id: Optional[str] = None) -> str:
        """
        构建用于 H5 或 Safari 访问的兜底 URL
        """
        pass
