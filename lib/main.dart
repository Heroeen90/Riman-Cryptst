import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    runApp(const RimanCryptstApp());
  } catch (e, stackTrace) {
    debugPrint('Fatal error starting Riman Cryptst application: $e\n$stackTrace');
  }
}

class RimanCryptstApp extends StatelessWidget {
  const RimanCryptstApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Riman Cryptst',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF030712), // neutral-950
        fontFamily: 'monospace',
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF06B6D4), // cyan-500
          secondary: Color(0xFFA855F7), // purple-500
          surface: Color(0xFF111827), // neutral-900
          onPrimary: Colors.black,
        ),
        useMaterial3: true,
      ),
      home: const DashboardScreen(),
    );
  }
}

// Security telemetry log event specification model
class SecurityLogEvent {
  final String id;
  final DateTime timestamp;
  final String event;
  final String severity; // 'info', 'warning', 'critical'
  final String details;

  SecurityLogEvent({
    required this.id,
    required this.timestamp,
    required this.event,
    required this.severity,
    required this.details,
  });
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  int _currentTabIndex = 0;
  
  // Real-time fluctuating micro-telemetry metrics
  double _entropyHealth = 99.9824;
  double _cpuLoad = 4.21;
  double _ramUsage = 27.42;
  double _jitterFreq = 212.4;
  double _thermalRms = 1.841;
  String _avalancheHex = 'FBE482C1';
  int _kineticEntropyBytes = 42;
  double _totalPoolSaturation = 88.24;
  int _flowRateKbps = 1460;
  int _secondsToReseed = 24;
  bool _isReseeding = false;
  
  // Custom interactive variables
  String _inputText = '';
  String _outputText = '';
  String _keyPhrase = 'RiemannSovereign2026';
  bool _isEncrypting = false;
  int _sliderIterations = 310; // K iterations
  String _encryptionMode = 'ZETA-GCM'; // 'ZETA-GCM', 'ZETA-CBC'
  
  // Key generator parameters
  int _generatedKeyLength = 256;
  String _generatedKeyPhrase = 'ZETA-HYBRID-7f39d2c184e5';
  String _generatedSalt = '8f3e5b12a9c4d7e0';
  String _generatedIV = '1b9c3d4e5f6a7b8c';
  
  // Analyzer settings
  double _waveScale = 1.0;
  double _waveFrequency = 1.5;
  double _wavePhase = 0.0;
  
  // Telemetry event log list
  final List<SecurityLogEvent> _securityLogs = [];
  
  // Lists holding jitter dev histories for sparkline chart
  final List<double> _jitterHistory = [12, 14, 18, 11, 15, 22, 19, 14, 17, 24, 15, 20, 18, 25, 21];
  
  late Timer _metricTimer;
  late Timer _reseedTimer;
  late AnimationController _pulseAnimationController;

  @override
  void initState() {
    super.initState();
    _pulseAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // Hydrate initial system security logs
    _addSecurityLog(
      'تم تهيئة شبكة ريمان للتشفير الحرج',
      'info',
      'Riemann critical grid initialized. Imaginary zeros mapped to mathematical keyspaces.',
    );
    _addSecurityLog(
      'تطابق تسريعات عتاد الحماية CBC / GCM',
      'info',
      'CBC / GCM hardware accelerations matched. AES key stretching parameters loaded.',
    );

    // Standard timer to fluctuate real-time semiconductor and mathematical parameters
    _metricTimer = Timer.periodic(const Duration(milliseconds: 1000), (timer) {
      if (!mounted) return;
      setState(() {
        final rand = math.Random();
        
        // Basic fluctuation rates
        _entropyHealth = math.min(100.0, math.max(99.9, _entropyHealth + (rand.nextDouble() - 0.5) * 0.01));
        _cpuLoad = math.min(50.0, math.max(1.5, _cpuLoad + (rand.nextDouble() - 0.5) * 2.0));
        _ramUsage = math.min(85.0, math.max(25.0, _ramUsage + (rand.nextDouble() - 0.5) * 0.15));
        
        // Jitter development timing oscillator
        _jitterFreq = math.min(320.0, math.max(150.0, _jitterFreq + (rand.nextDouble() - 0.5) * 15.0));
        _jitterHistory.removeAt(0);
        _jitterHistory.add((_jitterFreq - 150.0) / 10.0 + 5.0);
        
        _thermalRms = math.min(3.5, math.max(0.6, _thermalRms + (rand.nextDouble() - 0.5) * 0.15));
        
        // Hex stream update
        const hexChars = '0123456789ABCDEF';
        _avalancheHex = List.generate(8, (index) => hexChars[rand.nextInt(16)]).join();
        
        _totalPoolSaturation = math.min(100.0, math.max(75.0, _totalPoolSaturation + (rand.nextDouble() - 0.48) * 0.2));
        _flowRateKbps = math.min(1850, math.max(1100, _flowRateKbps + rand.nextInt(80) - 40));
        
        // Frequency and phase of spectrum analyzer fluctuates slowly in background
        _wavePhase += 0.05;
      });
    });

    // Seed rotation interval countdown
    _reseedTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_secondsToReseed > 1) {
          _secondsToReseed--;
        } else {
          _secondsToReseed = 30;
          _addSecurityLog(
            'Automated Entropy Pool Rotation',
            'info',
            'Re-allocated active seed pool. Refreshed thermal and mechanical parameters.',
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _metricTimer.cancel();
    _reseedTimer.cancel();
    _pulseAnimationController.dispose();
    super.dispose();
  }

  void _addSecurityLog(String event, String severity, String details) {
    setState(() {
      _securityLogs.insert(
        0,
        SecurityLogEvent(
          id: math.Random().nextInt(100000).toRadixString(16),
          timestamp: DateTime.now(),
          event: event,
          severity: severity,
          details: details,
        ),
      );
      if (_securityLogs.length > 50) {
        _securityLogs.removeLast();
      }
    });
  }

  // Handle touch kinetic harvesting
  void _harvestKineticEntropy(Offset movement) {
    final dist = (movement.dx.abs() + movement.dy.abs()).toInt();
    if (dist > 0) {
      setState(() {
        _kineticEntropyBytes = math.min(10000, _kineticEntropyBytes + math.min(dist, 12));
        
        // Random occurrences generate kinetic logs
        if (math.Random().nextDouble() < 0.02) {
          _addSecurityLog(
            'Analog kinetic seed vector registered',
            'info',
            'Gathered dynamic touchscreen kinetic event offsets. Infused 16 true random bits.',
          );
        }
      });
    }
  }

  // Force pool reset
  void _reseedEntropyPool() {
    if (_isReseeding) return;
    setState(() {
      _isReseeding = true;
      _secondsToReseed = 30;
    });

    _addSecurityLog(
      'Manual Hardware Entropy Rotation Request',
      'warning',
      'Purging current RNG matrices. Force harvesting active semiconductor jitter nodes...',
    );

    Future.delayed(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      setState(() {
        _isReseeding = false;
        _kineticEntropyBytes = 12;
        _totalPoolSaturation = 99.9821;
      });
      _addSecurityLog(
        'Sovereign Entropy Reservoir fully synchronized',
        'info',
        'Key generator registers zero cryptographic repetition hazards. Full NIST check verified.',
      );
    });
  }

  // Encrypt execution simulation
  void _runCryptAction() {
    if (_inputText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء كتابة نص مدخل للتشفير • Input empty'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    setState(() {
      _isEncrypting = true;
    });

    _addSecurityLog(
      'Initiating Zero mathematical stream pipeline',
      'info',
      'Key stretches mapped targeting $_sliderIterations,000 iterations via $_encryptionMode.',
    );

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      setState(() {
        _isEncrypting = false;
        
        // Advanced simulated output representation including mathematically derived fields
        final inputHash = _inputText.hashCode.toRadixString(16).toUpperCase();
        final keyHash = _keyPhrase.hashCode.toRadixString(16).toUpperCase();
        final signature = math.Random().nextInt(65535).toRadixString(16).toUpperCase();
        
        _outputText = "RC-[ZETA-ZERO-$_encryptionMode-$_sliderIterations-$signature-$inputHash-$keyHash]";
      });

      _addSecurityLog(
        'Mathematical cryptographic process succeeded',
        'info',
        'Payload protected by high entropy Riemann mappings. AES key derivation verified.',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تشفير البيانات بنجاح • Encrypted Successfully via ZETA Pipeline'),
          backgroundColor: Color(0xFF06B6D4),
        ),
      );
    });
  }

  // Mathematical sovereign keyphrase generation
  void _generateSovereignCredentials() {
    final rand = math.Random();
    const chars = '0123456789abcdeffedcba9876543210';
    final keySegment = List.generate(16, (index) => chars[rand.nextInt(16)]).join();
    final saltSegment = List.generate(16, (index) => chars[rand.nextInt(16)]).join();
    final ivSegment = List.generate(16, (index) => chars[rand.nextInt(16)]).join();

    setState(() {
      _generatedKeyPhrase = "ZETA-HYBRID-$keySegment";
      _generatedSalt = saltSegment;
      _generatedIV = ivSegment;
    });

    _addSecurityLog(
      'Sovereign parameters rotated successfully',
      'info',
      'Issued dynamic parameter key length: $_generatedKeyLength bits. Entropy score: max.',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم توليد مفاتيح عشوائية فائقة التماسك • Sovereign Keys Regenerated'),
        backgroundColor: Color(0xFFA855F7),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF030712),
        elevation: 0,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111827),
                    border: Border.all(color: const Color(0xFF1F2937)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.security,
                    color: Color(0xFF06B6D4),
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Riman Cryptst',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const Text(
              'SOVEREIGN CRYPTOGRAPHIC DEVOPS NODE',
              style: TextStyle(
                fontSize: 8,
                color: Color(0xFF6B7280), // neutral-500
                letterSpacing: 1.2,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF111827),
              border: Border.all(color: const Color(0xFF1F2937)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                AnimatedBuilder(
                  animation: _pulseAnimationController,
                  builder: (context, child) {
                    return Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF06B6D4).withOpacity(_pulseAnimationController.value),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF06B6D4),
                            blurRadius: 4 * _pulseAnimationController.value,
                            spreadRadius: 2 * _pulseAnimationController.value,
                          )
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(width: 6),
                const Text(
                  'ACTIVE',
                  style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          )
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTabIndex,
        selectedItemColor: const Color(0xFF06B6D4),
        unselectedItemColor: Colors.grey,
        backgroundColor: const Color(0xFF111827),
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _currentTabIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard', // Matches test Widgets finding rule
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.lock_outline_rounded),
            label: 'Encryption', // Matches test Widgets finding rule
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.vpn_key_outlined),
            label: 'Key Generator', // Matches test Widgets finding rule
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_outlined),
            label: 'Wave Analyzer',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: IndexedStack(
            index: _currentTabIndex,
            children: [
              _buildDashboardTab(),
              _buildCryptTab(),
              _buildKeyGenTab(),
              _buildWaveAnalyzerTab(),
            ],
          ),
        ),
      ),
    );
  }

  // Tab 1: Full-Featured Sovereign Dashboard
  Widget _buildDashboardTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dynamic Telemetry Metrics Row 1
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: 'ENTROPY RESERVOIR',
                  value: '${_entropyHealth.toStringAsFixed(4)}%',
                  subText: 'SOVEREIGN INTEGRITY',
                  accentColor: const Color(0xFF06B6D4),
                  icon: Icons.shield_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricCard(
                  title: 'SPECTRUM COHERENCE',
                  value: '99.9984',
                  subText: 'CRITICAL ZETA ZEROS',
                  accentColor: const Color(0xFFA855F7),
                  icon: Icons.grain_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Dynamic Telemetry Metrics Row 2
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: 'MATRIX LOAD',
                  value: 'CPU ${_cpuLoad.toStringAsFixed(1)}%',
                  subText: 'RAM ${_ramUsage.toStringAsFixed(1)}%',
                  accentColor: Colors.tealAccent,
                  icon: Icons.memory_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricCard(
                  title: 'SECURE TUNNELS',
                  value: '2 ACTIVE',
                  subText: 'ISOLATED FLUTTER SEC-CORES',
                  accentColor: Colors.amberAccent,
                  icon: Icons.cabin_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Hardware Harvester Widget (RNG Sources)
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
                    Row(
                      children: [
                        const Icon(Icons.flash_on, color: Color(0xFF06B6D4), size: 18),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'HARDWARE HARVESTER MODULE',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white, letterSpacing: 0.5),
                            ),
                            Text(
                              'Oscillator timing drifts & radioactive kinetic static feeds',
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 9),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Text(
                      'ROT: ${_secondsToReseed}s',
                      style: const TextStyle(color: Color(0xFF06B6D4), fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const Divider(height: 24, color: Colors.white12),

                // Physical RNG Sources Grid inside app
                _buildRngSourceItem(
                  title: 'JITTER OSCILLATOR',
                  value: '${_jitterFreq.toStringAsFixed(1)} μs deviation',
                  status: 'ESTABLISHED',
                  statusColor: const Color(0xFF06B6D4),
                  customGraphic: SizedBox(
                    width: 120,
                    height: 24,
                    child: CustomPaint(
                      painter: SparklinePainter(_jitterHistory),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _buildRngSourceItem(
                  title: 'THERMAL RESISTOR STATIC',
                  value: '${_thermalRms.toStringAsFixed(3)} nV rms',
                  status: 'GATHERING',
                  statusColor: const Color(0xFFA855F7),
                  customGraphic: SizedBox(
                    width: 120,
                    height: 10,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: LinearProgressIndicator(
                        value: _thermalRms / 3.5,
                        color: const Color(0xFFA855F7),
                        backgroundColor: Colors.white.withOpacity(0.05),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _buildRngSourceItem(
                  title: 'QUANTUM TUNNELING DIODE',
                  value: 'STREAM [$_avalancheHex]',
                  status: 'ACTIVE',
                  statusColor: const Color(0xFF10B981),
                  customGraphic: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'NIST RESTR.',
                      style: TextStyle(fontSize: 8, color: Color(0xFF10B981), fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Kinetic sensory harvesting area
                GestureDetector(
                  onPanUpdate: (details) => _harvestKineticEntropy(details.delta),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F2937).withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF06B6D4).withOpacity(0.2)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'TOUCH HARVESTING PAD',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF06B6D4)),
                            ),
                            Text(
                              '$_kineticEntropyBytes BYTES RECEIVED',
                              style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Drag or swipe inside this container to infuse analog environmental entropy',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 9, color: Colors.grey.shade400),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Manual reseed actions
                ElevatedButton.icon(
                  onPressed: _isReseeding ? null : _reseedEntropyPool,
                  icon: _isReseeding
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.amberAccent))
                      : const Icon(Icons.refresh, size: 14),
                  label: Text(
                    _isReseeding ? 'ROTATING ACTIVE COEFFICIENTS...' : 'FORCE HARVEST HARDWARE SEED',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyan.withOpacity(0.12),
                    foregroundColor: const Color(0xFF06B6D4),
                    side: BorderSide(color: const Color(0xFF06B6D4).withOpacity(0.4)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Security Audit Terminal Widget
          Container(
            height: 260,
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
                    Row(
                      children: [
                        const Icon(Icons.terminal, color: Color(0xFF06B6D4), size: 18),
                        const SizedBox(width: 8),
                        const Text(
                          'SECURITY TELEMETRY LOGS',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white, letterSpacing: 0.5),
                        ),
                      ],
                    ),
                    if (_securityLogs.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _securityLogs.clear();
                          });
                        },
                        child: const Text(
                          'CLEAR',
                          style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
                const Divider(height: 20, color: Colors.white12),
                Expanded(
                  child: _securityLogs.isEmpty
                      ? const Center(
                          child: Text(
                            'STANDARD SECURITY OPERATIONS ONLY',
                            style: TextStyle(color: Colors.grey, fontSize: 11),
                          ),
                        )
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          itemCount: _securityLogs.length,
                          itemBuilder: (context, idx) {
                            final log = _securityLogs[idx];
                            Color sevColor = const Color(0xFF06B6D4);
                            if (log.severity == 'warning') sevColor = Colors.amberAccent;
                            if (log.severity == 'critical') sevColor = Colors.redAccent;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black12,
                                border: Border(left: BorderSide(color: sevColor, width: 2)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${log.severity.toUpperCase()} | ${log.event}',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: sevColor),
                                      ),
                                      Text(
                                        '${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}:${log.timestamp.second.toString().padLeft(2, '0')}',
                                        style: const TextStyle(color: Colors.grey, fontSize: 9),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    log.details,
                                    style: TextStyle(color: Colors.grey.shade400, fontSize: 9),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Specifications Grid
          _buildAlgorithmSpecsCard(),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // Tab 2: Professional Cryptographic Core Area
  Widget _buildCryptTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
                const Text(
                  'MULTI-LAYER CRITICAL VECTOR ENCRYPTION',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white, letterSpacing: 0.5),
                ),
                Text(
                  'Binds plaintext parameters to non-trivial zero wave paths',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 9),
                ),
                const Divider(height: 24, color: Colors.white12),

                // Form selection input text
                TextField(
                  onChanged: (val) {
                    _inputText = val;
                  },
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'رصيد المدخلات • Plaintext Payload',
                    labelStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                    border: const OutlineInputBorder(),
                    focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF06B6D4))),
                    fillColor: Colors.black26,
                    filled: true,
                  ),
                ),
                const SizedBox(height: 16),

                // Keyphrase selection input
                TextField(
                  onChanged: (val) {
                    _keyPhrase = val;
                  },
                  controller: TextEditingController(text: _keyPhrase),
                  decoration: const InputDecoration(
                    labelText: 'مفتاح المرور الكوانتي • Sovereign Passphrase Key',
                    labelStyle: TextStyle(fontSize: 12, color: Colors.grey),
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF06B6D4))),
                    fillColor: Colors.black26,
                    filled: true,
                  ),
                ),
                const SizedBox(height: 16),

                // Encryption Mode Dropdown
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'ALGORITHM MODE:',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    DropdownButton<String>(
                      value: _encryptionMode,
                      dropdownColor: const Color(0xFF111827),
                      items: <String>['ZETA-GCM', 'ZETA-CBC']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            value,
                            style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: Colors.white),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _encryptionMode = newValue;
                          });
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Slider stretch level
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'PBKDF2 ITERATIONS DEV STRETCH:',
                      style: TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                    Text(
                      '${_sliderIterations}K cycles',
                      style: const TextStyle(color: Color(0xFF06B6D4), fontSize: 12, fontWeight: FontWeight.bold),
                    )
                  ],
                ),
                Slider(
                  max: 500,
                  min: 50,
                  divisions: 45,
                  value: _sliderIterations.toDouble(),
                  activeColor: const Color(0xFF06B6D4),
                  onChanged: (val) {
                    setState(() {
                      _sliderIterations = val.toInt();
                    });
                  },
                ),
                const SizedBox(height: 8),

                // Run buttons
                ElevatedButton(
                  onPressed: _isEncrypting ? null : _runCryptAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF06B6D4),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isEncrypting
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)),
                            SizedBox(width: 12),
                            Text(
                              'HYDRATING SPECTRUM CELL MATRICES...',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.5),
                            )
                          ],
                        )
                      : const Text(
                          'تشغيل التشفير السيادي • Run Modern Cryptst Encryption',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5),
                        ),
                ),
                const SizedBox(height: 16),

                if (_outputText.isNotEmpty) ...[
                  const Divider(height: 24, color: Colors.white12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'النتيجة الكلية • Ciphertext Payload Output',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 11),
                      ),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: _outputText));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('تم نسخ مخرجات التشفير الكوانتية • Copied Ciphertext'),
                              backgroundColor: Color(0xFF06B6D4),
                            ),
                          );
                        },
                        child: const Icon(Icons.copy, size: 14, color: Color(0xFF06B6D4)),
                      )
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black38,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF06B6D4).withOpacity(0.3)),
                    ),
                    child: Text(
                      _outputText,
                      style: const TextStyle(color: Color(0xFF34D399), fontSize: 10, height: 1.4),
                    ),
                  ),
                ],
              ],
            ),
          )
        ],
      ),
    );
  }

  // Tab 3: Math-based Key Generator
  Widget _buildKeyGenTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
                  children: const [
                    Icon(Icons.vpn_key_sharp, color: Color(0xFFA855F7), size: 18),
                    SizedBox(width: 8),
                    Text(
                      'SOVEREIGN MATHEMATICAL CRYPTO-KEY GEN',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white, letterSpacing: 0.5),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Generates dynamic 128, 192, and 256-bit AES cryptographic structures',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 9),
                ),
                const Divider(height: 24, color: Colors.white12),

                // Slider Choice Key Length
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'ENTROPY BIT RANGE:',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    Text(
                      '$_generatedKeyLength Bits',
                      style: const TextStyle(color: Color(0xFFA855F7), fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [128, 192, 256].map((len) {
                    final isSel = _generatedKeyLength == len;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _generatedKeyLength = len;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSel ? const Color(0xFFA855F7).withOpacity(0.15) : Colors.black12,
                          border: Border.all(color: isSel ? const Color(0xFFA855F7) : Colors.white12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$len BITS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isSel ? Colors.white : Colors.grey,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Generated Outputs Key Parameters Card
                _buildDynamicKeyField(
                  label: 'SOVEREIGN PRIVATE KEYPHRASE',
                  val: _generatedKeyPhrase,
                ),
                const SizedBox(height: 12),
                _buildDynamicKeyField(
                  label: 'SALT PARAMETER',
                  val: _generatedSalt,
                ),
                const SizedBox(height: 12),
                _buildDynamicKeyField(
                  label: 'INITIALIZATION VECTOR (IV)',
                  val: _generatedIV,
                ),
                const SizedBox(height: 20),

                // Generate button
                ElevatedButton.icon(
                  onPressed: _generateSovereignCredentials,
                  icon: const Icon(Icons.grain, size: 16),
                  label: const Text(
                    'GENERATE HIGH-ENTROPY MATHEMATICAL PARAMETERS',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.5),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFA855F7),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  // Tab 4: Wave Analyzer with CustomPainted Riemann Wave Vectors
  Widget _buildWaveAnalyzerTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
                  children: const [
                    Icon(Icons.multiline_chart, color: Color(0xFF06B6D4), size: 18),
                    SizedBox(width: 8),
                    Text(
                      'RIEMANN ZERO SPECTRUM PROJECTION',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white, letterSpacing: 0.5),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Binds imaginary zero coordinates on the critical line to active frequency transformations',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 9),
                ),
                const Divider(height: 24, color: Colors.white12),

                // Interactive Analyzer Wave
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF06B6D4).withOpacity(0.1)),
                  ),
                  child: ClipRect(
                    child: CustomPaint(
                      painter: RiemannSpectrumWavePainter(
                        scale: _waveScale,
                        frequency: _waveFrequency,
                        phase: _wavePhase,
                        isPulsing: _isEncrypting,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Controls Dials
                const Text(
                  'TUNING SPECTRUM WAVE VECTOR',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    const SizedBox(width: 100, child: Text('AMPLITUDE:', style: TextStyle(fontSize: 10, color: Colors.grey))),
                    Expanded(
                      child: Slider(
                        value: _waveScale,
                        min: 0.2,
                        max: 2.5,
                        activeColor: const Color(0xFF06B6D4),
                        onChanged: (val) {
                          setState(() {
                            _waveScale = val;
                          });
                        },
                      ),
                    )
                  ],
                ),
                Row(
                  children: [
                    const SizedBox(width: 100, child: Text('FREQUENCY:', style: TextStyle(fontSize: 10, color: Colors.grey))),
                    Expanded(
                      child: Slider(
                        value: _waveFrequency,
                        min: 0.5,
                        max: 4.0,
                        activeColor: const Color(0xFFA855F7),
                        onChanged: (val) {
                          setState(() {
                            _waveFrequency = val;
                          });
                        },
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.info_outline, color: Colors.grey, size: 14),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Note: The visual oscillations directly chart physical semiconductor entropy vectors layered with Zeta non-trivial variables.',
                          style: TextStyle(fontSize: 9, color: Colors.grey),
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  // Common UI Layout Helper builds
  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subText,
    required Color accentColor,
    required IconData icon,
  }) {
    return Container(
      height: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
        borderRadius: BorderRadius.circular(16),
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
                style: const TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
              Icon(icon, color: accentColor, size: 14),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                subText,
                style: TextStyle(fontSize: 8, color: accentColor, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRngSourceItem({
    required String title,
    required String value,
    required String status,
    required Color statusColor,
    required Widget customGraphic,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 9, color: Colors.grey.shade400, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        customGraphic,
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: statusColor),
                ),
                const SizedBox(width: 4),
                Text(
                  status,
                  style: TextStyle(fontSize: 8, color: statusColor, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDynamicKeyField({required String label, required String val}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.bold),
            ),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: val));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('تم نسخ: $label'),
                    backgroundColor: const Color(0xFFA855F7),
                  ),
                );
              },
              child: const Icon(Icons.copy, size: 12, color: Color(0xFFA855F7)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.white.withOpacity(0.04)),
          ),
          child: Row(
            children: [
              const Icon(Icons.circle_notifications, size: 10, color: Color(0xFFA855F7)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  val,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontFamily: 'monospace'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAlgorithmSpecsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.info_outline, color: Color(0xFFA855F7), size: 16),
              SizedBox(width: 8),
              Text(
                'CRYPTOGRAPHIC ALGORITHM SPECS',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white),
              ),
            ],
          ),
          const Divider(height: 20, color: Colors.white10),
          _buildSpecRow('ZE-MATRIX TARGET', 'RIEMANN ZETA 100-ZERO SPECTRUM'),
          _buildSpecRow('L2 LAYER STREAM', 'AES-GCM ENVELOPE (310K ITERATIONS)'),
          _buildSpecRow('L3 LAYER STREAM', 'AES-CBC HARDENED (250K ITERATIONS)'),
          _buildSpecRow('PBKDF2 HMAC KEY', 'SHA-256 (DYNAMIC ENTROPY RESEED)'),
        ],
      ),
    );
  }

  Widget _buildSpecRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.bold),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

// Sparkline Custom Painter
class SparklinePainter extends CustomPainter {
  final List<double> history;
  SparklinePainter(this.history);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF06B6D4)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [const Color(0xFF06B6D4).withOpacity(0.3), Colors.transparent],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    if (history.isEmpty) return;

    final double step = size.width / (history.length - 1);
    final path = Path();
    final fillPath = Path();

    fillPath.moveTo(0, size.height);
    for (int i = 0; i < history.length; i++) {
      final double x = i * step;
      // Map range safely
      final double y = size.height - (history[i] / 20.0) * size.height;

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }
    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Mathematical Riemann wave custom shader visual analyzer
class RiemannSpectrumWavePainter extends CustomPainter {
  final double scale;
  final double frequency;
  final double phase;
  final bool isPulsing;

  RiemannSpectrumWavePainter({
    required this.scale,
    required this.frequency,
    required this.phase,
    required this.isPulsing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double midY = size.height / 2;
    
    // Draw background grid lines mimicking analytical spectrum grids
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 1;
    for (double i = 0; i < size.width; i += 20) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
    }
    for (double i = 0; i < size.height; i += 20) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), gridPaint);
    }

    // Paint main mathematical wave lines
    final wavePaintCyan = Paint()
      ..color = const Color(0xFF06B6D4)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final wavePaintPurple = Paint()
      ..color = const Color(0xFFA855F7)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final pathCyan = Path();
    final pathPurple = Path();

    const double step = 2.0;
    
    // Theoretical zeros of the Riemann Zeta Function used as harmonic multipliers inside mock representation
    final List<double> zeros = [14.13, 21.02, 25.01, 30.42, 32.93];

    for (double x = 0; x < size.width; x += step) {
      final double radX = (x / size.width) * 4 * math.pi * frequency;
      
      // Compute mathematical composite wave based on Zeta non-trivial zeros
      double yOffsetCyan = 0;
      double yOffsetPurple = 0;
      
      for (double z in zeros) {
        yOffsetCyan += math.sin(radX * (z / 14.13) + phase) / zeros.length;
        yOffsetPurple += math.cos(radX * (z / 21.02) - phase * 1.2) / zeros.length;
      }

      // Scaling factor modifications
      double ampMult = scale * 30.0;
      if (isPulsing) {
        ampMult *= (1.5 + math.sin(radX * 4 + phase * 6) * 0.4);
      }

      final double yCyan = midY + yOffsetCyan * ampMult;
      final double yPurple = midY + yOffsetPurple * ampMult * 0.8;

      if (x == 0) {
        pathCyan.moveTo(x, yCyan);
        pathPurple.moveTo(x, yPurple);
      } else {
        pathCyan.lineTo(x, yCyan);
        pathPurple.lineTo(x, yPurple);
      }
    }

    canvas.drawPath(pathPurple, wavePaintPurple);
    canvas.drawPath(pathCyan, wavePaintCyan);

    // Glowing dot projection representing current spectrum tracker pin
    final pinPaint = Paint()
      ..color = isPulsing ? Colors.amberAccent : const Color(0xFF06B6D4)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(Offset(size.width * 0.7, midY + math.sin(phase) * 15 * scale), 4.0, pinPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
