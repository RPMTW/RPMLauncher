import 'package:flutter/material.dart';
import 'package:rpmlauncher/Utility/I18n.dart';
import 'package:rpmlauncher/Widget/RPMTW-Design/OkClose.dart';

class UnSupportedForgeVersion extends StatelessWidget {
  String gameVersion;
  UnSupportedForgeVersion({
    required this.gameVersion,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: I18nText.errorInfoText(),
      content: I18nText(
        "version.list.mod.loader.forge.error",
        args: {"version": gameVersion},
      ),
      actions: [const OkClose()],
    );
  }
}
