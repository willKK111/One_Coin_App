

import 'package:flutter/material.dart';
Widget buildTextFieldAdiciona({
  required TextEditingController controller,
  required String label,
  required String hintText,
  TextInputType keyboardType = TextInputType.text,
  String? Function(String?)? validator,
}) {
  return TextFormField(
    controller: controller,
    keyboardType: keyboardType,
    decoration: InputDecoration(
      labelText: label,
      hintText: hintText,
      labelStyle: TextStyle(fontSize: 16, color: Colors.teal.shade900),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
    validator: validator,
  );
}