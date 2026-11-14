import asyncio
import httpx
from app.main import app
from app.schemas import CompareRequest, PlatformType, PlatformQuote, PriceBreakdown
from app.services.comparator import TakeawayComparatorService
from app.adapters.base import BasePlatformAdapter


async def test_http_endpoints_async():
    """
    使用现代 httpx.ASGITransport 纯异步测试端点，彻底避免 Starlette TestClient 的弃用警告
    """
    transport = httpx.ASGITransport(app=app)
    async with httpx.AsyncClient(transport=transport, base_url="http://test") as client:
        # 1. 测试健康检查
        res = await client.get("/api/v1/health")
        assert res.status_code == 200, f"Health check failed with {res.status_code}"
        assert res.json()["status"] == "healthy"
        assert res.json()["platforms_count"] == 4

        # 2. 测试平台列表
        res = await client.get("/api/v1/platforms")
        assert res.status_code == 200
        platforms = res.json()["platforms"]
        assert len(platforms) == 4
        platform_ids = {p["id"] for p in platforms}
        assert "meituan_waimai" in platform_ids
        assert "eleme" in platform_ids
        assert "meituan_shangou" in platform_ids
        assert "taobao_shangou" in platform_ids

        # 3. 测试边缘情况：空关键词应返回 400 校验错误
        res = await client.post("/api/v1/compare", json={"keyword": "   "})
        assert res.status_code == 400 or res.status_code == 422, "空关键词未触发 400/422 错误"

        # 4. 测试快速 GET 接口
        res = await client.get("/api/v1/quick_compare?q=冰美式")
        assert res.status_code == 200
        data = res.json()
        assert data["query"] == "冰美式"
        assert len(data["quotes"]) == 4
        assert data["best_quote"] is not None
        assert "voice_speech_text" in data and len(data["voice_speech_text"]) > 0
        assert "is_simulated" in data
        assert isinstance(data["failed_platforms"], list)

    print("✅ HTTP 端点异步调用、状态码与参数校验测试通过！")


class FailingMockAdapter(BasePlatformAdapter):
    """用于测试容错机制的故障模拟适配器"""
    def __init__(self):
        super().__init__(PlatformType.ELEME)

    async def fetch_quote(self, keyword, address=None, latitude=None, longitude=None):
        raise ConnectionResetError("模拟平台接口触发反爬风控或网络超时")

    def build_deep_link(self, keyword: str, shop_name: str) -> str:
        return "eleme://mock"

    def build_web_url(self, keyword: str) -> str:
        return "https://ele.me"


async def test_comparator_platform_failure_resilience():
    """
    测试当个别平台网络故障或反爬封禁时的容错性与降级记录机制
    """
    service = TakeawayComparatorService()
    # 注入一个必定抛出异常的适配器
    service.adapters.append(FailingMockAdapter())

    req = CompareRequest(keyword="生椰拿铁")
    resp = await service.compare(req)

    # 验证系统未崩溃，正常平台仍可产出比价结果
    assert len(resp.quotes) == 4, "正常平台应成功返回"
    assert resp.best_quote is not None, "正常平台中仍应选出最优解"
    # 验证异常平台被准确捕获并记录在 failed_platforms
    assert len(resp.failed_platforms) >= 1, "异常平台必须记录在 failed_platforms"
    assert any("模拟平台接口触发反爬风控" in err for err in resp.failed_platforms), "未正确记录故障描述"

    print("✅ 单平台异常隔离与失败日志捕获断言测试通过！")


# 与 iOS 端 ios/SmartTakeaway/Core/DeepLinkPolicy.swift 保持一致的白名单
IOS_POLICY_SCHEME = {
    "meituan_waimai": "imeituan",
    "meituan_shangou": "imeituan",
    "eleme": "eleme",
    "taobao_shangou": "taobao",
}
IOS_POLICY_FALLBACK_HOSTS = {
    "meituan_waimai": {"waimai.meituan.com"},
    "meituan_shangou": {"waimai.meituan.com"},
    "eleme": {"h5.ele.me"},
    "taobao_shangou": {"s.taobao.com"},
}


async def test_backend_links_pass_ios_policy():
    """
    后端生成的 deep_link / web_fallback_url 必须能通过 iOS 端 DeepLinkPolicy，
    否则真机上会被拦截（.reject）。
    """
    from urllib.parse import urlparse
    service = TakeawayComparatorService()
    for kw in ["生椰拿铁", "可口可乐", "麦当劳", "霸王茶姬", "抽纸"]:
        resp = await service.compare(CompareRequest(keyword=kw))
        for q in resp.quotes:
            pid = q.platform_id.value
            app = urlparse(q.deep_link)
            web = urlparse(q.web_fallback_url)
            assert app.scheme == IOS_POLICY_SCHEME[pid], f"{pid} 的 App Scheme 不匹配: {q.deep_link}"
            assert web.scheme == "https", f"{pid} 兜底链接不是 https: {q.web_fallback_url}"
            assert web.hostname in IOS_POLICY_FALLBACK_HOSTS[pid], f"{pid} 兜底域名不在白名单: {q.web_fallback_url}"
    print("✅ 后端生成的跳转链接全部符合 iOS DeepLinkPolicy 白名单！")


def test_backend_discount_math_precision():
    """
    仅验证 Python 后端 PriceBreakdown.total_discount。
    Swift 端 totalDiscount 的测试在 ios/Tests/SmartTakeawayCoreTests（需在 Mac 上 swift test）。
    """
    test_cases = [
        (6.0, 4.0, 10.0),       # 6 + 4 = 10
        (5.25, 3.35, 8.60),     # 浮点相加精度
        (0.0, 5.0, 5.0),
        (0.0, 0.0, 0.0)
    ]
    for shop, coupon, expected in test_cases:
        p = PriceBreakdown(
            origin_price=30.0,
            shop_discount=shop,
            coupon_discount=coupon,
            delivery_fee=3.0,
            package_fee=1.0,
            final_price=round(30.0 - shop - coupon + 3.0 + 1.0, 2)
        )
        assert abs(p.total_discount - expected) < 0.001, (
            f"折扣计算错误: shop={shop}, coupon={coupon}, 得={p.total_discount}, 预期={expected}"
        )
    print("✅ 优惠合并与浮点精度数学断言测试通过！")


async def test_comparator_math_and_logic():
    """
    深入针对比价算法数学逻辑、费用拆解公式、排序单调性进行严格断言
    """
    service = TakeawayComparatorService()
    test_keywords = ["生椰拿铁", "可口可乐", "麦当劳", "霸王茶姬"]

    for kw in test_keywords:
        req = CompareRequest(keyword=kw, address="测试地址")
        resp = await service.compare(req)

        assert resp.best_quote is not None, f"{kw} 缺少最佳推荐"
        assert len(resp.quotes) == 4, f"{kw} 返回平台数量不为4"

        # 校验 1：排序单调性递增
        for i in range(len(resp.quotes) - 1):
            assert resp.quotes[i].price.final_price <= resp.quotes[i + 1].price.final_price, (
                f"排序逻辑错误: {resp.quotes[i].platform_name} ({resp.quotes[i].price.final_price}) "
                f"> {resp.quotes[i+1].platform_name} ({resp.quotes[i+1].price.final_price})"
            )

        # 校验 2：费用计算公式准确性
        for q in resp.quotes:
            p = q.price
            expected_final = round(p.origin_price - p.shop_discount - p.coupon_discount + p.delivery_fee + p.package_fee, 2)
            assert abs(p.final_price - expected_final) < 0.05, (
                f"价格算式不一致: 平台={q.platform_name}, 计算得={p.final_price}, 公式得={expected_final}"
            )
            assert q.deep_link.startswith(("imeituan://", "eleme://", "taobao://")), f"非法Scheme: {q.deep_link}"

        # 校验 3：最大立省金额 = 最高价 - 最低价
        expected_saved = round(resp.quotes[-1].price.final_price - resp.quotes[0].price.final_price, 2)
        assert abs(resp.max_saved_amount - expected_saved) < 0.05, "最大节省金额计算错误"

        # 校验 4：最佳推荐标志
        assert resp.quotes[0].is_best_deal is True, "第一名必须标记为最优"
        for q in resp.quotes[1:]:
            assert q.is_best_deal is False, "非第一名不能标记为最优"

    print("✅ 算法费用公式、单调性排序与立省金额数学断言全部通过！")


async def async_main():
    print("=" * 60)
    print("🧪 SmartTakeaway 后端断言测试")
    print("=" * 60)
    await test_http_endpoints_async()
    test_backend_discount_math_precision()
    await test_comparator_math_and_logic()
    await test_comparator_platform_failure_resilience()
    await test_backend_links_pass_ios_policy()
    print("\n" + "=" * 60)
    print("🎉 后端测试全部通过（仅覆盖 Python 后端；Swift 测试需在 Mac 上运行）")
    print("=" * 60)


if __name__ == "__main__":
    asyncio.run(async_main())
