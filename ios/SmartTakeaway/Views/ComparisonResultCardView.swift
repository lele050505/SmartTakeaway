import SwiftUI
import AppIntents

public struct PlatformQuoteCard: View {
    public let quote: PlatformQuote
    public let isSnippetMode: Bool
    
    public init(quote: PlatformQuote, isSnippetMode: Bool = false) {
        self.quote = quote
        self.isSnippetMode = isSnippetMode
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(quote.platform_name)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(platformColor(for: quote.platform_id))
                
                if quote.is_best_deal {
                    Text("🌟 性价比之王")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(6)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("¥")
                            .font(.caption)
                            .fontWeight(.semibold)
                        Text(String(format: "%.1f", quote.price.final_price))
                            .font(.title2)
                            .fontWeight(.heavy)
                    }
                    .foregroundColor(quote.is_best_deal ? .red : .primary)
                    
                    if quote.saved_amount > 0 {
                        Text("省 ¥\(String(format: "%.1f", quote.saved_amount))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Text(quote.shop_name)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(1)
            
            // 费用明细微型标签
            HStack(spacing: 8) {
                Label("减¥\(String(format: "%.1f", quote.price.totalDiscount))", systemImage: "tag.fill")
                    .font(.caption2)
                    .foregroundColor(.orange)
                
                Label("运费¥\(String(format: "%.1f", quote.price.delivery_fee))", systemImage: "bicycle")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Label("\(quote.delivery_eta_minutes)分钟", systemImage: "clock")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                ForEach(quote.highlights.prefix(2), id: \.self) { tag in
                    Text(tag)
                        .font(.caption2)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color(.systemGray6))
                        .cornerRadius(4)
                }
                
                Spacer()
                
                // 由 SnippetIntent 承载的卡片中，按钮通过 AppIntent 执行；平台/链接/兜底一并传入并校验
                Button(intent: OpenTakeawayURLIntent(quote: quote)) {
                    HStack(spacing: 4) {
                        Text("去下单")
                            .font(.caption)
                            .fontWeight(.bold)
                        Image(systemName: "arrow.up.right.circle.fill")
                            .font(.caption)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(quote.is_best_deal ? Color.red : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: quote.is_best_deal ? Color.red.opacity(0.15) : Color.black.opacity(0.05), radius: 6, x: 0, y: 3)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(quote.is_best_deal ? Color.red.opacity(0.6) : Color.clear, lineWidth: 1.5)
                )
        )
    }
    
    private func platformColor(for type: PlatformType) -> Color {
        switch type {
        case .meituanWaimai: return Color(red: 0.95, green: 0.7, blue: 0.0)
        case .eleme: return Color(red: 0.0, green: 0.55, blue: 1.0)
        case .meituanShangou: return Color(red: 1.0, green: 0.5, blue: 0.0)
        case .taobaoShangou: return Color(red: 1.0, green: 0.3, blue: 0.0)
        }
    }
}

public struct ComparisonSnippetView: View {
    public let response: CompareResponse
    
    public init(response: CompareResponse) {
        self.response = response
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.yellow)
                Text("Siri 外卖多平台比价")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                if response.is_simulated {
                    Text("演示模式")
                        .font(.caption2)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.2))
                        .foregroundColor(.orange)
                        .cornerRadius(4)
                }
                Text("省 ¥\(String(format: "%.1f", response.max_saved_amount))")
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.green.opacity(0.2))
                    .foregroundColor(.green)
                    .cornerRadius(4)
            }
            
            if let best = response.best_quote {
                PlatformQuoteCard(quote: best, isSnippetMode: true)
            }
            
            Text("其余平台：")
                .font(.caption)
                .foregroundColor(.secondary)
            
            ForEach(response.quotes.filter { !$0.is_best_deal }.prefix(3)) { quote in
                HStack {
                    Text(quote.platform_name)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("¥\(String(format: "%.1f", quote.price.final_price))")
                        .font(.caption)
                        .fontWeight(.semibold)
                    Text("(\(quote.delivery_eta_minutes)分钟)")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 4)
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(14)
    }
}
