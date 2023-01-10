import 'package:flutter/material.dart';
import 'package:rpmlauncher/ui/theme/launcher_theme.dart';

class RPMLTextField extends StatefulWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final bool Function(String value)? verify;
  final String? hintText;
  final TextAlign textAlign;
  final TextInputType? keyboardType;
  final VoidCallback? onEditingComplete;

  const RPMLTextField({
    super.key,
    this.controller,
    this.onChanged,
    this.verify,
    this.hintText,
    this.textAlign = TextAlign.center,
    this.keyboardType,
    this.onEditingComplete,
  });

  @override
  State<RPMLTextField> createState() => _RPMLTextFieldState();
}

class _RPMLTextFieldState extends State<RPMLTextField> {
  Color? color;

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: context.theme.borderColor, width: 2.5));

    return TextField(
        controller: widget.controller,
        decoration: InputDecoration(
            hintText: widget.hintText,
            border: border,
            enabledBorder: border,
            focusedBorder: border,
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
