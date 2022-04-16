import 'package:rpmlauncher/Utility/I18n.dart';
import 'package:flutter/material.dart';

class CheckDialog extends StatelessWidget {
  final VoidCallback? onPressedOK;
  final String title;
  final String message;

  const CheckDialog({
    required this.title,
    required this.message,
    required this.onPressedOK,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          child: Text(I18n.format("gui.cancel")),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        TextButton(
            onPressed: onPressedOK, child: Text(I18n.format("gui.confirm"))),
      ],
    );
  }
}
