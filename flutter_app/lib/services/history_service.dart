import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/takeaway_models.dart';

class HistoryService {
  static const String _historyKey = 'compare_history_records';
  static const String _favoritesKey = 'favorite_keywords';
  static const int _maxHistory = 30;

  Future<List<HistoryRecord>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_historyKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => HistoryRecord.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> addRecord(CompareResponse response) async {
    final best = response.bestQuote;
    if (best == null) return;

    final record = HistoryRecord(
      keyword: response.query,
      bestPlatform: best.platformName,
      bestPrice: best.price.finalPrice,
      savedAmount: response.maxSavedAmount,
      timestamp: response.timestamp,
      isSimulated: response.isSimulated,
    );

    final list = await getHistory();
    list.insert(0, record);
    if (list.length > _maxHistory) {
      list.removeRange(_maxHistory, list.length);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _historyKey,
      jsonEncode(list.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }

  Future<List<String>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_favoritesKey) ??
        ['生椰拿铁', '可口可乐', '麦当劳', '霸王茶姬', '抽纸'];
  }

  Future<void> toggleFavorite(String keyword) async {
    final kw = keyword.trim();
    if (kw.isEmpty) return;
    final list = List<String>.from(await getFavorites());
    if (list.contains(kw)) {
      list.remove(kw);
    } else {
      list.insert(0, kw);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_favoritesKey, list);
  }
}
