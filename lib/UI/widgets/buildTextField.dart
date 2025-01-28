
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

Widget buildTextField({
  required TextEditingController controller,
  required String label,
  required String hintText,
  required TextInputType keyboardType
}) {
  return TextField(
    controller: controller,
    decoration: InputDecoration(
      labelText: label,
      hintText: hintText,
      labelStyle: TextStyle(color: Colors.teal.shade900),
      filled: true,
      fillColor: Colors.teal.shade50,
      border: OutlineInputBorder(),
    ),
  );
}