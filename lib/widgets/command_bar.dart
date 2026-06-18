import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/riman_x.dart';
import '../utils/riman_x_service.dart';

class CommandBarWidget extends StatefulWidget {
  final String locale;
  final Function(String message, String type) onSuccess;

  const CommandBarWidget({
    Key? key,
    required this.locale,
    required this.onSuccess,
  }) : super(key: key);

  @override
  State<CommandBarWidget> createState() => _CommandBarWidgetState();
}

class _CommandBarWidgetState extends State<CommandBarWidget> {
  final TextEditingController _commandController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<RimanCommand> _predictions = [];
  String _consoleOutput = '';
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _commandController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _commandController.removeListener(_onTextChanged);
    _commandController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final text = _commandController.text.trim();
    if (text.startsWith('/')) {
      setState(() {
        _predictions = RimanXService().commands.where((cmd) {
          return cmd.command.toLowerCase().startsWith(text.toLowerCase());
        }).toList();
      });
    } else {
      if (_predictions.isNotEmpty) {
        setState(() {
          _predictions = [];
        });
      }
    }
  }

  void _submitCommand() {
    final text = _commandController.text.trim();
    if (text.isEmpty) return;

    final output = RimanXService().executeCommand(
      text,
      locale: widget.locale,
      onNotification: (msg, type) => widget.onSuccess(msg, type),
    );

    setState(() {
      _consoleOutput = output;
      _commandController.clear();
      _predictions = [];
      _isExpanded = true;
    });

    _focusNode.unfocus();
  }

  String _locVal(String en, String ar) {
    return widget.locale == 'ar' ? ar : en;
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = widget.locale == 'ar';
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF111827), // deep grey bg
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF06B6D4).withOpacity(0.35), // Cyan neon accent
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF06B6D4).withOpacity(0.08),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Command Bar Title Headers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.terminal,
                    color: const Color(0xFF06B6D4),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _locVal('COMMAND LINE EXECUTOR', 'موجه الأوامر التنفيذي المباشر'),
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: Color(0xFF06B6D4),
                    ),
                  ),
                ],
              ),
              if (_consoleOutput.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear_all, size: 16, color: Colors.white54),
                  onPressed: () {
                    setState(() {
                      _consoleOutput = '';
                    });
                  },
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Main input element
          Row(
            children: [
              Expanded(
                child: Directionality(
                  textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                  child: TextField(
                    controller: _commandController,
                    focusNode: _focusNode,
                    style: const TextStyle(
                      fontFamily: 'JetBrains Mono',
                      color: Colors.white,
                      fontSize: 13,
                    ),
                    decoration: InputDecoration(
                      hintText: _locVal('Type / to display available directives...', 'أدخل / لاستعراض الأوامر التوجيهية المتاحة...'),
                      hintStyle: const TextStyle(
                        fontFamily: 'Inter',
                        color: Colors.white24,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                      prefixIcon: const Icon(Icons.chevron_right, color: Color(0xFF06B6D4), size: 18),
                      filled: true,
                      fillColor: const Color(0xFF1F2937),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF06B6D4), width: 1.2),
                      ),
                    ),
                    onSubmitted: (_) => _submitCommand(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _submitCommand,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF06B6D4),
                  foregroundColor: Colors.black,
                  minimumSize: const Size(40, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  _locVal('EXEC', 'تنفيذ'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.0),
                ),
              ),
            ],
          ),

          // Autocomplete prediction list
          if (_predictions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(maxHeight: 180),
              decoration: BoxDecoration(
                color: const Color(0xFF1F2937),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: _predictions.length,
                itemBuilder: (context, index) {
                  final pred = _predictions[index];
                  return Material(
                    color: Colors.transparent,
                    child: ListTile(
                      dense: true,
                      leading: Icon(pred.icon, size: 14, color: const Color(0xFF06B6D4)),
                      title: Text(
                        pred.command,
                        style: const TextStyle(
                          fontFamily: 'JetBrains Mono',
                          color: Color(0xFF06B6D4),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        _locVal(pred.descriptionEn, pred.descriptionAr),
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: Colors.white.withOpacity(0.70), // complying with Colors.white70 rule
                          fontSize: 10,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () {
                        setState(() {
                          _commandController.text = pred.command;
                          _predictions = [];
                        });
                        _focusNode.requestFocus();
                      },
                    ),
                  );
                },
              ),
            ),
          ],

          // Command line response logs
          if (_consoleOutput.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF030712),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF06B6D4).withOpacity(0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _locVal('CONSOLE EXECUTION REPORT:', 'تقرير مخرجات وحدة المعالجة:'),
                        style: const TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                        ),
                      ),
                      const Icon(Icons.check_circle_outline, color: Colors.green, size: 12),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _consoleOutput,
                    style: const TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 11,
                      color: Colors.lightGreenAccent,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
