import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/scanner_service.dart';

class PortInputField extends StatefulWidget {
  final TextEditingController controller;
  final bool enabled;
  const PortInputField({super.key, required this.controller, required this.enabled});

  @override
  State<PortInputField> createState() => _PortInputFieldState();
}

class _PortInputFieldState extends State<PortInputField> {
  bool _showDefaults = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: widget.controller,
          enabled: widget.enabled,
          style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 13),
          decoration: InputDecoration(
            hintText: '留空使用默认端口，或输入: 80,443,8080',
            hintStyle: const TextStyle(color: Color(0xFF484F58), fontSize: 12),
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
            suffixIcon: TextButton(
              onPressed: () => setState(() => _showDefaults = !_showDefaults),
              child: Text(
                _showDefaults ? '隐藏' : '默认',
                style: const TextStyle(color: Color(0xFF58A6FF), fontSize: 11),
              ),
            ),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9,\s]'))],
        ),
        if (_showDefaults) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: defaultPorts.map((p) {
              return GestureDetector(
                onTap: () {
                  final current = widget.controller.text.trim();
                  final ports = current.isEmpty
                      ? <String>[]
                      : current.split(',').map((s) => s.trim()).toList();
                  final ps = p.toString();
                  if (ports.contains(ps)) {
                    ports.remove(ps);
                  } else {
                    ports.add(ps);
                  }
                  widget.controller.text = ports.join(',');
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF21262D),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFF30363D)),
                  ),
                  child: Text(
                    '$p',
                    style: const TextStyle(
                      color: Color(0xFF8B949E),
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}
