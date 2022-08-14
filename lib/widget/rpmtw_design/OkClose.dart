import 'package:flutter/material.dart';
import 'package:rpmlauncher/util/i18n.dart';

class OkClose extends StatelessWidget {
  final Function? onOk;
  final String? title;
  final Color? color;
  const OkClose({
    Key? key,
    this.title,
    this.color,
    this.onOk,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextButton(
        onPressed: () {
          Navigator.pop(context);
          if (onOk != null) {
            onOk!.call();
          }
        },
        child: Text(
          title ?? I18n.format("gui.ok"),
          style: TextStyle(color: color),
        ));
  }
}
