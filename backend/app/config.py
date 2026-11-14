from typing import Dict, Any
from app.schemas import PlatformType, PlatformDisplayInfo

# 平台注册表信息
PLATFORM_METADATA: Dict[PlatformType, PlatformDisplayInfo] = {
    PlatformType.MEITUAN_WAIMAI: PlatformDisplayInfo(
        id=PlatformType.MEITUAN_WAIMAI,
        name="美团外卖",
        color_hex="#FFD101",
        badge_title="外卖首选",
        scheme_prefix="imeituan://www.meituan.com/waimai"
    ),
    PlatformType.ELEME: PlatformDisplayInfo(
        id=PlatformType.ELEME,
        name="饿了么",
        color_hex="#0092FF",
        badge_title="品质外卖",
        scheme_prefix="eleme://waimai"
    ),
    PlatformType.MEITUAN_SHANGOU: PlatformDisplayInfo(
        id=PlatformType.MEITUAN_SHANGOU,
        name="美团闪购",
        color_hex="#FF9900",
        badge_title="30分即达",
        scheme_prefix="imeituan://www.meituan.com/takeaway/shangou"
    ),
    PlatformType.TAOBAO_SHANGOU: PlatformDisplayInfo(
        id=PlatformType.TAOBAO_SHANGOU,
        name="淘宝闪购",
        color_hex="#FF5000",
        badge_title="同城闪购",
        scheme_prefix="taobao://takeaway"
    )
}

# 服务基础配置
SERVER_HOST = "0.0.0.0"
SERVER_PORT = 8000
DEBUG_MODE = True
MOCK_SIMULATION_ENABLED = True  # 当缺乏各平台商用逆向Session时启用高仿真智能报价引擎
