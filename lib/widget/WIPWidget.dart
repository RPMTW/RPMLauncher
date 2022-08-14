import 'package:flutter/material.dart';
import 'package:rpmlauncher/util/i18n.dart';
import 'package:rpmlauncher/widget/rpmtw_design/OkClose.dart';

class WiPWidget extends StatelessWidget {
  @override
  build(BuildContext context) {
    return AlertDialog(
      title: Text(I18n.format('gui.tips.info')),
      content: Text(I18n.format('gui.wip')),
      actions: const [OkClose()],
    );
  }
}
