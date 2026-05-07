class DeviceInfo {
  final String ip;
  final String hostname;
  final List<int> openPorts;
  final DateTime discoveredAt;

  DeviceInfo({
    required this.ip,
    required this.hostname,
    required this.openPorts,
    required this.discoveredAt,
  });

  String get displayName {
    if (hostname.isNotEmpty && hostname != ip) return hostname;
    return ip;
  }

  String get portSummary {
    if (openPorts.isEmpty) return 'mDNS';
    return openPorts.map((p) => _portLabel(p)).join(', ');
  }

  String _portLabel(int port) {
    const labels = {
      21: 'FTP',
      22: 'SSH',
      23: 'Telnet',
      80: 'HTTP',
      443: 'HTTPS',
      445: 'SMB',
      1883: 'MQTT',
      3389: 'RDP',
      5000: 'UPnP',
      5555: 'ADB',
      8080: 'HTTP-Alt',
      8443: 'HTTPS-Alt',
      9100: 'Print',
    };
    return labels[port] ?? '$port';
  }

  String get deviceIcon {
    for (final p in openPorts) {
      if (p == 3389) return '🖥️';
      if (p == 22) return '🐧';
      if (p == 445) return '💾';
      if (p == 9100) return '🖨️';
      if (p == 5555) return '📱';
      if (p == 1883) return '🔌';
    }
    if (hostname.toLowerCase().contains('router') ||
        hostname.toLowerCase().contains('gateway')) return '📡';
    if (openPorts.contains(80) || openPorts.contains(443)) return '🌐';
    return '📟';
  }
}
