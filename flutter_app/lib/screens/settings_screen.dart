import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TakeawayApiService _apiService = TakeawayApiService();
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  String? _statusText;
  bool? _isConnected;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _urlController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final url = await _apiService.getBaseUrl();
    final addr = await _apiService.getAddress();
    if (mounted) {
      setState(() {
        _urlController.text = url;
        _addressController.text = addr;
      });
    }
  }

  Future<void> _saveAndTest() async {
    final url = _urlController.text.trim();
    final addr = _addressController.text.trim();
    await _apiService.setBaseUrl(url);
    await _apiService.setAddress(addr);
    final ok = await _apiService.checkHealth(url);
    if (mounted) {
      setState(() {
        _isConnected = ok;
        _statusText = ok ? '已成功连通后端服务！' : '无法连接到 $url，请确认后端已启动且在同一局域网。';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '设置与 Siri 桥接',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '后端比价服务配置',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _urlController,
                    decoration: const InputDecoration(
                      labelText: '后端 API 地址',
                      hintText: 'http://10.0.2.2:8000',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '提示：Windows Android 模拟器填 http://10.0.2.2:8000；真机（iPhone / Android 手机）请填电脑局域网 IP（例如 http://192.168.1.100:8000）。',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: '默认配送地址',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _saveAndTest,
                      icon: const Icon(Icons.wifi_tethering),
                      label: const Text('保存并测试连接'),
                    ),
                  ),
                  if (_statusText != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _statusText!,
                      style: TextStyle(
                        fontSize: 12,
                        color: _isConnected == true ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.mic, color: Colors.purple),
                      SizedBox(width: 6),
                      Text(
                        'Apple Siri 快捷指令胶水桥接',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '在 iPhone「快捷指令」App 中新建指令，即可通过 Siri 语音直接唤起本 App 并自动比价：',
                    style: TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.purple.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'smarttakeaway://compare?q=生椰拿铁',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(
                        const ClipboardData(text: 'smarttakeaway://compare?q=生椰拿铁'),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('已复制 Deep Link 示例')),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('复制调起链接格式'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
