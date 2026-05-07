import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/device_info.dart';

class DeviceCard extends StatelessWidget {
  final DeviceInfo device;
  const DeviceCard({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF0D1117),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(device.deviceIcon, style: const TextStyle(fontSize: 22)),
          ),
        ),
        title: Row(
          children: [
            Text(
              device.ip,
              style: const TextStyle(
                color: Color(0xFF58A6FF),
                fontFamily: 'monospace',
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (device.hostname.isNotEmpty && device.hostname != device.ip) ...[
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  device.hostname,
                  style: const TextStyle(
                    color: Color(0xFF8B949E),
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
        subtitle: device.openPorts.isNotEmpty
            ? Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: device.openPorts
                      .map((p) => _PortChip(port: p))
                      .toList(),
                ),
              )
            : null,
        trailing: IconButton(
          icon: const Icon(Icons.copy, size: 16, color: Color(0xFF484F58)),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: device.ip));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('已复制 ${device.ip}'),
                duration: const Duration(seconds: 1),
                backgroundColor: const Color(0xFF238636),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PortChip extends StatelessWidget {
  final int port;
  const _PortChip({required this.port});

  @override
  Widget build(BuildContext context) {
    const colors = {
      80: Color(0xFF1F6FEB),
      443: Color(0xFF238636),
      22: Color(0xFF9E6A03),
      3389: Color(0xFF8957E5),
      445: Color(0xFF1F6FEB),
      5555: Color(0xFFDA3633),
    };
    final color = colors[port] ?? const Color(0xFF30363D);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.6)),
      ),
      child: Text(
        '$port',
        style: TextStyle(color: color, fontSize: 11, fontFamily: 'monospace'),
      ),
    );
  }
}
