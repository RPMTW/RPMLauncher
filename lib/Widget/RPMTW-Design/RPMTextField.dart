import 'package:flutter/material.dart';

class RPMTextField extends TextField {
  RPMTextField({
    Key? key,
    TextEditingController? controller,
    ValueChanged<String>? onChanged,
    String? hintText,
    TextAlign textAlign = TextAlign.center,
    TextInputType? keyboardType,
  }) : super(
            key: key,
            controller: controller,
            decoration: InputDecoration(
              hintText: hintText,
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white12, width: 3.0),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.lightBlue, width: 3.0),
              ),
            ),
            textAlign: textAlign,
            keyboardType: keyboardType,
            onChanged: onChanged);
}
