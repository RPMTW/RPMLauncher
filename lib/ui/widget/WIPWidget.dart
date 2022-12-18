import 'package:flutter/material.dart';
import 'package:rpmlauncher/i18n/i18n.dart';
import 'package:rpmlauncher/ui/widget/rpmtw_design/OkClose.dart';

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
