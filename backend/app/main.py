from datetime import datetime
from fastapi import FastAPI, Query, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from app.config import PLATFORM_METADATA, SERVER_HOST, SERVER_PORT
from app.schemas import (
    CompareRequest,
    CompareResponse,
    CouponClaimAllResponse,
    CouponClaimItem,
    PlatformType,
)
from app.services.comparator import TakeawayComparatorService

app = FastAPI(
    title="SmartTakeaway API - 外卖多平台智能比价引擎",
    description="支持美团外卖、饿了么、美团闪购、淘宝闪购等平台的实时价格计算与Siri快捷指令深度交互",
    version="1.0.0"
)

# 允许跨域（支持iOS App、本地调试与前端界面）
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

comparator_service = TakeawayComparatorService()


@app.get("/")
async def root():
    return {
        "service": "SmartTakeaway API",
        "status": "online",
        "supported_platforms": [p.name for p in PLATFORM_METADATA.values()],
        "docs_url": "/docs"
    }


@app.get("/api/v1/health")
async def health_check():
    return {
        "status": "healthy",
        "platforms_count": len(PLATFORM_METADATA)
    }


@app.get("/api/v1/platforms")
async def get_platforms():
    return {
        "platforms": list(PLATFORM_METADATA.values())
    }


@app.post("/api/v1/compare", response_model=CompareResponse)
async def compare_takeaway(request: CompareRequest):
    """
    接收用户搜索的商品名称，并发比对各大外卖与即时零售平台的最终到手价格
    """
    if not request.keyword.strip():
        raise HTTPException(status_code=400, detail="搜索关键词不能为空")
    return await comparator_service.compare(request)


@app.get("/api/v1/quick_compare", response_model=CompareResponse)
async def quick_compare(q: str = Query(..., min_length=1, description="搜索关键词，如：生椰拿铁、可口可乐")):
    """
    便捷 GET 请求接口，特别适配 iOS 快捷指令（Shortcuts）通过 URL 直接解析
    """
    req = CompareRequest(keyword=q)
    return await comparator_service.compare(req)


@app.post("/api/v1/coupons/claim-all", response_model=CouponClaimAllResponse)
async def claim_all_coupons():
    """
    全平台优惠券一键自动领取（PoC 模拟领券流程 + 各平台领券中心直达链接）
    """
    coupons = [
        CouponClaimItem(
            platform_id=PlatformType.MEITUAN_WAIMAI,
            platform_name="美团外卖",
            coupon_title="美团神券 · 满25减8",
            discount_amount=8.0,
            min_spend=25.0,
            claimed=True,
            message="已自动放入美团卡包",
            deep_link="imeituan://www.meituan.com/waimai/coupon?source=smart_takeaway",
            web_fallback_url="https://waimai.meituan.com/",
        ),
        CouponClaimItem(
            platform_id=PlatformType.ELEME,
            platform_name="饿了么",
            coupon_title="吃货超级红包 · 满28减10",
            discount_amount=10.0,
            min_spend=28.0,
            claimed=True,
            message="已自动领取到账户",
            deep_link="eleme://coupon?source=smart_takeaway",
            web_fallback_url="https://h5.ele.me/",
        ),
        CouponClaimItem(
            platform_id=PlatformType.MEITUAN_SHANGOU,
            platform_name="美团闪购",
            coupon_title="闪购百亿补贴 · 满20减6",
            discount_amount=6.0,
            min_spend=20.0,
            claimed=True,
            message="已自动激活免配叠加",
            deep_link="imeituan://www.meituan.com/takeaway/shangou?source=smart_takeaway",
            web_fallback_url="https://waimai.meituan.com/",
        ),
        CouponClaimItem(
            platform_id=PlatformType.TAOBAO_SHANGOU,
            platform_name="淘宝闪购",
            coupon_title="小时达通用券 · 满19减5",
            discount_amount=5.0,
            min_spend=19.0,
            claimed=True,
            message="已自动领券并绑定",
            deep_link="taobao://s.taobao.com/search?tab=takeaway&source=smart_takeaway",
            web_fallback_url="https://s.taobao.com/",
        ),
    ]
    total = round(sum(c.discount_amount for c in coupons if c.claimed), 2)
    return CouponClaimAllResponse(
        timestamp=datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        total_claimed_amount=total,
        claimed_count=sum(1 for c in coupons if c.claimed),
        coupons=coupons,
        is_simulated=True,
    )


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app.main:app", host=SERVER_HOST, port=SERVER_PORT, reload=True)
