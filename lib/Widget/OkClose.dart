import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rpmlauncher/Utility/i18n.dart';

class OkClose extends StatelessWidget {
  final Function? onOk;
  const OkClose({
    Key? key,
    Function? this.onOk,
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
        child: Text(i18n.format("gui.ok")));
  }
}
