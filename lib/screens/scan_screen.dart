import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import '../models/device_info.dart';
import '../services/scanner_service.dart';
import '../widgets/device_card.dart';
import '../widgets/port_input_field.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _cidrController = TextEditingController();
  final _portController = TextEditingController();
  final _scanner = ScannerService();

  List<DeviceInfo> _devices = [];
  bool _scanning = false;
  double _progress = 0;
  int _scanned = 0;
  int _total = 0;
  String _statusText = '';
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _autoFillCidr();
  }

  Future<void> _autoFillCidr() async {
    try {
      final info = NetworkInfo();
      final ip = await info.getWifiIP();
      if (ip != null && ip.isNotEmpty) {
        final parts = ip.split('.');
        if (parts.length == 4) {
          _cidrController.text = '${parts[0]}.${parts[1]}.${parts[2]}.0/24';
        }
      }
    } catch (_) {}
  }

  List<int>? _parsePorts() {
    final text = _portController.text.trim();
    if (text.isEmpty) return null;
    try {
      return text
          .split(RegExp(r'[,\s]+'))
          .where((s) => s.isNotEmpty)
          .map((s) => int.parse(s.trim()))
          .where((p) => p > 0 && p <= 65535)
          .toList();
    } catch (_) {
      return null;
    }
  }

  void _startScan() {
    final cidr = _cidrController.text.trim();
    if (cidr.isEmpty) {
      _showError('请输入网段，例如 192.168.1.0/24');
      return;
    }

    final ports = _parsePorts();
    final portText = _portController.text.trim();
    if (portText.isNotEmpty && ports == null) {
      _showError('端口格式错误，请用逗号分隔，例如：80,443,22');
      return;
    }

    setState(() {
      _devices = [];
      _scanning = true;
      _progress = 0;
      _scanned = 0;
      _total = 0;
      _statusText = '正在扫描...';
    });

    _sub = _scanner
        .scan(cidr: cidr, ports: ports)
        .listen(
          (progress) {
            setState(() {
              _scanned = progress.scanned;
              _total = progress.total;
              _progress = progress.percent;
              _statusText = '扫描中 $_scanned / $_total';
              if (progress.newDevice != null) {
                _devices = [progress.newDevice!, ..._devices];
              }
            });
          },
          onDone: () {
            setState(() {
              _scanning = false;
              _statusText = '扫描完成，发现 ${_devices.length} 台设备';
            });
          },
          onError: (e) {
            setState(() {
              _scanning = false;
              _statusText = '错误：$e';
            });
            _showError(e.toString());
          },
        );
  }

  void _stopScan() {
    _scanner.cancel();
    _sub?.cancel();
    setState(() {
      _scanning = false;
      _statusText = '已停止，发现 ${_devices.length} 台设备';
    });
  }

  void _exportResults() {
    if (_devices.isEmpty) return;
    final buf = StringBuffer();
    buf.writeln('LAN扫描结果 - ${DateTime.now().toString().substring(0, 19)}');
    buf.writeln('网段: ${_cidrController.text}');
    buf.writeln('─' * 40);
    for (final d in _devices) {
      buf.writeln('IP: ${d.ip}');
      if (d.hostname.isNotEmpty && d.hostname != d.ip) {
        buf.writeln('  主机名: ${d.hostname}');
      }
      if (d.openPorts.isNotEmpty) {
        buf.writeln('  开放端口: ${d.portSummary}');
      }
      buf.writeln();
    }
    Share.share(buf.toString(), subject: 'LAN扫描结果');
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red[700]),
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    _cidrController.dispose();
    _portController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        title: Row(
          children: [
            const Text('📡', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              'LAN Scanner',
              style: theme.textTheme.titleLarge?.copyWith(
                color: const Color(0xFF58A6FF),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          if (_devices.isNotEmpty && !_scanning)
            IconButton(
              icon: const Icon(Icons.share, color: Color(0xFF58A6FF)),
              onPressed: _exportResults,
              tooltip: '导出结果',
            ),
        ],
      ),
      body: Column(
        children: [
          _buildInputPanel(theme),
          _buildProgressBar(),
          _buildStatusBar(theme),
          Expanded(child: _buildDeviceList(theme)),
        ],
      ),
    );
  }

  Widget _buildInputPanel(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF161B22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // CIDR input
          _label('🌐 扫描网段 (CIDR)'),
          const SizedBox(height: 6),
          TextField(
            controller: _cidrController,
            enabled: !_scanning,
            style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
            decoration: _inputDeco('例如 192.168.1.0/24'),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9./]'))],
          ),
          const SizedBox(height: 12),
          // Port input
          _label('🔌 自定义端口 (留空使用默认13个端口)'),
          const SizedBox(height: 6),
          PortInputField(
            controller: _portController,
            enabled: !_scanning,
          ),
          const SizedBox(height: 16),
          // Scan button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: _scanning
                ? OutlinedButton.icon(
                    onPressed: _stopScan,
                    icon: const Icon(Icons.stop, color: Colors.red),
                    label: const Text('停止扫描', style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                    ),
                  )
                : ElevatedButton.icon(
                    onPressed: _startScan,
                    icon: const Icon(Icons.radar),
                    label: const Text('开始扫描', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF238636),
                      foregroundColor: Colors.white,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return LinearProgressIndicator(
      value: _scanning ? _progress : (_total > 0 ? 1.0 : 0.0),
      backgroundColor: const Color(0xFF21262D),
      valueColor: AlwaysStoppedAnimation<Color>(
        _scanning ? const Color(0xFF58A6FF) : const Color(0xFF238636),
      ),
      minHeight: 3,
    );
  }

  Widget _buildStatusBar(ThemeData theme) {
    if (_statusText.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFF161B22),
      child: Row(
        children: [
          if (_scanning)
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF58A6FF),
              ),
            ),
          if (_scanning) const SizedBox(width: 8),
          Text(
            _statusText,
            style: TextStyle(
              color: _scanning ? const Color(0xFF58A6FF) : const Color(0xFF3FB950),
              fontSize: 13,
            ),
          ),
          const Spacer(),
          if (_devices.isNotEmpty)
            Text(
              '${_devices.length} 台在线',
              style: const TextStyle(color: Color(0xFF3FB950), fontSize: 13),
            ),
        ],
      ),
    );
  }

  Widget _buildDeviceList(ThemeData theme) {
    if (_devices.isEmpty && !_scanning) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📡', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              '输入网段后点击扫描',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              '默认扫描常用13个端口',
              style: TextStyle(color: Colors.grey[700], fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _devices.length,
      itemBuilder: (ctx, i) => DeviceCard(device: _devices[i]),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(color: Color(0xFF8B949E), fontSize: 12),
      );

  InputDecoration _inputDeco(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF484F58)),
        filled: true,
        fillColor: const Color(0xFF0D1117),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFF30363D)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFF30363D)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFF58A6FF)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      );
}
