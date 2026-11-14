# SmartTakeaway：外卖 / 闪购比价 + Siri 下单助手（MVP）

覆盖 **美团外卖、饿了么、美团闪购、淘宝闪购**：先比较到手价，再通过 Siri 或 App 跳转到最便宜的平台，由用户用 Face ID 完成支付。

> [!IMPORTANT]
> **平台报价目前是 PoC 模拟数据**，还没有接入任何平台的真实接口。这一版验证的是「比价算法 → Siri 语音 / 卡片 → 跳转下单」这条链路是否走得通。所有响应都带 `is_simulated: true`。

---

## 验证状态（如实列出）

| 项目 | 状态 | 怎么验证 |
| :--- | :--- | :--- |
| 后端比价算法、排序、费用公式 | ✅ 已通过（Windows） | `cd backend && python -W error test_api.py` |
| 单平台异常隔离、`failed_platforms` 记录 | ✅ 已通过（Windows） | 同上（注入故障适配器） |
| 后端生成的链接符合 iOS 跳转白名单 | ✅ 已通过（Windows） | 同上 |
| Swift `totalDiscount` / `DeepLinkPolicy` / `ComparisonCache` | ⏳ 已写好测试，**尚未运行** | 在 Mac 上执行 `cd ios && swift test` |
| iOS App 编译 | ⏳ **未验证** | 需要 Xcode 26+ |
| Siri 短语注册、交互卡片、跳转第三方 App | ⏳ **未验证** | 需要 iOS 26+ 真机 |

开发环境是 Windows，没有 Swift / Xcode 工具链，所以上面 ⏳ 的项目只做过源码层面的检查。

---

## 架构要点

- **后端**（Python FastAPI）：4 个平台适配器并发报价，统一计算
  `到手价 = 原价 − 店铺满减 − 平台券 + 配送费 + 包装费`，按到手价升序排序，并生成 Siri 播报文案。
- **iOS**（SwiftUI + App Intents，**最低 iOS 26**，因为用到了 `SnippetIntent`）
  - `CompareTakeawayIntent`：可以说任意商品名，Siri 会追问「你想比价什么？」
  - `QuickCompareIntent` + `PopularItem`（AppEnum）：常点商品可以一句话说完，例如「用外卖智能比价比价生椰拿铁」
  - `TakeawayComparisonSnippetIntent`（`SnippetIntent`）：负责渲染可交互卡片；主意图通过 `snippetIntent:` 返回它
  - `ComparisonCache`：主意图只请求一次后端，卡片直接读缓存，保证语音和卡片显示的是同一份报价
  - `OpenTakeawayURLIntent` + `DeepLinkPolicy`：链接 Scheme 必须属于该报价的平台；App 打不开时只回退到**该平台自己的** https 网页，其他链接一律拦截
  - 后端地址存在 `UserDefaults`（`@AppStorage`）里，Siri 在后台执行时也能读到同一个局域网 IP

---

## 目录结构

```
SmartTakeaway/
├── backend/
│   ├── app/
│   │   ├── adapters/          # meituan / eleme / meituan_shangou / taobao_shangou（模拟数据）
│   │   ├── services/comparator.py
│   │   ├── schemas.py · config.py · main.py
│   ├── requirements.txt
│   └── test_api.py            # 后端断言测试
├── ios/
│   ├── Package.swift          # 只包含 Core 纯逻辑，用于 swift test
│   ├── Tests/SmartTakeawayCoreTests/SmartTakeawayCoreTests.swift
│   └── SmartTakeaway/
│       ├── Core/              # 纯 Foundation：TakeawayModels / DeepLinkPolicy / ComparisonCache
│       ├── Intents/           # CompareTakeawayIntent（含 SnippetIntent、QuickCompare）/ OpenTakeawayURLIntent / Shortcuts
│       ├── Services/TakeawayAPIService.swift
│       ├── Views/ComparisonResultCardView.swift
│       ├── ContentView.swift · SmartTakeawayApp.swift · Info.plist
├── docs/ARCHITECTURE.md · docs/SIRI_SHORTCUTS_SETUP.md
└── start_server.bat / start_server.ps1
```

---

## 运行

**后端**
```bash
cd backend
pip install -r requirements.txt
python -W error test_api.py                 # 断言测试
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000
```

**Swift 单元测试（Mac）**
```bash
cd ios
swift test
```

**iOS App（Mac + Xcode 26）**：步骤见 [docs/SIRI_SHORTCUTS_SETUP.md](docs/SIRI_SHORTCUTS_SETUP.md)。

---

## 已知限制 / 下一步

1. 接入真实报价：可选企业开放平台 / CPS 接口，或参考 `ucloud/orderwise-agent` 的云手机 + 视觉 Agent 方案。注意风控和平台服务条款。
2. 点击卡片「去下单」时会先拉起本 App（`openAppWhenRun`），再跳转到目标平台。以后可以评估改用 `OpenURLIntent` 直接跳转。
3. 如果以后把意图放进 App Intents Extension，`UserDefaults` 和缓存需要改用 App Group 共享。
4. 各平台 URL Scheme 的落地页路径来自公开资料，需要在真机上逐个确认能打开正确的页面。
