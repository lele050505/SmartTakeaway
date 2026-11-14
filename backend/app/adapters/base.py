from abc import ABC, abstractmethod
from typing import Optional
from app.schemas import PlatformType, PlatformQuote, PriceBreakdown
from app.config import PLATFORM_METADATA


class BasePlatformAdapter(ABC):
    def __init__(self, platform_type: PlatformType):
        self.platform_type = platform_type
        self.display_info = PLATFORM_METADATA[platform_type]

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
    def build_deep_link(self, keyword: str, shop_name: str) -> str:
        """
        构建用于在 iOS 上调起对应原生 App 并在店内/搜索页待支付的 URL Scheme
        """
        pass

    @abstractmethod
    def build_web_url(self, keyword: str) -> str:
        """
        构建用于 H5 或 Safari 访问的兜底 URL
        """
        pass
