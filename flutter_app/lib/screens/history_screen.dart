import 'package:flutter/material.dart';
import '../models/takeaway_models.dart';
import '../services/history_service.dart';

class HistoryScreen extends StatefulWidget {
  final ValueChanged<String> onRecompare;

  const HistoryScreen({super.key, required this.onRecompare});

  @override
  State<HistoryScreen> createState() => HistoryScreenState();
}

class HistoryScreenState extends State<HistoryScreen> {
  final HistoryService _historyService = HistoryService();
  List<HistoryRecord> _records = [];

  @override
  void initState() {
    super.initState();
    reload();
  }

  Future<void> reload() async {
    final list = await _historyService.getHistory();
    if (mounted) {
      setState(() => _records = list);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '比价历史',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_records.isNotEmpty)
            IconButton(
              tooltip: '清空记录',
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                await _historyService.clearHistory();
                await reload();
              },
            ),
        ],
      ),
      body: _records.isEmpty
          ? const Center(
              child: Text(
                '暂无比价记录，去首页搜一款外卖试试吧',
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(14),
              itemCount: _records.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, idx) {
                final item = _records[idx];
                return Card(
                  child: ListTile(
                    title: Row(
                      children: [
                        Text(
                          item.keyword,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        if (item.isSimulated)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              '仿真',
                              style: TextStyle(fontSize: 10, color: Colors.orange),
                            ),
                          ),
                      ],
                    ),
                    subtitle: Text(
                      '最优: ${item.bestPlatform} ¥${item.bestPrice.toStringAsFixed(1)} · 省 ¥${item.savedAmount.toStringAsFixed(1)}\n${item.timestamp}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    isThreeLine: true,
                    trailing: TextButton(
                      onPressed: () => widget.onRecompare(item.keyword),
                      child: const Text('再比一次'),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
