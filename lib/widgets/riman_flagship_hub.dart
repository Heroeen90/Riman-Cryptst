import 'package:flutter/material.dart';
import 'command_bar.dart';
import 'deception_radar.dart';

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
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            _locVal('RIMAN FLAGSHIP HUB', 'مركز عمليات ريمان'),
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          CommandBarWidget(locale: locale, onSuccess: onSuccess),
          const SizedBox(height: 16),
          const DeceptionRadarWidget(),
        ],
      ),
    );
  }
}
