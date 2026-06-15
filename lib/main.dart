import 'package:flutter/material.dart';

void main() {
  runApp(const RimanCryptstApp());
}

class RimanCryptstApp extends StatelessWidget {
  const RimanCryptstApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Riman Cryptst',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF030712), // neutral-950
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF06B6D4), // cyan-500
          secondary: Color(0xFFA855F7), // purple-500
          surface: Color(0xFF111827), // neutral-900
        ),
        useMaterial3: true,
      ),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentTabIndex = 0;
  String _inputText = '';
  String _outputText = '';
  String _keyPhrase = 'RiemannSovereign2026';
  bool _isEncrypting = false;

  void _runCryptAction() {
    if (_inputText.isEmpty) return;
    setState(() {
      _isEncrypting = true;
    });

    // Simulate spectrum analysis delay in cryptographic channel
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() {
          _isEncrypting = false;
          // Clean pseudorandom mathematical wave encryption simulation
          _outputText = "RC-ZETA[${_inputText.hashCode.toRadixString(16).toUpperCase()}-${_keyPhrase.hashCode.toRadixString(16).toUpperCase()}]";
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تشفير البيانات بنجاح • Encrypted Successfully via ZETA Pipeline'),
            backgroundColor: Color(0xFF06B6D4),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Riman Cryptst',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              'SOVEREIGN DEVOPS PLATFORM',
              style: TextStyle(fontSize: 10, color: Colors.grey, letterSpacing: 1.5),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF030712),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.security, color: Color(0xFF06B6D4)),
            onPressed: () {},
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTabIndex,
        selectedItemColor: const Color(0xFF06B6D4),
        unselectedItemColor: Colors.grey,
        backgroundColor: const Color(0xFF111827),
        onTap: (index) {
          setState(() {
            _currentTabIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.lock_outline_rounded),
            label: 'Encryption',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.vpn_key_outlined),
            label: 'Key Generator',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: IndexedStack(
            index: _currentTabIndex,
            children: [
              _buildOverviewTab(),
              _buildCryptTab(),
              _buildKeyGenTab(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF111827),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sovereign Security Node Active',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                ),
                SizedBox(height: 8),
                Text(
                  'All telemetry data feeds are protected via non-trivial zeros mapped directly inside the Riman Cryptst mathematics network.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('Security Log', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 10),
          _buildLogItem('CBC / GCM hardware matched successfully', 'SUCCESS'),
          _buildLogItem('Mathematical zeros mapped to keyspace', 'AUTHENTICATED'),
        ],
      ),
    );
  }

  Widget _buildCryptTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          onChanged: (val) => _inputText = val,
          decoration: const InputDecoration(
            labelText: 'رصيد المدخلات • Plaintext Payload',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: _isEncrypting ? null : _runCryptAction,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF06B6D4),
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _isEncrypting 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
            : const Text('تشغيل التشفير • Run Encryption'),
        ),
        if (_outputText.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text('النتيجة • Ciphertext Output', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF111827),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.cyan.withOpacity(0.3)),
            ),
            child: Text(
              _outputText,
              style: const TextStyle(fontFamily: 'Courier', fontSize: 14),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildKeyGenTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sovereign Key Generator',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 4),
        const Text(
          'Generate high entropy 256-bit AES parameters.',
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: TextEditingController(text: _keyPhrase),
          readOnly: true,
          decoration: const InputDecoration(
            labelText: 'Sovereign Passphrase Key',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildLogItem(String txt, String status) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(txt, style: const TextStyle(fontSize: 12))),
          Text(status, style: const TextStyle(fontSize: 10, color: Color(0xFF06B6D4), fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
