import 'package:RPMLauncher/Utility/i18n.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// ignore: must_be_immutable
class CheckDialog extends StatelessWidget {
  final VoidCallback? onPressedOK;
  final String title;
  final String content;

  const CheckDialog({
    required this.title,
    required this.content,
    required this.onPressedOK,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          child: Text(i18n.Format("gui.cancel")),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        TextButton(
            child: Text(i18n.Format("gui.confirm")), onPressed: onPressedOK),
      ],
    );
  }
}
