import 'package:blur/blur.dart';
import 'package:flutter/material.dart';
import 'package:rpmlauncher/i18n/i18n.dart';
import 'package:rpmlauncher/launcher/download/game_install_task.dart';
import 'package:rpmlauncher/model/game/loader.dart';
import 'package:rpmlauncher/model/game/version/mc_version.dart';
import 'package:rpmlauncher/task/task_manager.dart';
import 'package:rpmlauncher/ui/theme/launcher_theme.dart';
import 'package:rpmlauncher/ui/widget/rpml_button.dart';
import 'package:rpmlauncher/ui/widget/rpml_dialog.dart';
import 'package:rpmlauncher/ui/widget/rpmtw_design/rpml_text_field.dart';
import 'package:rpmlauncher/util/launcher_info.dart';
import 'package:rpmtw_dart_common_library/rpmtw_dart_common_library.dart';

class CreateCollectionDialog extends StatefulWidget {
  final GameLoader loader;
  final MCVersion version;
  final ImageProvider image;

  const CreateCollectionDialog(
      {super.key,
      required this.image,
      required this.loader,
      required this.version});

  @override
  State<CreateCollectionDialog> createState() => _CreateCollectionDialogState();
}

class _CreateCollectionDialogState extends State<CreateCollectionDialog> {
  late final TextEditingController nameController;

  @override
  void initState() {
    nameController = TextEditingController(
        text: '${widget.loader.name.toCapitalized()} - ${widget.version.id}');
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return RPMLDialog(
      title: '建立您的收藏',
      icon: Icon(Icons.create_new_folder_rounded,
          color: context.theme.primaryColor),
      actions: [
        IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            tooltip: I18n.format('gui.back'),
            icon: const Icon(Icons.low_priority_rounded, size: 30))
      ],
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Expanded(
                flex: 3,
                child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Blur(
                        blur: 0,
                        colorOpacity: 0.2,
                        blurColor: context.theme.mainColor,
                        child: Image(image: widget.image)))),
            Expanded(
              flex: 4,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('收藏名稱', style: TextStyle(fontSize: 22)),
                  const SizedBox(height: 8),
                  FractionallySizedBox(
                    widthFactor: 0.8,
                    child: RPMLTextField(
                      controller: nameController,
                      hintText: '請輸入收藏名稱',
                      onChanged: (value) {},
                    ),
                  ),
                  const SizedBox(height: 15),
                  RPMLButton(
                      width: 100,
                      height: 50,
                      label: '建立',
                      icon: const Icon(Icons.done_rounded),
                      labelType: RPMLButtonLabelType.text,
                      onPressed: () {
                        Navigator.of(context).pushNamed(LauncherInfo.route);
                        taskManager.submit(GameInstallTask(
                            displayName: nameController.text,
                            loader: widget.loader,
                            version: widget.version));
                      })
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
