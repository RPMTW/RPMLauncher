import 'package:flutter/material.dart';
import 'package:rpmlauncher/model/game/loader.dart';
import 'package:rpmlauncher/model/game/version/mc_version.dart';
import 'package:rpmlauncher/route/slide_route.dart';
import 'package:rpmlauncher/ui/theme/launcher_theme.dart';
import 'package:rpmlauncher/ui/widget/blur_block.dart';
import 'package:rpmlauncher/ui/widget/rpml_button.dart';
import 'package:rpmlauncher/ui/widget/rpml_tool_bar.dart';
import 'package:rpmtw_dart_common_library/rpmtw_dart_common_library.dart';

class CreateCollectionPage extends StatefulWidget {
  final GameLoader loader;
  final MCVersion version;
  final ImageProvider image;

  const CreateCollectionPage(
      {super.key,
      required this.image,
      required this.loader,
      required this.version});

  Future<void> show(BuildContext context) {
    return Navigator.of(context).push(SlideRoute(builder: (context) => this));
  }

  @override
  State<CreateCollectionPage> createState() => _CreateCollectionPageState();
}

class _CreateCollectionPageState extends State<CreateCollectionPage> {
  late final TextEditingController nameController;

  @override
  void initState() {
    nameController = TextEditingController(
        text: '${widget.loader.name.toCapitalized()} - ${widget.version.id}');
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.display_settings_rounded, size: 50),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('收藏資訊', style: TextStyle(fontSize: 30)),
                Text('設定您要建立的收藏資訊',
                    style: TextStyle(
                        color: context.theme.primaryColor, fontSize: 15))
              ])
            ],
          ),
          const SizedBox(height: 15),
          Expanded(
              child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: BlurBlock(
                      child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 25, horizontal: 22),
                    child: Column(
                      children: [
                        Expanded(
                          flex: 10,
                          child: BlurBlock(
                            color: context.theme.dialogBackgroundColor,
                            colorOpacity: 0.8,
                            child: Row(
                              children: [
                                Image(
                                    image: widget.image,
                                    width: 200,
                                    height: 300,
                                    fit: BoxFit.cover),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          flex: 9,
                          child: BlurBlock(
                            color: context.theme.dialogBackgroundColor,
                            colorOpacity: 0.8,
                            child: Row(),
                          ),
                        )
                      ],
                    ),
                  )))),
          RPMLToolBar(actions: [
            RPMLButton(
              label: '返回上一頁',
              isOutline: true,
              icon: const Icon(Icons.low_priority_rounded),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ]),
        ],
      ),
    );
  }
}

/*
  Navigator.of(context).pushNamed(LauncherInfo.route);
                          taskManager.submit(GameInstallTask(
                              displayName: nameController.text,
                              loader: widget.loader,
                              version: widget.version));
*/