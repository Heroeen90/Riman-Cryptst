import 'package:flutter/material.dart';
import 'command_bar.dart';
import 'deception_radar.dart';
import 'dynamic_theme_panel.dart';
import 'reorderable_dashboard_grid.dart';
import 'telemetry_graph_canvas.dart';

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
import '../utils/network_pinning_service.dart';
import '../utils/in_memory_crypto_wrapper.dart';
import '../utils/integrity_attestation_manager.dart';

import '../utils/biometric_storage_service.dart';
import '../utils/window_security_service.dart';
import '../utils/crypto_engine.dart';
import '../utils/environment_checker.dart';
import '../utils/clipboard_protection_service.dart';
import '../utils/hardware_sentinel.dart';
import '../utils/keyboard_security_service.dart';
import '../utils/secure_platform_channel.dart';
import '../utils/scoped_storage_manager.dart';

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
  Color _accentColor = Colors.cyan;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initSecurityPipeline();
    });
  }

  Future<void> _initSecurityPipeline() async {
    await WindowSecurityService.secureScreen();
    ClipboardProtectionService.startMonitoring();
    bool isSecure = await IntegrityAttestationManager.checkPlatformIntegrity();
    final metrics = await HardwareSentinel.getHardwareMetrics();
    if (!isSecure) {
      debugPrint('Security alert: Tampering detected! Metrics: $metrics');
    }
    
    // Convergence check
    final status = isSecure ? 'CONVERGED: SECURE' : 'THREAT: COMPROMISED';
    widget.onSuccess(status, isSecure ? 'success' : 'error');
  }

  String _locVal(String en, String ar) {
    return widget.locale == 'ar' ? ar : en;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Text(
                _locVal('RIMAN CITADEL MASTER CONVERGENCE', 'نواة قلعة ريمان القصوى'),
                style: TextStyle(color: _accentColor, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              // Anchors preserved
              const Icon(Icons.monitor_heart, color: Colors.green),
              const SizedBox(width: 8),
              const Icon(Icons.security, color: Colors.cyan),
            ],
          ),
          const SizedBox(height: 16),
          DynamicThemePanel(
            currentColor: _accentColor,
            onColorChanged: (color) => setState(() => _accentColor = color),
          ),
          const SizedBox(height: 16),
          CommandBarWidget(locale: widget.locale, onSuccess: widget.onSuccess),
          const SizedBox(height: 16),
          const TelemetryGraphCanvas(),
          const SizedBox(height: 16),
          const DeceptionRadarWidget(),
          const SizedBox(height: 16),
          const ReorderableDashboardGrid(),
          const SizedBox(height: 16),
          // Master Convergence Status
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                Text(
                  _locVal('CONVERGENCE STATUS: V100.0 OPERATIONAL', 'حالة النظم: V100.0 جاهز'),
                  style: const TextStyle(color: Colors.blueGrey, fontFamily: 'JetBrains Mono'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
