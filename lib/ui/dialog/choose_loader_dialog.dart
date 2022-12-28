import 'package:flutter/material.dart';
import 'package:rpmlauncher/ui/theme/launcher_theme.dart';
import 'package:rpmlauncher/ui/widget/rpml_dialog.dart';

class ChooseLoaderDialog extends StatefulWidget {
  const ChooseLoaderDialog({super.key});

  @override
  State<ChooseLoaderDialog> createState() => _ChooseLoaderDialogState();
}

class _ChooseLoaderDialogState extends State<ChooseLoaderDialog> {
  @override
  Widget build(BuildContext context) {
    return RPMLDialog(
      title: '載入器類型',
      icon: Icon(Icons.offline_bolt_rounded, color: context.theme.primaryColor),
      insetPadding: EdgeInsets.symmetric(
          vertical: MediaQuery.of(context).size.height / 6,
          horizontal: MediaQuery.of(context).size.width / 4.3),
      child: ConstrainedBox(
        constraints: const BoxConstraints.expand(),
        child: Wrap(
          spacing: 20,
          children: [_buildLoader()],
        ),
      ),
    );
  }

  Widget _buildLoader() {
    return Container(
        decoration: const BoxDecoration(
            image: DecorationImage(
                image: AssetImage('assets/images/Minecraft.png'))));
  }
}
