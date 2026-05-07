import 'dart:async';
import 'dart:io';
import 'package:multicast_dns/multicast_dns.dart';
import '../models/device_info.dart';

const List<int> defaultPorts = [
  21, 22, 23, 80, 443, 445, 1883, 3389, 5000, 5555, 8080, 8443, 9100
];

class ScanProgress {
  final int total;
  final int scanned;
  final DeviceInfo? newDevice;

  ScanProgress({required this.total, required this.scanned, this.newDevice});

  double get percent => total == 0 ? 0 : scanned / total;
}

class ScannerService {
  bool _cancelled = false;

  void cancel() => _cancelled = true;

  /// Parse CIDR notation, returns list of IP strings
  static List<String> parseCidr(String cidr) {
    final parts = cidr.trim().split('/');
    if (parts.length != 2) throw FormatException('Invalid CIDR: $cidr');

    final ip = parts[0].trim();
    final prefix = int.parse(parts[1].trim());
    if (prefix < 0 || prefix > 32) throw FormatException('Invalid prefix length');

    final ipParts = ip.split('.');
    if (ipParts.length != 4) throw FormatException('Invalid IP address');

    final ipInt = ipParts.fold<int>(0, (acc, part) => (acc << 8) | int.parse(part));
    final mask = prefix == 0 ? 0 : (0xFFFFFFFF << (32 - prefix)) & 0xFFFFFFFF;
    final network = ipInt & mask;
    final broadcast = network | (~mask & 0xFFFFFFFF);

    final ips = <String>[];
    for (int addr = network + 1; addr < broadcast; addr++) {
      ips.add([
        (addr >> 24) & 0xFF,
        (addr >> 16) & 0xFF,
        (addr >> 8) & 0xFF,
        addr & 0xFF,
      ].join('.'));
    }
    return ips;
  }

  Stream<ScanProgress> scan({
    required String cidr,
    List<int>? ports,
    int concurrency = 80,
    int timeoutMs = 800,
  }) async* {
    _cancelled = false;
    final portList = (ports != null && ports.isNotEmpty) ? ports : defaultPorts;
    final ips = parseCidr(cidr);
    final total = ips.length;
    int scanned = 0;

    // Start mDNS discovery in background
    final mdnsResults = <String, String>{};
    _startMdns(mdnsResults);

    final semaphore = _Semaphore(concurrency);
    final pending = <Future<DeviceInfo?>>[];

    for (final ip in ips) {
      if (_cancelled) break;
      final future = semaphore.run(() => _probeHost(ip, portList, timeoutMs));
      pending.add(future);
    }

    // Yield progress as each IP completes
    for (int i = 0; i < pending.length; i++) {
      if (_cancelled) break;
      final device = await pending[i];
      scanned++;

      DeviceInfo? result = device;
      if (result == null && mdnsResults.containsKey(ips[i])) {
        // Found via mDNS but not TCP — still report it
        result = DeviceInfo(
          ip: ips[i],
          hostname: mdnsResults[ips[i]]!,
          openPorts: [],
          discoveredAt: DateTime.now(),
        );
      }

      yield ScanProgress(total: total, scanned: scanned, newDevice: result);
    }

  }

  Future<DeviceInfo?> _probeHost(String ip, List<int> ports, int timeoutMs) async {
    final openPorts = <int>[];

    await Future.wait(ports.map((port) async {
      try {
        final socket = await Socket.connect(
          ip,
          port,
          timeout: Duration(milliseconds: timeoutMs),
        );
        openPorts.add(port);
        await socket.close();
      } catch (e) {
        // Connection refused (SocketException with errno 111) = host is UP but port closed
        if (e is SocketException) {
          final msg = e.message.toLowerCase();
          if (msg.contains('connection refused') ||
              msg.contains('errno = 111') ||
              msg.contains('errno = 61')) {
            openPorts.add(-port); // negative = refused (host alive)
          }
        }
      }
    }));

    // Host is alive if any port connected OR any port was refused
    final alive = openPorts.isNotEmpty;
    if (!alive) return null;

    // Only report actually open (positive) ports
    final actualOpen = openPorts.where((p) => p > 0).toList()..sort();

    // Try hostname resolution
    String hostname = '';
    try {
      final result = await InternetAddress(ip).reverse().timeout(
        const Duration(milliseconds: 1500),
      );
      hostname = result.host;
    } catch (_) {}

    return DeviceInfo(
      ip: ip,
      hostname: hostname,
      openPorts: actualOpen,
      discoveredAt: DateTime.now(),
    );
  }

  void _startMdns(Map<String, String> results) async {
    try {
      final client = MDnsClient();
      await client.start();
      await client
          .lookup<PtrResourceRecord>(ResourceRecordQuery.serverPointer('_services._dns-sd._udp.local'))
          .timeout(const Duration(seconds: 8), onTimeout: (s) => s.close())
          .drain<void>();
      client.stop();
    } catch (_) {}
  }
}

class _Semaphore {
  final int maxConcurrent;
  int _current = 0;
  final _queue = <Completer<void>>[];

  _Semaphore(this.maxConcurrent);

  Future<T> run<T>(Future<T> Function() fn) async {
    if (_current >= maxConcurrent) {
      final completer = Completer<void>();
      _queue.add(completer);
      await completer.future;
    }
    _current++;
    try {
      return await fn();
    } finally {
      _current--;
      if (_queue.isNotEmpty) {
        _queue.removeAt(0).complete();
      }
    }
  }
}
