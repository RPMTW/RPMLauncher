import 'package:flutter/material.dart';

class RMLTextField extends StatefulWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final bool Function(String value)? verify;
  final String? hintText;
  final TextAlign textAlign;
  final TextInputType? keyboardType;
  final VoidCallback? onEditingComplete;

  const RMLTextField({
    this.controller,
    this.onChanged,
    this.verify,
    this.hintText,
    this.textAlign = TextAlign.center,
    this.keyboardType,
    this.onEditingComplete,
  });

  @override
  State<RMLTextField> createState() => _RMLTextFieldState();
}

class _RMLTextFieldState extends State<RMLTextField> {
  Color? color;

  @override
  Widget build(BuildContext context) {
    return TextField(
        controller: widget.controller,
        decoration: InputDecoration(
            hintText: widget.hintText,
            border: const OutlineInputBorder(),
            errorText: color == null ? null : '',
            errorStyle: const TextStyle(fontSize: 0)),
        textAlign: widget.textAlign,
        keyboardType: widget.keyboardType,
        onEditingComplete: widget.onEditingComplete,
        onChanged: (value) {
          bool verifyResult = widget.verify?.call(value) ?? true;

          if (!verifyResult) {
            color = Colors.red;
          } else {
            color = null;
            widget.onChanged?.call(value);
          }
          setState(() {});
        });
  }
}
