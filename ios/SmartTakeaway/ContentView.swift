import SwiftUI

public struct ContentView: View {
    @State private var searchKeyword: String = "生椰拿铁"
    @AppStorage(TakeawayAPIService.baseURLDefaultsKey) private var serverURL: String = TakeawayAPIService.defaultBaseURL
    @State private var isComparing: Bool = false
    @State private var currentResult: CompareResponse?
    @State private var errorMessage: String?
    
    let sampleKeywords = ["生椰拿铁", "可口可乐", "麦当劳", "霸王茶姬", "抽纸"]
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // 若当前结果为离线兜底，显示高亮警告
                    if let result = currentResult, result.is_simulated {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("当前为离线本地仿真数据")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.orange)
                                Text("未连通后端开发机。真机测试请将 127.0.0.1 改为电脑局域网 IP。")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding(10)
                        .background(Color.orange.opacity(0.12))
                        .cornerRadius(10)
                    }
                    
                    // Siri 语音操作向导卡片
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "mic.fill.badge.plus")
                                .font(.title3)
                                .foregroundColor(.purple)
                            Text("Apple Siri 语音深度操作已就绪")
                                .font(.headline)
                                .fontWeight(.bold)
                        }
                        
                        Text("你可以随时长按电源键或呼唤 Siri：")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("🗣️ “嘿 Siri，用 SmartTakeaway 帮我比价外卖”")
                                    .font(.caption)
                                    .foregroundColor(.purple)
                            }
                            HStack {
                                Text("🗣️ “嘿 Siri，在 SmartTakeaway 比价 生椰拿铁”")
                                    .font(.caption)
                                    .foregroundColor(.purple)
                            }
                        }
                        .padding(8)
                        .background(Color.purple.opacity(0.08))
                        .cornerRadius(8)
                    }
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color(.secondarySystemGroupedBackground)))
                    
                    // 搜索输入栏
                    VStack(alignment: .leading, spacing: 10) {
                        Text("🔍 实时跨平台比价测试")
                            .font(.subheadline)
                            .fontWeight(.bold)
                        
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                            TextField("输入餐品或商品名", text: $searchKeyword)
                                .textFieldStyle(.plain)
                            
                            if isComparing {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Button("比价") {
                                    runComparison()
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        }
                        .padding(10)
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        
                        // 预设快速测试药丸按钮
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(sampleKeywords, id: \.self) { kw in
                                    Button(action: {
                                        searchKeyword = kw
                                        runComparison()
                                    }) {
                                        Text(kw)
                                            .font(.caption)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 5)
                                            .background(searchKeyword == kw ? Color.blue.opacity(0.15) : Color(.systemGray6))
                                            .foregroundColor(searchKeyword == kw ? .blue : .primary)
                                            .cornerRadius(12)
                                    }
                                }
                            }
                        }
                    }
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color(.secondarySystemGroupedBackground)))
                    
                    // 比价结果呈现区
                    if let result = currentResult {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack {
                                        Text("比价结果 · \(result.query)")
                                            .font(.headline)
                                            .fontWeight(.bold)
                                        if !result.is_simulated {
                                            Text("实时后端响应")
                                                .font(.caption2)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color.green.opacity(0.15))
                                                .foregroundColor(.green)
                                                .cornerRadius(6)
                                        }
                                    }
                                    Text(result.voice_speech_text)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                if result.max_saved_amount > 0 {
                                    VStack {
                                        Text("最多立省")
                                            .font(.caption2)
                                            .foregroundColor(.white)
                                        Text("¥\(String(format: "%.1f", result.max_saved_amount))")
                                            .font(.title3)
                                            .fontWeight(.heavy)
                                            .foregroundColor(.white)
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.green)
                                    .cornerRadius(10)
                                }
                            }
                            .padding(.bottom, 4)
                            
                            // 各平台卡片列表
                            ForEach(result.quotes) { quote in
                                PlatformQuoteCard(quote: quote)
                            }
                        }
                    } else if let error = errorMessage {
                        Text("❌ \(error)")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    
                    // 后端配置折叠区
                    DisclosureGroup("⚙️ 后端网络与真机连接设置") {
                        VStack(alignment: .leading, spacing: 8) {
                            TextField("服务器地址 (如 http://192.168.1.100:8000)", text: $serverURL)
                                .textFieldStyle(.roundedBorder)
                                .font(.caption)
                            Text("💡 提示：在真机 iPhone 运行时，127.0.0.1 指向手机自身，请务必填写电脑局域网 IP（在电脑命令行运行 ipconfig 查看）。")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 6)
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color(.secondarySystemGroupedBackground)))
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("SmartTakeaway")
            .onAppear {
                runComparison()
            }
        }
    }
    
    private func runComparison() {
        guard !searchKeyword.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isComparing = true
        errorMessage = nil
        
        Task {
            do {
                let res = try await TakeawayAPIService.shared.fetchComparison(keyword: searchKeyword)
                await MainActor.run {
                    self.currentResult = res
                    self.isComparing = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isComparing = false
                }
            }
        }
    }
}
