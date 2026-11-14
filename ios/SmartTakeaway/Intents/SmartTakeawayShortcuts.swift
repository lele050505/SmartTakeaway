import AppIntents

/// App Shortcut 短语规则：
/// - 每条短语必须包含 \(.applicationName)
/// - 短语中的参数只能是 AppEnum / AppEntity；String 参数放进短语会导致构建期元数据报错
public struct SmartTakeawayShortcuts: AppShortcutsProvider {
    public static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CompareTakeawayIntent(),
            phrases: [
                "用\(.applicationName)比价外卖",
                "用\(.applicationName)点外卖",
                "在\(.applicationName)查哪家外卖最便宜"
            ],
            shortTitle: "外卖比价",
            systemImageName: "cart.badge.plus"
        )
        AppShortcut(
            intent: QuickCompareIntent(),
            phrases: [
                "用\(.applicationName)比价\(\.$item)",
                "用\(.applicationName)点\(\.$item)"
            ],
            shortTitle: "常点商品比价",
            systemImageName: "bolt.fill"
        )
    }
}
