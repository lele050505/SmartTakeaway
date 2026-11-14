# Siri 与 Xcode 真机调试指南

> 当前所有平台报价都是**模拟数据**。本文档用于在 Mac + iPhone 上验证 Siri 链路。

## 一、环境要求

- macOS + **Xcode 26 或更高**
- **iOS 26+** 真机（`SnippetIntent` 交互卡片的最低系统要求）
- iPhone 与电脑连接同一个 Wi‑Fi

## 二、在 Xcode 中创建工程

1. 新建 iOS App 工程，Product Name 填 `SmartTakeaway`，Interface 选 SwiftUI，Bundle ID 建议填 `com.smarttakeaway.app`。
2. 删除模板生成的 `ContentView.swift` 和 `*App.swift`，再把 `ios/SmartTakeaway/` 下的 `Core/`、`Intents/`、`Services/`、`Views/`、`ContentView.swift`、`SmartTakeawayApp.swift` 拖进 App Target。
3. 把 `ios/SmartTakeaway/Info.plist` 中的 `LSApplicationQueriesSchemes`、`NSAppTransportSecurity`、`NSSiriUsageDescription` 合并到工程的 Info 设置里。
4. **Deployment Target 设为 iOS 26.0**。
5. 可选：在 `ios/` 目录执行 `swift test`，先跑一遍 Core 单元测试。

## 三、连接后端

1. 在电脑上执行 `start_server.bat`（监听 `0.0.0.0:8000`）。
2. 用 `ipconfig` 查看电脑的局域网 IP。
3. 在 App 底部的「后端网络与真机连接设置」中填入 `http://<电脑IP>:8000`。这个地址会存进 UserDefaults，Siri 执行时也会使用它。
4. 如果页面顶部出现橙色的「离线本地仿真数据」提示，说明没有连上后端。

## 四、Siri 短语

| 说法 | 对应意图 | 说明 |
| :--- | :--- | :--- |
| 用外卖智能比价比价外卖 / 点外卖 | `CompareTakeawayIntent` | Siri 会追问商品名，可以说任意商品 |
| 在外卖智能比价查哪家外卖最便宜 | `CompareTakeawayIntent` | 同上 |
| 用外卖智能比价比价**生椰拿铁** | `QuickCompareIntent` | 一句话说完，仅限 `PopularItem` 中的常点商品 |

> App Shortcut 短语里只能放 AppEnum / AppEntity 类型的参数，不能放任意 String。所以「任意商品一句话说完」目前做不到，只能先说触发短语，再回答 Siri 的追问。

## 五、真机验收清单

- [ ] App 能编译并安装
- [ ] 「设置 → Siri」中能看到本 App 的快捷指令
- [ ] 说出短语后，Siri 播报的价格与卡片显示一致
- [ ] 卡片「去下单」能拉起对应平台 App（美团 / 饿了么 / 淘宝）
- [ ] 卸载饿了么后点击饿了么报价，打开的是 `h5.ele.me`，**不是**美团网页
- [ ] 断开后端时，界面显示离线仿真警告
