import 'package:flutter/material.dart';

class KeyboardSecurityService {
  static InputDecoration getSecureInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      fillColor: Colors.blueGrey.withOpacity(0.1),
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.blueGrey),
      ),
    );
  }

  static Widget secureTextField(
      TextEditingController controller, String label, bool obscure) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      enableSuggestions: false,
      autocorrect: false,
      decoration: getSecureInputDecoration(label),
      style: const TextStyle(color: Colors.white, fontFamily: 'JetBrains Mono'),
    );
  }
}
