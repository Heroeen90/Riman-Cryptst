import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../utils/translations.dart';

class SovereignDashboardWidget extends StatefulWidget {
  final String locale;
  final Function(String message, String severity, String details) onSecurityLog;

  const SovereignDashboardWidget({
    Key? key,
    required this.locale,
    required this.onSecurityLog,
  }) : super(key: key);

  @override
  State<SovereignDashboardWidget> createState() => _SovereignDashboardWidgetState();
}

class _SovereignDashboardWidgetState extends State<SovereignDashboardWidget> {
  late Timer _fluctuateTimer;
  late Timer _rotationTimer;

  // Fluctuating values
  double _entropyReservoirVal = 99.987254;
  double _spectrumCoherenceVal = 98.42;
  double _matrixLoadVal = 34.21;
  int _secureTunnelsCount = 14;

  int _reseedSecondsRemaining = 45;
  bool _isReseeding = false;

  // Kinetic user harvesting
  int _kineticBytes = 0;
  bool _kineticRecording = false;

  // Jitter history for sparkline
  final List<double> _jitterHistory = List.generate(40, (index) => 0.2 + math.Random().nextDouble() * 0.6);

  // Hex stream values for Avalanche tunneling
  String _avalancheHexValue = 'A9C8D4F0E132';

  @override
  void initState() {
    super.initState();
    _startSimulationTimers();
  }

  @override
  void dispose() {
    _fluctuateTimer.cancel();
    _rotationTimer.cancel();
    super.dispose();
  }

  void _startSimulationTimers() {
    // Fast fluctuation timer (every 1 second)
    _fluctuateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        final r = math.Random();
        _entropyReservoirVal = 99.8 + r.nextDouble() * 0.19;
        _spectrumCoherenceVal = 97.5 + r.nextDouble() * 2.4;
        _matrixLoadVal = 25.0 + r.nextDouble() * 20.0;
        if (r.nextDouble() > 0.8) {
          _secureTunnelsCount = 12 + r.nextInt(5);
        }

        // Drop oldest jitter point and add another
        _jitterHistory.removeAt(0);
        _jitterHistory.add(0.15 + r.nextDouble() * 0.7);

        // Generate dynamic avalanche hex
        const chars = '0123456789ABCDEF';
        _avalancheHexValue = List.generate(12, (_) => chars[r.nextInt(16)]).join();
      });
    });

    // Count down timer for reseed cycle
    _rotationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_reseedSecondsRemaining > 1) {
          _reseedSecondsRemaining--;
        } else {
          _triggerSecuredReseeding();
        }
      });
    });
  }

  void _triggerSecuredReseeding() {
    if (_isReseeding) return;
    setState(() {
      _isReseeding = true;
    });

    widget.onSecurityLog(
      'Sovereign rotating reseed triggered',
      'info',
      'Infusing kT/C electronic noise and kinetic offsets into general zeta zero matrix.',
    );

    Future.delayed(const Duration(milliseconds: 1600), () {
      if (!mounted) return;
      setState(() {
        _isReseeding = false;
        _reseedSecondsRemaining = 45;
        _kineticBytes = 0; // reset harvesting byte
      });
      widget.onSecurityLog(
        'Reservoir entropy pool reseeded',
        'success',
        'Status: SATURATED. Key space fresh parameters rotation fully completed.',
      );
    });
  }

  void _handleKineticDrag(DragUpdateDetails details) {
    setState(() {
      _kineticBytes += 2;
      _kineticRecording = true;
    });

    if (_kineticBytes % 30 == 0) {
      widget.onSecurityLog(
        'Gathered physical kinetic offset parameters',
        'info',
        'Offset: Dx: ${details.delta.dx.toStringAsFixed(3)}, Dy: ${details.delta.dy.toStringAsFixed(3)}',
      );
    }
  }

  void _handleKineticDragEnd(DragEndDetails details) {
    setState(() {
      _kineticRecording = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 4 Grid Metric Cards
          LayoutBuilder(
            builder: (context, constraints) {
              final crossCount = constraints.maxWidth > 600 ? 4 : 2;
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossCount,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.4,
                children: [
                  _buildMetricCard(
                    title: translate('entropy_reservoir', widget.locale),
                    value: '${_entropyReservoirVal.toStringAsFixed(6)} %',
                    subtext: translate('sovereign_offline', widget.locale),
                    icon: Icons.grain,
                    color: const Color(0xFF06B6D4),
                  ),
                  _buildMetricCard(
                    title: translate('spectrum_coherence', widget.locale),
                    value: '${_spectrumCoherenceVal.toStringAsFixed(2)} %',
                    subtext: translate('critical_zeta', widget.locale),
                    icon: Icons.waves,
                    color: const Color(0xFFA855F7),
                  ),
                  _buildMetricCard(
                    title: translate('matrix_load', widget.locale),
                    value: '${_matrixLoadVal.toStringAsFixed(2)} %',
                    subtext: translate('stream_cycle', widget.locale),
                    icon: Icons.compress,
                    color: const Color(0xFFEC4899),
                  ),
                  _buildMetricCard(
                    title: translate('secure_tunnels', widget.locale),
                    value: '${_secureTunnelsCount}',
                    subtext: translate('isolated_capsules', widget.locale),
                    icon: Icons.security,
                    color: const Color(0xFF10B981),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),

          // Harvester Module Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF111827),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            translate('hardware_harvester_title', widget.locale),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            translate('hardware_harvester_desc', widget.locale),
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            translate('auto_rotation_cycle', widget.locale),
                            style: const TextStyle(fontSize: 8, color: Colors.grey, fontFamily: 'monospace'),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            translateFormat(
                              'seconds_remaining',
                              widget.locale,
                              {'seconds': _reseedSecondsRemaining.toString()},
                            ),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF06B6D4),
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
                const Divider(height: 24, color: Colors.white12),

                // Manual reseed button
                ElevatedButton.icon(
                  onPressed: _isReseeding ? null : _triggerSecuredReseeding,
                  icon: _isReseeding
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                        )
                      : const Icon(Icons.refresh, size: 14),
                  label: Text(
                    translate('rotate_seed', widget.locale),
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF06B6D4),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),

                // Oscilloscopes row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // CPU Jitter Sparkline Left Side
                    Expanded(
                      flex: 4,
                      child: Container(
                        height: 100,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.04)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              translate('jitter_oscillator', widget.locale),
                              style: const TextStyle(color: Colors.grey, fontSize: 9, fontFamily: 'monospace'),
                            ),
                            const Expanded(child: SizedBox(height: 8)),
                            SizedBox(
                              height: 50,
                              width: double.infinity,
                              child: CustomPaint(
                                painter: SparklinePainter(_jitterHistory),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Thermal / Avalanche Right Side
                    Expanded(
                      flex: 5,
                      child: Column(
                        children: [
                          // kT/C Node
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black12,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withOpacity(0.04)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      translate('thermal_node', widget.locale),
                                      style: const TextStyle(color: Colors.grey, fontSize: 8, fontFamily: 'monospace'),
                                    ),
                                    const Text('+34.2°C ambient', style: TextStyle(color: Colors.amber, fontSize: 8, fontFamily: 'monospace')),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: const LinearProgressIndicator(
                                    value: 0.65,
                                    backgroundColor: Colors.white10,
                                    color: Colors.amber,
                                    minHeight: 4,
                                  ),
                                )
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Avalanche Tunneling
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black12,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withOpacity(0.04)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  translate('avalanche_tunneling', widget.locale),
                                  style: const TextStyle(color: Colors.purpleAccent, fontSize: 8, fontFamily: 'monospace'),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _avalancheHexValue,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontFamily: 'monospace',
                                        color: Colors.greenAccent,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                    const Icon(Icons.flash_on, size: 10, color: Colors.greenAccent),
                                  ],
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 16),

                // Kinetic user seed toucher
                GestureDetector(
                  onPanUpdate: _handleKineticDrag,
                  onPanEnd: _handleKineticDragEnd,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _kineticRecording
                            ? const Color(0xFF06B6D4)
                            : Colors.white12,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _kineticRecording ? Icons.radio_button_checked : Icons.gesture,
                              size: 16,
                              color: _kineticRecording ? Colors.redAccent : Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              translate('kinetic_harvester', widget.locale),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _kineticRecording
                              ? translate('kinetic_recording', widget.locale)
                              : translate('kinetic_hover', widget.locale),
                          style: TextStyle(
                            fontSize: 9,
                            color: _kineticRecording ? Colors.redAccent : Colors.grey,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black38,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white.withOpacity(0.04)),
                          ),
                          child: Text(
                            translateFormat(
                              'kinetic_bytes',
                              widget.locale,
                              {'bytes': _kineticBytes.toString()},
                            ),
                            style: const TextStyle(
                              fontSize: 18,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF06B6D4),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtext,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.grey),
                overflow: TextOverflow.ellipsis,
              ),
              Icon(icon, size: 12, color: color),
            ],
          ),
          Text(
            value,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color, fontFamily: 'monospace'),
          ),
          Text(
            subtext,
            style: const TextStyle(fontSize: 8, color: Colors.white30),
          )
        ],
      ),
    );
  }
}

class SparklinePainter extends CustomPainter {
  final List<double> values;

  SparklinePainter(this.values);

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final paint = Paint()
      ..color = const Color(0xFF06B6D4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final path = Path();
    final double stepX = size.width / (values.length - 1);

    for (int i = 0; i < values.length; i++) {
      final x = i * stepX;
      final y = size.height - (values[i] * size.height);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    // Glowing subtle shadow fill
    final shadowPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [const Color(0xFF06B6D4).withOpacity(0.15), Colors.transparent],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final shadowPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(shadowPath, shadowPaint);
  }

  @override
  bool shouldRepaint(covariant SparklinePainter oldDelegate) {
    return oldDelegate.values != values;
  }
}
