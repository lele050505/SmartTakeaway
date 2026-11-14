from __future__ import annotations
from enum import Enum
from typing import List, Optional
from pydantic import BaseModel, Field


class PlatformType(str, Enum):
    MEITUAN_WAIMAI = "meituan_waimai"
    ELEME = "eleme"
    MEITUAN_SHANGOU = "meituan_shangou"
    TAOBAO_SHANGOU = "taobao_shangou"


class PlatformDisplayInfo(BaseModel):
    id: PlatformType
    name: str
    color_hex: str
    badge_title: str
    scheme_prefix: str


class PriceBreakdown(BaseModel):
    origin_price: float = Field(..., description="商品标价/原价")
    shop_discount: float = Field(0.0, description="店铺立减/满减/折扣")
    coupon_discount: float = Field(0.0, description="平台通用券/红包抵扣")
    delivery_fee: float = Field(0.0, description="预估配送费")
    package_fee: float = Field(0.0, description="打包/包装费")
    final_price: float = Field(..., description="最终预估到手总价")

    @property
    def total_discount(self) -> float:
        return round(self.shop_discount + self.coupon_discount, 2)


class PlatformQuote(BaseModel):
    platform_id: PlatformType
    platform_name: str
    shop_name: str
    item_name: str
    item_specs: Optional[str] = "标准规格"
    item_image: Optional[str] = None
    price: PriceBreakdown
    delivery_eta_minutes: int = Field(30, description="预计配送用时（分钟）")
    shop_rating: float = Field(4.8, description="店铺评分")
    monthly_sales: int = Field(1000, description="月销量")
    deep_link: str = Field(..., description="用于唤起原生App的URL Scheme")
    web_fallback_url: str = Field(..., description="H5/网页兜底链接")
    is_best_deal: bool = False
    saved_amount: float = 0.0
    highlights: List[str] = Field(default_factory=list)


class CompareRequest(BaseModel):
    keyword: str = Field(..., min_length=1, description="用户搜索的餐品/商品名称，例如'生椰拿铁'、'冰美式'、'可口可乐'")
    category: Optional[str] = Field("全部", description="搜索大类：全部 / 外卖美食 / 闪购超市")
    address: Optional[str] = Field("我的默认地址", description="配送地址名称")
    latitude: Optional[float] = None
    longitude: Optional[float] = None


class CompareResponse(BaseModel):
    query: str
    timestamp: str
    quotes: List[PlatformQuote]
    best_quote: Optional[PlatformQuote] = None
    max_saved_amount: float = 0.0
    voice_speech_text: str = Field(..., description="专为Siri生成的直接语音播报文本")
    summary: str
    is_simulated: bool = Field(False, description="是否处于仿真演示模式")
    failed_platforms: List[str] = Field(default_factory=list, description="因风控/超时等导致拉取失败的平台列表")


class CouponClaimItem(BaseModel):
    platform_id: PlatformType
    platform_name: str
    coupon_title: str
    discount_amount: float
    min_spend: float
    claimed: bool = True
    message: str
    deep_link: str
    web_fallback_url: str


class CouponClaimAllResponse(BaseModel):
    timestamp: str
    total_claimed_amount: float
    claimed_count: int
    coupons: List[CouponClaimItem]
    is_simulated: bool = True
