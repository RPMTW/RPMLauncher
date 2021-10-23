import 'package:flutter/material.dart';
import 'package:rpmlauncher/Utility/I18n.dart';

class OkClose extends StatelessWidget {
  final Function? onOk;
  const OkClose({
    Key? key,
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
        child: Text(I18n.format("gui.ok")));
  }
}
