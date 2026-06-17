import 'package:flutter/material.dart';
import 'command_bar.dart';
import 'deception_radar.dart';
import '../utils/threat_matrix_analytics.dart';

class RimanFlagshipHubWidget extends StatelessWidget {
  final String locale;
  final Function(String message, String type) onSuccess;

  const RimanFlagshipHubWidget({
    Key? key,
    required this.locale,
    required this.onSuccess,
  }) : super(key: key);

  String _locVal(String en, String ar) {
    return locale == 'ar' ? ar : en;
  }

  @override
  Widget build(BuildContext context) {
    final threatScore = ThreatMatrixAnalytics.calculateThreatScore();
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Text(
                _locVal('RIMAN FLAGSHIP HUB', 'مركز عمليات ريمان'),
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              // Anchor required for testing
              const Icon(Icons.monitor_heart, color: Colors.green),
              const SizedBox(width: 8),
              const Icon(Icons.security, color: Colors.cyan),
            ],
          ),
          const SizedBox(height: 16),
          CommandBarWidget(locale: locale, onSuccess: onSuccess),
          const SizedBox(height: 16),
          const DeceptionRadarWidget(),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(16)),
            child: Text(
              _locVal('Threat Score: ${threatScore.toStringAsFixed(1)}%', 'مستوى التهديد: ${threatScore.toStringAsFixed(1)}%'),
              style: TextStyle(color: threatScore > 50 ? Colors.red : Colors.green, fontFamily: 'JetBrains Mono'),
            ),
          )
        ],
      ),
    );
  }
}
