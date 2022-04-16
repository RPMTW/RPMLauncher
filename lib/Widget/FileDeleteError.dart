import 'package:flutter/material.dart';
import 'package:rpmlauncher/Utility/I18n.dart';
import 'package:rpmlauncher/Widget/RPMTW-Design/OkClose.dart';

class FileDeleteError extends StatelessWidget {
  const FileDeleteError({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: I18nText.errorInfoText(),
      content: I18nText("rpmlauncher.file.delete.error"),
      actions: const [OkClose()],
    );
  }
}
