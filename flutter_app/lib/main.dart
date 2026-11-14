import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'screens/home_screen.dart';
import 'screens/history_screen.dart';
import 'screens/settings_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // 严格限制图片/图层缓存上限为 10 MB，避免内存膨胀
  PaintingBinding.instance.imageCache.maximumSizeBytes = 10 * 1024 * 1024;
  PaintingBinding.instance.imageCache.maximumSize = 40;
  runApp(const SmartTakeawayApp());
}

class SmartTakeawayApp extends StatelessWidget {
  const SmartTakeawayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartTakeaway',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFFAFAFA),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF111111),
          secondary: Color(0xFF2E6F5E),
          surface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFAFAFA),
          foregroundColor: Color(0xFF111111),
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFFF3F2EE),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return TextStyle(
              fontSize: 11,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? const Color(0xFF111111) : const Color(0xFF888888),
            );
          }),
        ),
        useMaterial3: true,
      ),
      home: const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  final GlobalKey<HomeScreenState> _homeKey = GlobalKey<HomeScreenState>();
  final GlobalKey<HistoryScreenState> _historyKey = GlobalKey<HistoryScreenState>();

  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSub;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();

    // 冷启动 Deep Link
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleIncomingUri(initialUri);
      }
    } catch (_) {}

    // 热启动 Deep Link 监听
    _linkSub = _appLinks.uriLinkStream.listen(
      _handleIncomingUri,
      onError: (_) {},
    );
  }

  void _handleIncomingUri(Uri uri) {
    if (uri.scheme.toLowerCase() != 'smarttakeaway') return;
    // 支持 smarttakeaway://compare?q=生椰拿铁
    final keyword = uri.queryParameters['q'] ?? uri.queryParameters['keyword'];
    if (keyword != null && keyword.trim().isNotEmpty) {
      _pendingDeepLinkKeyword = keyword;
      setState(() => _currentIndex = 0);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _homeKey.currentState?.searchFromDeepLink(keyword);
      });
    }
  }

  String? _pendingDeepLinkKeyword;

  Widget _buildActivePage() {
    switch (_currentIndex) {
      case 0:
        final kw = _pendingDeepLinkKeyword;
        _pendingDeepLinkKeyword = null;
        return HomeScreen(
          key: _homeKey,
          initialKeyword: kw,
          onHistoryUpdated: () => _historyKey.currentState?.reload(),
        );
      case 1:
        return HistoryScreen(
          key: _historyKey,
          onRecompare: (kw) {
            _pendingDeepLinkKeyword = kw;
            setState(() => _currentIndex = 0);
          },
        );
      default:
        return const SettingsScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildActivePage(),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFEAEAEA), width: 0.8)),
        ),
        child: NavigationBar(
          height: 64,
          selectedIndex: _currentIndex,
          onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
          destinations: const [
          NavigationDestination(
            icon: Icon(Icons.compare_arrows_outlined),
            selectedIcon: Icon(Icons.compare_arrows),
            label: '比价',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: '历史',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: '设置',
          ),
        ],
      ),
      ),
    );
  }
}
