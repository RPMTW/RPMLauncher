import 'package:blur/blur.dart';
import 'package:dyn_mouse_scroll/dyn_mouse_scroll.dart';
import 'package:flutter/material.dart';
import 'package:rpmlauncher/api/mojang_meta_api.dart';
import 'package:rpmlauncher/handler/game_version_handler.dart';
import 'package:rpmlauncher/i18n/i18n.dart';
import 'package:rpmlauncher/model/game/loader.dart';
import 'package:rpmlauncher/model/game/version/mc_version.dart';
import 'package:rpmlauncher/model/game/version/mc_version_manifest.dart';
import 'package:rpmlauncher/model/game/version/mc_version_type.dart';
import 'package:rpmlauncher/ui/theme/launcher_theme.dart';
import 'package:rpmlauncher/ui/widget/rpml_button.dart';
import 'package:rpmlauncher/ui/widget/rpml_dialog.dart';

class ChooseVersionDialog extends StatefulWidget {
  final GameLoader loader;
  const ChooseVersionDialog({super.key, required this.loader});

  @override
  State<ChooseVersionDialog> createState() => _ChooseVersionDialogState();
}

class _ChooseVersionDialogState extends State<ChooseVersionDialog> {
  @override
  Widget build(BuildContext context) {
    return RPMLDialog(
      title: '遊戲版本',
      icon: Icon(Icons.view_in_ar_rounded, color: context.theme.primaryColor),
      insetPadding: EdgeInsets.symmetric(
          vertical: MediaQuery.of(context).size.height / 6,
          horizontal: MediaQuery.of(context).size.width / 4.3),
      actions: [
        IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            tooltip: I18n.format('gui.back'),
            icon: const Icon(Icons.low_priority_rounded, size: 30))
      ],
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: FutureBuilder<MCVersionManifest>(
            future: MojangMetaAPI.getVersionManifest(),
            builder: (context, snapshot) {
              final data = snapshot.data;
              if (data != null) {
                final versions =
                    data.versions.where((e) => e.type == MCVersionType.release);
                final mainVersions = versions
                    .map((e) => GameVersionHandler.parse(e.id))
                    .map((e) => '${e.major}.${e.minor}')
                    .toSet() // Remove duplicate
                    .toList();

                return DynMouseScroll(builder: (context, controller, physics) {
                  return ListView.builder(
                      controller: controller,
                      physics: physics,
                      itemCount: mainVersions.length,
                      itemBuilder: (context, index) {
                        final mainID = mainVersions[index];
                        final versionList = versions
                            .where((e) => e.id.contains(mainID))
                            .toList();

                        versionList.sort((a, b) =>
                            GameVersionHandler.parse(b.id)
                                .compareTo(GameVersionHandler.parse(a.id)));

                        return Padding(
                          padding: const EdgeInsets.all(8),
                          child: _MainVersionTile(
                              mainID: mainID, versionList: versionList),
                        );
                      });
                });
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            }),
      ),
    );
  }
}

class _MainVersionTile extends StatefulWidget {
  final String mainID;
  final List<MCVersion> versionList;

  const _MainVersionTile({required this.mainID, required this.versionList});

  @override
  State<_MainVersionTile> createState() => _MainVersionTileState();
}

class _MainVersionTileState extends State<_MainVersionTile> {
  late ImageProvider backgroundImage;

  @override
  void initState() {
    backgroundImage = AssetImage('assets/images/versions/${widget.mainID}.png');

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Stack(
        children: [
          Blur(
            blur: 2.5,
            colorOpacity: 0,
            child: Image(
              height: 90,
              width: double.infinity,
              image: backgroundImage,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Image.asset('assets/images/background.png',
                    height: 90, fit: BoxFit.cover);
              },
            ),
          ),
          Container(
            height: 90,
            decoration: BoxDecoration(
                gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                context.theme.backgroundColor,
                context.theme.mainColor.withOpacity(0.3)
              ],
            )),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${widget.mainID}.x',
                      style: const TextStyle(
                          fontSize: 30, fontWeight: FontWeight.bold)),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RPMLButton(
                          height: 50,
                          width: 100,
                          label: '安裝',
                          labelType: RPMLButtonLabelType.text,
                          onPressed: () {}),
                      const SizedBox(width: 12),
                      RPMLButton(
                          height: 50,
                          width: 120,
                          label: '更多版本',
                          isOutline: true,
                          backgroundBlur: 5,
                          labelType: RPMLButtonLabelType.text,
                          onPressed: () {})
                    ],
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
