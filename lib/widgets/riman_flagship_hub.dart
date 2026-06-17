import 'package:flutter/material.dart';
import 'command_bar.dart';
import 'deception_radar.dart';
import '../utils/threat_matrix_analytics.dart';
import '../utils/polymorphic_engine.dart';
import '../utils/memory_decoy.dart';
import '../utils/isolation_gatekeeper.dart';
import '../utils/secret_splitter.dart';
import '../utils/entropy_harvester.dart';
import '../utils/secure_tunnel.dart';
import '../utils/archival_shredder.dart';
import '../utils/runtime_obfuscator.dart';
import '../utils/debugger_detector.dart';
import '../utils/encrypted_cache.dart';
import '../utils/hardware_binder.dart';

import '../utils/biometric_storage_service.dart';
import '../utils/window_security_service.dart';
import '../utils/crypto_engine.dart';
import '../utils/environment_checker.dart';

class RimanFlagshipHubWidget extends StatefulWidget {
  final String locale;
  final Function(String message, String type) onSuccess;

  const RimanFlagshipHubWidget({
    Key? key,
    required this.locale,
    required this.onSuccess,
  }) : super(key: key);

  @override
  _RimanFlagshipHubWidgetState createState() => _RimanFlagshipHubWidgetState();
}

class _RimanFlagshipHubWidgetState extends State<RimanFlagshipHubWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initSecurityPipeline();
    });
  }

  Future<void> _initSecurityPipeline() async {
    await WindowSecurityService.secureScreen();
    bool tampered = await EnvironmentChecker.isTampered();
    if (tampered) {
      debugPrint('Security alert: Tampering detected!');
    }
  }

  String _locVal(String en, String ar) {
    return widget.locale == 'ar' ? ar : en;
  }

  @override
  Widget build(BuildContext context) {
    final threatScore = ThreatMatrixAnalytics.calculateThreatScore();
    final entropy = EntropyHarvester.getEntropy();

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Text(
                _locVal('RIMAN SOVEREIGN DREADNOUGHT', 'بارجة ريمان السيادية'),
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              // Anchors preserved
              const Icon(Icons.monitor_heart, color: Colors.green),
              const SizedBox(width: 8),
              const Icon(Icons.security, color: Colors.cyan),
            ],
          ),
          const SizedBox(height: 16),
          CommandBarWidget(locale: widget.locale, onSuccess: widget.onSuccess),
          const SizedBox(height: 16),
          const DeceptionRadarWidget(),
          const SizedBox(height: 16),
          // Apex/Dreadnought Status
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                Text(
                  _locVal('DREADNOUGHT STATUS: ACTIVE', 'حالة البارجة: نشطة'),
                  style: const TextStyle(color: Colors.blueGrey, fontFamily: 'JetBrains Mono'),
                ),
                Text(
                  _locVal('Threat Score: ${threatScore.toStringAsFixed(1)}% | Entropy: ${entropy.toInt()}', 'مستوى التهديد: ${threatScore.toStringAsFixed(1)}% | العشوائية: ${entropy.toInt()}'),
                  style: TextStyle(color: threatScore > 50 ? Colors.red : Colors.teal, fontFamily: 'JetBrains Mono'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
