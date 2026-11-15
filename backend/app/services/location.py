import hashlib
import math
import os
from typing import Optional, Tuple
import httpx

# 常见城市中心坐标兜底表（无高德 AMAP_KEY 时使用）
_CITY_CENTERS = {
    "北京": (39.9042, 116.4074),
    "上海": (31.2304, 121.4737),
    "广州": (23.1291, 113.2644),
    "深圳": (22.5431, 114.0579),
    "杭州": (30.2741, 120.1551),
    "成都": (30.5728, 104.0668),
    "西安": (34.2658, 108.9541),
    "南京": (32.0603, 118.7969),
    "武汉": (30.5928, 114.3055),
}


def haversine_km(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """计算两点之间的球面距离（公里）"""
    r = 6371.0
    phi1, phi2 = math.radians(lat1), math.radians(lat2)
    d_phi = math.radians(lat2 - lat1)
    d_lambda = math.radians(lon2 - lon1)
    a = (
        math.sin(d_phi / 2) ** 2
        + math.cos(phi1) * math.cos(phi2) * math.sin(d_lambda / 2) ** 2
    )
    return round(2 * r * math.atan2(math.sqrt(a), math.sqrt(1 - a)), 2)


async def geocode_address(
    address: Optional[str],
    latitude: Optional[float] = None,
    longitude: Optional[float] = None,
) -> Tuple[float, float, str]:
    """
    将配送地址解析为 (latitude, longitude, resolved_address)。
    1. 若请求已带经纬度则直接使用；
    2. 若配置了高德地图环境变量 AMAP_KEY，则调用高德地理编码 API；
    3. 否则使用本地城市中心 + 地址哈希确定性偏移作为离线兜底。
    """
    clean_addr = (address or "").strip() or "默认配送地址"
    if latitude is not None and longitude is not None:
        return latitude, longitude, clean_addr

    amap_key = os.getenv("AMAP_KEY", "").strip()
    if amap_key and clean_addr != "默认配送地址":
        try:
            async with httpx.AsyncClient(timeout=3.0) as client:
                resp = await client.get(
                    "https://restapi.amap.com/v3/geocode/geo",
                    params={"address": clean_addr, "key": amap_key},
                )
                data = resp.json()
                geocodes = data.get("geocodes") or []
                if geocodes:
                    loc = geocodes[0].get("location", "")
                    lon_s, lat_s = loc.split(",")
                    formatted = geocodes[0].get("formatted_address") or clean_addr
                    return float(lat_s), float(lon_s), formatted
        except Exception:
            pass

    base_lat, base_lon = 34.2658, 108.9541
    for city, coords in _CITY_CENTERS.items():
        if city in clean_addr:
            base_lat, base_lon = coords
            break

    digest = hashlib.md5(clean_addr.encode("utf-8")).hexdigest()
    lat_offset = ((int(digest[:4], 16) % 200) - 100) * 0.0002
    lon_offset = ((int(digest[4:8], 16) % 200) - 100) * 0.0002
    return round(base_lat + lat_offset, 6), round(base_lon + lon_offset, 6), clean_addr
