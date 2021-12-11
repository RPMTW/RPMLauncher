import 'package:flutter/material.dart';

class RPMTextField extends StatefulWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final bool Function(String value)? verify;
  final String? hintText;
  final TextAlign textAlign;
  final TextInputType? keyboardType;
  final VoidCallback? onEditingComplete;

  const RPMTextField({
    this.controller,
    this.onChanged,
    this.verify,
    this.hintText,
    this.textAlign = TextAlign.center,
    this.keyboardType,
    this.onEditingComplete,
  });

  @override
  State<RPMTextField> createState() => _RPMTextFieldState();
}

class _RPMTextFieldState extends State<RPMTextField> {
  Color enabledColor = Colors.white12;

  Color focusedColor = Colors.lightBlue;

  @override
  Widget build(BuildContext context) {
    return TextField(
        controller: widget.controller,
        decoration: InputDecoration(
          hintText: widget.hintText,
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: enabledColor, width: 3.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: focusedColor, width: 3.0),
          ),
        ),
        textAlign: widget.textAlign,
        keyboardType: widget.keyboardType,
        onEditingComplete: widget.onEditingComplete,
        onChanged: (value) {
          bool verifyResult = widget.verify?.call(value) ?? true;

          if (!verifyResult) {
            enabledColor = Colors.red;
            focusedColor = Colors.red;
          } else {
            enabledColor = Colors.white12;
            focusedColor = Colors.lightBlue;
            widget.onChanged?.call(value);
          }
          setState(() {});
        });
  }
}
