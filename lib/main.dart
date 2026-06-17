import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'utils/translations.dart';
import 'utils/vault_service.dart';
import 'widgets/sovereign_dashboard.dart';
import 'widgets/security_center.dart';
import 'widgets/smart_vaults_tab.dart';
import 'widgets/text_shield.dart';
import 'widgets/file_shield.dart';
import 'widgets/time_capsules.dart';
import 'widgets/key_generator.dart';
import 'widgets/spectrum_analyzer_tab.dart';
import 'widgets/flutter_exporter.dart';
import 'widgets/secure_notes.dart';
import 'widgets/secure_journal.dart';
import 'widgets/secure_gallery.dart';
import 'widgets/secure_media.dart';
import 'widgets/nexus_dashboard.dart';
import 'widgets/archive_dashboard.dart';
import 'widgets/forensics_dashboard.dart';
import 'widgets/sentinel_dashboard.dart';
import 'widgets/workspace_dashboard.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    runApp(const RimanCryptstApp());
  } catch (e, stackTrace) {
    debugPrint('Fatal error starting Riman Cryptst application: \$e\\n\$stackTrace');
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

class SecurityLogEvent {
  final String id;
  final DateTime timestamp;
  final String event;
  final String severity; // 'info', 'warning', 'critical', 'success'
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

class _DashboardScreenState extends State<DashboardScreen> {
  // Localization state
  String _locale = 'ar'; // default to Arabic for alignment

  // Splash Screen loading state
  bool _isLoaded = false;
  int _loadingProgress = 0;
  String _loadingStatus = '';

  // Tab State (0=Dashboard, 1=Text, 2=File, 3=Capsules, 4=Keygen, 5=Spectrum, 6=Exporter)
  int _currentTabIndex = 0;

  // Global Telemetry Logs list
  final List<SecurityLogEvent> _logs = [];
  final ScrollController _terminalScrollController = ScrollController();

  // Pin lock overlays
  String _pinValue = '';
  String _pinError = '';

  @override
  void initState() {
    super.initState();
    _startSplashScreenLoading();
    _seedInitialSecurityLogs();
    VaultService().addListener(_onVaultServiceUpdate);
  }

  @override
  void dispose() {
    _terminalScrollController.dispose();
    VaultService().removeListener(_onVaultServiceUpdate);
    super.dispose();
  }

  void _onVaultServiceUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  void _startSplashScreenLoading() {
    _loadingStatus = _locale == 'ar' ? 'تهيئة النظام الكمومي لـ Riman...' : 'Quantum system initializing...';
    Timer.periodic(const Duration(milliseconds: 25), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_loadingProgress < 100) {
          _loadingProgress++;
          if (_loadingProgress == 25) {
            _loadingStatus = _locale == 'ar' ? 'رسم أصفار دالة ريمان...' : 'Mapping Riemann zeta zeros...';
          } else if (_loadingProgress == 55) {
            _loadingStatus = _locale == 'ar' ? 'تنشيط جدران التشفير الثلاثية...' : 'Securing triple encryption pipelines...';
          } else if (_loadingProgress == 85) {
            _loadingStatus = _locale == 'ar' ? 'مزامنة ترابط الطيف المتوازن...' : 'Synchronizing wave coherence spectrums...';
          }
        } else {
          _isLoaded = true;
          timer.cancel();
          _appendSecurityLog(
            'System Startup Completed',
            'success',
            'Riemann multi-layer security suite standard protocols established. Secure orbit active.',
          );
        }
      });
    });
  }

  void _seedInitialSecurityLogs() {
    _logs.addAll([
      SecurityLogEvent(
        id: 'L01',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        event: 'Sovereign Cryptst Kernel Boot',
        severity: 'info',
        details: 'Loaded cryptographic micro-core components.',
      ),
      SecurityLogEvent(
        id: 'L02',
        timestamp: DateTime.now().subtract(const Duration(minutes: 4)),
        event: 'Zeta zero mapping compiled',
        severity: 'success',
        details: 'First 10 non-trivial zeroes lying on critical line s=1/2 embedded.',
      ),
    ]);
  }

  void _appendSecurityLog(String message, String severity, String details) {
    if (!mounted) return;
    setState(() {
      final code = 'L${(_logs.length + 1).toString().padLeft(2, '0')}';
      _logs.add(SecurityLogEvent(
        id: code,
        timestamp: DateTime.now(),
        event: message,
        severity: severity,
        details: details,
      ));
    });

    // Auto scroll the terminal log list to bottom
    Future.delayed(const Duration(milliseconds: 80), () {
      if (_terminalScrollController.hasClients) {
        _terminalScrollController.animateTo(
          _terminalScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showNotification(String message, String type) {
    if (!mounted) return;
    final color = type == 'success' ? const Color(0xFF06B6D4) : const Color(0xFFB91C1C);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              type == 'success' ? Icons.check_circle : Icons.error,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'monospace'),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildSplashScreen() {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: const BoxDecoration(
          color: Color(0xFF030712),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.all_inclusive,
              size: 56,
              color: Color(0xFF06B6D4),
            ),
            const SizedBox(height: 18),
            Text(
              translate('title', _locale),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.0,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              translate('subtitle', _locale),
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade500,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _loadingProgress / 100.0,
                backgroundColor: Colors.white10,
                color: const Color(0xFF06B6D4),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _loadingStatus,
                    style: TextStyle(fontSize: 9, color: Colors.grey.shade500, fontFamily: 'monospace'),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '$_loadingProgress %',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF06B6D4), fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppLockOverlay() {
    final locVal = (String en, String ar) => _locale == 'ar' ? ar : en;
    return Scaffold(
      backgroundColor: const Color(0xFF030712),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock, color: Colors.red, size: 56),
                const SizedBox(height: 16),
                Text(
                  locVal('Sovereign Session Locked', 'تأمين وتجميد الذاكرة'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'monospace'),
                ),
                const SizedBox(height: 8),
                Text(
                  locVal('All decrypted cached channels have been purged.', 'بروتوكول الطوارئ مسح مفاتيح التشفير وتفريغ الحافظة.'),
                  style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // PIN Dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) {
                    final isFilled = _pinValue.length > index;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: isFilled ? Colors.red : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.red.withOpacity(0.5), width: 2),
                      ),
                    );
                  }),
                ),
                if (_pinError.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    _pinError,
                    style: const TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ],
                const SizedBox(height: 32),
                // Number Pad (Grid of Buttons)
                SizedBox(
                  width: 240,
                  child: GridView.count(
                    shrinkWrap: true,
                    crossAxisCount: 3,
                    childAspectRatio: 1.25,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      ...[1, 2, 3, 4, 5, 6, 7, 8, 9].map((num) => _buildPinPadButton(num.toString())),
                      // Backspace
                      TextButton(
                        onPressed: () {
                          if (_pinValue.isNotEmpty) {
                            setState(() {
                              _pinValue = _pinValue.substring(0, _pinValue.length - 1);
                              _pinError = '';
                            });
                          }
                        },
                        child: const Text('DEL', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                      _buildPinPadButton('0'),
                      // OK Button
                      TextButton(
                        onPressed: () {
                          if (_pinValue == '1234') {
                            setState(() {
                              _pinValue = '';
                              _pinError = '';
                              VaultService().setLocked(false);
                            });
                            _appendSecurityLog(
                              'Sovereign session authenticated',
                              'info',
                              'Correct PIN provided to unlock system memory.',
                            );
                            _showNotification(
                              locVal('Access Granted. Workspace Unlocked.', 'تم التصريح بالدخول. أهلاً بك في وحدة ريمان.'),
                              'success',
                            );
                          } else {
                            setState(() {
                              _pinValue = '';
                              _pinError = locVal('Incorrect PIN specification!', 'رمز التعريف PIN المدخل خاطئ!');
                            });
                          }
                        },
                        child: const Text('OPEN', style: TextStyle(color: Colors.cyan, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  locVal('Initial bypass PIN is: 1234', 'رمز العبور المبدئي لفك القفل هو: 1234'),
                  style: TextStyle(fontSize: 8, color: Colors.grey.shade600, fontFamily: 'monospace'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPinPadButton(String text) {
    return InkWell(
      borderRadius: BorderRadius.circular(30),
      onTap: () {
        if (_pinValue.length < 4) {
          setState(() {
            _pinValue += text;
            _pinError = '';
          });
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withOpacity(0.04)),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    final List<Map<String, dynamic>> tabs = [
      {'icon': Icons.monitor_heart, 'key': 'tab_dashboard'},
      {'icon': Icons.verified_user, 'key': 'tab_security'},
      {'icon': Icons.security, 'key': 'tab_vaults'},
      {'icon': Icons.hub, 'key': 'tab_nexus'},
      {'icon': Icons.archive, 'key': 'tab_archive'},
      {'icon': Icons.policy, 'key': 'tab_forensics'},
      {'icon': Icons.shield, 'key': 'tab_sentinel'},
      {'icon': Icons.business_center, 'key': 'tab_workspace'},
      {'icon': Icons.text_snippet, 'key': 'tab_text'},
      {'icon': Icons.folder_zip, 'key': 'tab_file'},
      {'icon': Icons.lock_clock, 'key': 'tab_capsules'},
      {'icon': Icons.vpn_key, 'key': 'tab_keygen'},
      {'icon': Icons.note_alt, 'key': 'tab_notes'},
      {'icon': Icons.book, 'key': 'tab_journal'},
      {'icon': Icons.photo_library, 'key': 'tab_gallery'},
      {'icon': Icons.video_library, 'key': 'tab_media_vault'},
      {'icon': Icons.waves, 'key': 'tab_spectrum'},
      {'icon': Icons.code, 'key': 'tab_flutter'},
    ];

    return Container(
      height: 44,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: tabs.length,
        itemBuilder: (context, idx) {
          final tab = tabs[idx];
          final isSelected = _currentTabIndex == idx;
          final label = translate(tab['key']!, _locale);

          return GestureDetector(
            onTap: () {
              setState(() {
                _currentTabIndex = idx;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8, left: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF1F2937) : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? const Color(0xFF06B6D4) : Colors.white.withOpacity(0.04),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    tab['icon'] as IconData,
                    size: 14,
                    color: isSelected ? const Color(0xFF06B6D4) : Colors.grey,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAuditTerminalLogs() {
    return Container(
      height: 120,
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF090D16),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.terminal, color: Color(0xFF10B981), size: 12),
                  const SizedBox(width: 6),
                  Text(
                    translate('audit_log_title', _locale),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.white),
                  ),
                ],
              ),
              InkWell(
                onTap: () {
                  setState(() {
                    _logs.clear();
                  });
                  _appendSecurityLog(
                    'Log Terminal Clear',
                    'info',
                    'Dynamic telemetry buffers flushed.',
                  );
                },
                child: Text(
                  translate('clear_data', _locale),
                  style: const TextStyle(fontSize: 8, color: Color(0xFFEF4444), fontFamily: 'monospace', fontWeight: FontWeight.bold),
                ),
              )
            ],
          ),
          const Divider(height: 12, color: Colors.white10),
          Expanded(
            child: _logs.isEmpty
                ? Center(
                    child: Text(
                      translate('standard_operations', _locale),
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 8),
                    ),
                  )
                : ListView.builder(
                    controller: _terminalScrollController,
                    physics: const BouncingScrollPhysics(),
                    itemCount: _logs.length,
                    itemBuilder: (context, idx) {
                      final log = _logs[idx];
                      Color severityColor = const Color(0xFF06B6D4);
                      if (log.severity == 'warning') severityColor = Colors.amber;
                      else if (log.severity == 'critical') severityColor = const Color(0xFFEF4444);
                      else if (log.severity == 'success') severityColor = const Color(0xFF10B981);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '[\${log.id}] [${log.severity.toUpperCase()}]',
                                  style: TextStyle(color: severityColor, fontSize: 8, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    log.event,
                                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 12, top: 1),
                              child: Text(
                                log.details,
                                style: TextStyle(color: Colors.grey.shade500, fontSize: 8, height: 1.2),
                              ),
                            )
                          ],
                        ),
                      );
                    },
                  ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded) {
      return _buildSplashScreen();
    }

    final vaultService = VaultService();
    if (vaultService.isLocked) {
      return _buildAppLockOverlay();
    }

    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0F19),
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.all_inclusive, color: Color(0xFF06B6D4), size: 20),
            const SizedBox(width: 8),
            Text(
              translate('title', _locale),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        actions: [
          // Secure system badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text(
                  translate('secure_badge', _locale),
                  style: const TextStyle(color: Color(0xFF10B981), fontSize: 8, fontWeight: FontWeight.bold),
                )
              ],
            ),
          ),
          const SizedBox(width: 10),

          // GLOBE LANGUAGE TOGGLER
          IconButton(
            icon: const Icon(Icons.language, color: Colors.grey, size: 18),
            onPressed: () {
              setState(() {
                _locale = _locale == 'ar' ? 'en' : 'ar';
              });
              _appendSecurityLog(
                'System locale changed',
                'info',
                'Language switch: "$_locale". Modulating labels.',
              );
              _showNotification(
                _locale == 'ar' ? 'تغيرت واجهة لغة الطيف إلى العربية' : 'System spectrum interface language set to English',
                'success',
              );
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Tabs scroll row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildTabBar(),
            ),

            // Active Tab mount
            Expanded(
              child: IndexedStack(
                index: _currentTabIndex,
                children: [
                  SovereignDashboardWidget(
                    locale: _locale,
                    onSecurityLog: _appendSecurityLog,
                  ),
                  SecurityCenterWidget(
                    locale: _locale,
                    onSecurityLog: _appendSecurityLog,
                    onSuccess: _showNotification,
                  ),
                  SmartVaultsTab(
                    locale: _locale,
                    onSecurityLog: _appendSecurityLog,
                    onSuccess: _showNotification,
                  ),
                  NexusDashboardWidget(
                    locale: _locale,
                    onSecurityLog: _appendSecurityLog,
                    onSuccess: _showNotification,
                  ),
                  ArchiveDashboardWidget(
                    locale: _locale,
                    onSecurityLog: _appendSecurityLog,
                    onSuccess: _showNotification,
                  ),
                  ForensicsDashboardWidget(
                    locale: _locale,
                    onSecurityLog: _appendSecurityLog,
                    onSuccess: _showNotification,
                  ),
                  SentinelDashboardWidget(
                    locale: _locale,
                    onSecurityLog: _appendSecurityLog,
                    onSuccess: _showNotification,
                  ),
                  WorkspaceDashboardWidget(
                    locale: _locale,
                    onSecurityLog: _appendSecurityLog,
                    onSuccess: _showNotification,
                  ),
                  TextShieldWidget(
                    locale: _locale,
                    onSecurityLog: _appendSecurityLog,
                    onSuccess: _showNotification,
                  ),
                  FileShieldWidget(
                    locale: _locale,
                    onSecurityLog: _appendSecurityLog,
                    onSuccess: _showNotification,
                  ),
                  TimeCapsulesWidget(
                    locale: _locale,
                    onSecurityLog: _appendSecurityLog,
                    onSuccess: _showNotification,
                  ),
                  KeyGeneratorWidget(
                    locale: _locale,
                    onSecurityLog: _appendSecurityLog,
                    onSuccess: _showNotification,
                  ),
                  SecureNotesWidget(
                    locale: _locale,
                    onSecurityLog: _appendSecurityLog,
                    onSuccess: _showNotification,
                  ),
                  SecureJournalWidget(
                    locale: _locale,
                    onSecurityLog: _appendSecurityLog,
                    onSuccess: _showNotification,
                  ),
                  SecureGalleryWidget(
                    locale: _locale,
                    onSecurityLog: _appendSecurityLog,
                    onSuccess: _showNotification,
                  ),
                  SecureMediaWidget(
                    locale: _locale,
                    onSecurityLog: _appendSecurityLog,
                    onSuccess: _showNotification,
                  ),
                  SpectrumAnalyzerWidget(
                    locale: _locale,
                    onSecurityLog: _appendSecurityLog,
                  ),
                  FlutterExporterWidget(
                    locale: _locale,
                    onSuccess: _showNotification,
                  ),
                ],
              ),
            ),

            // Global audit log terminal below mount
            _buildAuditTerminalLogs(),

            // Footer specifications credits
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: Colors.black,
              child: Column(
                children: [
                  Text(
                    translate('version_footer', _locale),
                    style: const TextStyle(fontSize: 7, color: Colors.white24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    translate('copyright_footer', _locale),
                    style: const TextStyle(fontSize: 6, color: Colors.white10),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
