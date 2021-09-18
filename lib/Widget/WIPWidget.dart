import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rpmlauncher/Utility/i18n.dart';
import 'package:rpmlauncher/Widget/OkClose.dart';

class WiPWidget extends StatelessWidget {
  @override
  build(BuildContext context) {
    return AlertDialog(
      title: Text(i18n.format('gui.tips.info')),
      content: Text(i18n.format('gui.wip')),
      actions: [OkClose()],
    );
  }
}
