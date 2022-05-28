import 'package:rpmlauncher/util/I18n.dart';
import 'package:flutter/material.dart';

class CheckDialog extends StatelessWidget {
  final String title;
  final String? message;
  final void Function(BuildContext context) onPressedOK;
  final void Function(BuildContext context)? onPressedCancel;

  const CheckDialog({
    required this.title,
    this.message,
    required this.onPressedOK,
    this.onPressedCancel,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: message != null ? Text(message!) : null,
      actions: [
        ElevatedButton(
          child: Text(I18n.format("gui.cancel")),
          onPressed: () {
            if (onPressedCancel != null) {
              onPressedCancel?.call(context);
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        ElevatedButton(
            onPressed: () {
              onPressedOK(context);
            },
            child: Text(I18n.format("gui.confirm"))),
      ],
    );
  }
}
