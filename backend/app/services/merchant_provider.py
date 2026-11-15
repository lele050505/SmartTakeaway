import os
from dataclasses import dataclass
from typing import List, Optional
import httpx
from app.schemas import PlatformType
from app.services.location import haversine_km


@dataclass
class MerchantStoreCandidate:
    shop_id: str
    shop_name: str
    item_name: str
    item_specs: str
    origin_price: float
    shop_discount: float
    coupon_discount: float
    delivery_fee: float
    package_fee: float
    final_price: float
    distance_km: float
    delivery_eta_minutes: int
    shop_rating: float
    monthly_sales: int
    highlights: List[str]
    is_real: bool = True


async def fetch_real_store_candidate(
    platform_id: PlatformType,
    keyword: str,
    latitude: float,
    longitude: float,
) -> Optional[MerchantStoreCandidate]:
    """
    对接外部合规商家/联盟检索网关（通过环境变量 MERCHANT_API_BASE_URL 与 MERCHANT_API_KEY 配置）。
    返回按“到手价 + 距离权重（最近且最便宜）”筛选出的真实门店 shop_id 与报价；
    未配置商业接口时返回 None，由适配器降级至本地 PoC 仿真引擎。
    """
    base_url = os.getenv("MERCHANT_API_BASE_URL", "").strip().rstrip("/")
    if not base_url:
        return None

    api_key = os.getenv("MERCHANT_API_KEY", "").strip()
    headers = {"Authorization": f"Bearer {api_key}"} if api_key else {}

    try:
        async with httpx.AsyncClient(timeout=4.0) as client:
            resp = await client.get(
                f"{base_url}/stores/search",
                params={
                    "platform": platform_id.value,
                    "keyword": keyword,
                    "lat": latitude,
                    "lng": longitude,
                },
                headers=headers,
            )
            if resp.status_code != 200:
                return None
            items = resp.json().get("stores") or []
    except Exception:
        return None

    candidates: List[MerchantStoreCandidate] = []
    for raw in items:
        shop_id = str(raw.get("shop_id") or "").strip()
        if not shop_id:
            continue
        s_lat = raw.get("latitude")
        s_lon = raw.get("longitude")
        dist = (
            haversine_km(latitude, longitude, float(s_lat), float(s_lon))
            if s_lat is not None and s_lon is not None
            else float(raw.get("distance_km") or 1.5)
        )
        origin = float(raw.get("origin_price") or 0.0)
        shop_disc = float(raw.get("shop_discount") or 0.0)
        coupon_disc = float(raw.get("coupon_discount") or 0.0)
        deliv = float(raw.get("delivery_fee") or 0.0)
        pack = float(raw.get("package_fee") or 0.0)
        final_p = float(
            raw.get("final_price")
            or max(0.0, round(origin - shop_disc - coupon_disc + deliv + pack, 2))
        )
        candidates.append(
            MerchantStoreCandidate(
                shop_id=shop_id,
                shop_name=str(raw.get("shop_name") or "附近精选门店"),
                item_name=str(raw.get("item_name") or keyword),
                item_specs=str(raw.get("item_specs") or "标准规格"),
                origin_price=origin,
                shop_discount=shop_disc,
                coupon_discount=coupon_disc,
                delivery_fee=deliv,
                package_fee=pack,
                final_price=final_p,
                distance_km=dist,
                delivery_eta_minutes=int(raw.get("delivery_eta_minutes") or max(15, int(12 + dist * 8))),
                shop_rating=float(raw.get("shop_rating") or 4.8),
                monthly_sales=int(raw.get("monthly_sales") or 1000),
                highlights=list(raw.get("highlights") or [f"距您 {dist} km", "真实门店直达"]),
                is_real=True,
            )
        )

    if not candidates:
        return None

    # 综合排序：优先价格最低，兼顾距离最近（每公里折算 1.5 元权重）
    candidates.sort(key=lambda c: (c.final_price + c.distance_km * 1.5, c.distance_km))
    return candidates[0]
