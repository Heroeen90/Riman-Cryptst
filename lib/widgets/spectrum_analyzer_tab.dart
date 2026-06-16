import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../utils/translations.dart';

class SpectrumAnalyzerWidget extends StatefulWidget {
  final String locale;
  final Function(String message, String severity, String details) onSecurityLog;

  const SpectrumAnalyzerWidget({
    Key? key,
    required this.locale,
    required this.onSecurityLog,
  }) : super(key: key);

  @override
  State<SpectrumAnalyzerWidget> createState() => _SpectrumAnalyzerWidgetState();
}

class _SpectrumAnalyzerWidgetState extends State<SpectrumAnalyzerWidget> {
  late Timer _fluctuationTimer;
  late Timer _angleTimer;

  // Slider tuning parameters
  double _amplitude = 30.0;
  double _frequency = 2.0;

  double _animationPhase = 0.0;
  double _activeVarianceOffset = 0.042;

  // First 10 non-trivial zeros lying on critical line Re(s)=1/2
  final List<Map<String, dynamic>> _zeros = [
    {'id': 1, 're': 0.5, 'im': 14.134725, 'offset': 1.2},
    {'id': 2, 're': 0.5, 'im': 21.022040, 'offset': 2.4},
    {'id': 3, 're': 0.5, 'im': 25.010858, 'offset': 1.8},
    {'id': 4, 're': 0.5, 'im': 30.424876, 'offset': 3.1},
    {'id': 5, 're': 0.5, 'im': 32.935062, 'offset': 0.9},
    {'id': 6, 're': 0.5, 'im': 37.586178, 'offset': 4.2},
    {'id': 7, 're': 0.5, 'im': 40.918719, 'offset': 2.1},
    {'id': 8, 're': 0.5, 'im': 43.327073, 'offset': 1.5},
    {'id': 9, 're': 0.5, 'im': 48.005151, 'offset': 3.5},
    {'id': 10, 're': 0.5, 'im': 49.773832, 'offset': 0.6},
  ];

  @override
  void initState() {
    super.initState();
    _startWaveAnimations();
  }

  @override
  void dispose() {
    _fluctuationTimer.cancel();
    _angleTimer.cancel();
    super.dispose();
  }

  void _startWaveAnimations() {
    _fluctuationTimer = Timer.periodic(const Duration(milliseconds: 800), (timer) {
      if (!mounted) return;
      setState(() {
        _activeVarianceOffset = math.Random().nextDouble() * 0.05;
      });
    });

    _angleTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (!mounted) return;
      setState(() {
        _animationPhase += 0.08;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool useDualColumns = screenWidth > 800;

    Widget buildWaveProjectionCard() {
      return Container(
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      translate('spectrum_analyzer_title', widget.locale),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      translate('quantum_field_matrix', widget.locale),
                      style: const TextStyle(fontSize: 8, color: Colors.grey, fontFamily: 'monospace'),
                    )
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.info_outline, size: 14, color: Colors.grey),
                  onPressed: () {
                    widget.onSecurityLog(
                      'Analyzing spectral wave energy parameters',
                      'info',
                      'Current Amp: $_amplitude, Freq: $_frequency. Wave oscillation verified.',
                    );
                  },
                )
              ],
            ),
            const Divider(height: 16, color: Colors.white12),

            // SINE WAVE CANVAS
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.04)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CustomPaint(
                  painter: RiemannSpectrumWavePainter(
                    phase: _animationPhase,
                    amplitude: _amplitude,
                    frequency: _frequency,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Controls sliders
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${translate('time_axes', widget.locale)}: ${_amplitude.toInt()}',
                        style: const TextStyle(color: Colors.grey, fontSize: 8),
                      ),
                      Slider(
                        value: _amplitude,
                        min: 10,
                        max: 60,
                        activeColor: const Color(0xFF06B6D4),
                        onChanged: (val) {
                          setState(() {
                            _amplitude = val;
                          });
                        },
                      )
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${translate('frequency_axes', widget.locale)}: ${_frequency.toStringAsFixed(1)}',
                        style: const TextStyle(color: Colors.grey, fontSize: 8),
                      ),
                      Slider(
                        value: _frequency,
                        min: 0.5,
                        max: 5.0,
                        activeColor: const Color(0xFFA855F7),
                        onChanged: (val) {
                          setState(() {
                            _frequency = val;
                          });
                        },
                      )
                    ],
                  ),
                )
              ],
            )
          ],
        ),
      );
    }

    Widget buildZerosTableCard() {
      return Container(
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
                const Text(
                  'COMPUTED NON-TRIVIAL ZERO ROOTS',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white),
                ),
                Text(
                  'COUNT: ${_zeros.length}',
                  style: const TextStyle(color: Color(0xFFA855F7), fontSize: 9, fontFamily: 'monospace', fontWeight: FontWeight.bold),
                )
              ],
            ),
            const Divider(height: 16, color: Colors.white12),

            // Simple responsive table/list view representation
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 4, // first 4 coordinates for clean bento aesthetic on mobile screens
              itemBuilder: (context, idx) {
                final zero = _zeros[idx];
                final currentVariance = (zero['offset'] as double) + _activeVarianceOffset;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                  decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '# ${zero['id'].toString().padLeft(2, '0')}',
                        style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                      ),
                      Text(
                        's = 0.5 + i${zero['im'].toString()}',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontFamily: 'monospace'),
                      ),
                      Row(
                        children: [
                          Text(
                            currentVariance.toStringAsFixed(4),
                            style: const TextStyle(color: Color(0xFF06B6D4), fontSize: 9, fontFamily: 'monospace'),
                          ),
                          const SizedBox(width: 6),
                          SizedBox(
                            width: 32,
                            height: 3,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: math.min(1.0, currentVariance / 5.0),
                                backgroundColor: Colors.white10,
                                color: const Color(0xFF06B6D4),
                              ),
                            ),
                          )
                        ],
                      )
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      );
    }

    Widget buildCoherenceStatsCard() {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'COHERENCE COMPLEX PLANE MATRIX',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              translate('zeta_zeros_desc', widget.locale),
              style: const TextStyle(color: Colors.white70, fontSize: 10, height: 1.4),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ZETA PLANE FUNCTION', style: TextStyle(color: Colors.grey, fontSize: 7, fontFamily: 'monospace')),
                  const SizedBox(height: 4),
                  const Text('ζ(s) = ∑ (1 / n^s)', style: TextStyle(color: Color(0xFFA855F7), fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'monospace'))
                ],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('COORDINATE ALIGNMENT', style: TextStyle(color: Colors.grey, fontSize: 7, fontFamily: 'monospace')),
                  const SizedBox(height: 4),
                  const Text('Re(s) = 0.5000000000...', style: TextStyle(color: Color(0xFF06B6D4), fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'monospace'))
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('ZETA SYNC STATUS', style: TextStyle(fontSize: 8, color: Colors.grey, fontFamily: 'monospace')),
                Text('100% SECURE', style: TextStyle(fontSize: 9, color: Color(0xFF34D399), fontWeight: FontWeight.bold, fontFamily: 'monospace')),
              ],
            )
          ],
        ),
      );
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          useDualColumns
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: buildWaveProjectionCard()),
                    const SizedBox(width: 16),
                    Expanded(flex: 2, child: Column(children: [buildZerosTableCard(), const SizedBox(height: 16), buildCoherenceStatsCard()])),
                  ],
                )
              : Column(
                  children: [
                    buildWaveProjectionCard(),
                    const SizedBox(height: 16),
                    buildZerosTableCard(),
                    const SizedBox(height: 16),
                    buildCoherenceStatsCard()
                  ],
                ),
        ],
      ),
    );
  }
}

class RiemannSpectrumWavePainter extends CustomPainter {
  final double phase;
  final double amplitude;
  final double frequency;

  RiemannSpectrumWavePainter({
    required this.phase,
    required this.amplitude,
    required this.frequency,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawSineWave(canvas, size, const Color(0xFF06B6D4).withOpacity(0.55), phase, amplitude, frequency);
    _drawSineWave(canvas, size, const Color(0xFFA855F7).withOpacity(0.40), phase * 0.7 + 1.2, amplitude * 0.8, frequency * 1.3);
  }

  void _drawSineWave(Canvas canvas, Size size, Color color, double localPhase, double localAmp, double localFreq) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final path = Path();
    final double midY = size.height / 2;

    for (double x = 0; x <= size.width; x++) {
      final double angle = (x / size.width) * 2 * math.pi * localFreq + localPhase;
      final double y = midY + math.sin(angle) * (localAmp / 60.0) * (size.height / 2.5);

      if (x == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant RiemannSpectrumWavePainter oldDelegate) {
    return oldDelegate.phase != phase ||
        oldDelegate.amplitude != amplitude ||
        oldDelegate.frequency != frequency;
  }
}
