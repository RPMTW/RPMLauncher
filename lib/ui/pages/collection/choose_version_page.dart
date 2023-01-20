import 'package:blur/blur.dart';
import 'package:dyn_mouse_scroll/dyn_mouse_scroll.dart';
import 'package:flutter/material.dart';
import 'package:rpmlauncher/api/mojang_meta_api.dart';
import 'package:rpmlauncher/handler/game_version_handler.dart';
import 'package:rpmlauncher/model/game/loader.dart';
import 'package:rpmlauncher/model/game/version/mc_version.dart';
import 'package:rpmlauncher/model/game/version/mc_version_manifest.dart';
import 'package:rpmlauncher/model/game/version/mc_version_type.dart';
import 'package:rpmlauncher/route/slide_route.dart';
import 'package:rpmlauncher/ui/pages/collection/create_collection_page.dart';
import 'package:rpmlauncher/ui/theme/launcher_theme.dart';
import 'package:rpmlauncher/ui/widget/blur_block.dart';
import 'package:rpmlauncher/ui/widget/rpml_button.dart';
import 'package:rpmlauncher/ui/widget/rpml_tool_bar.dart';

class ChooseVersionPage extends StatefulWidget {
  final GameLoader loader;
  const ChooseVersionPage({super.key, required this.loader});

  Future<void> show(BuildContext context) {
    return Navigator.of(context).push(
        SlideRoute(begin: const Offset(0.0, 1.0), builder: (context) => this));
  }

  @override
  State<ChooseVersionPage> createState() => _ChooseVersionPageState();
}

class _ChooseVersionPageState extends State<ChooseVersionPage> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const Icon(Icons.view_in_ar_rounded, size: 50),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('遊戲版本', style: TextStyle(fontSize: 30)),
              Text('選擇用於建立您的收藏的 Minecraft 遊戲版本',
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
                padding:
                    const EdgeInsets.symmetric(vertical: 25, horizontal: 22),
                child: Row(
                  children: [
                    Expanded(
                      child: FutureBuilder<MCVersionManifest>(
                          future: MojangMetaAPI.getVersionManifest(),
                          builder: (context, snapshot) {
                            final data = snapshot.data;
                            if (data != null) {
                              final versions = data.versions.where(
                                  (e) => e.type == MCVersionType.release);
                              final mainVersions = versions
                                  .map((e) => GameVersionHandler.parse(e.id))
                                  .map((e) => '${e.major}.${e.minor}')
                                  .toSet() // Remove duplicate
                                  .toList();

                              return DynMouseScroll(
                                  builder: (context, controller, physics) {
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
                                              .compareTo(
                                                  GameVersionHandler.parse(
                                                      a.id)));

                                      return Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: _MainVersionTile(
                                            mainID: mainID,
                                            versionList: versionList),
                                      );
                                    });
                              });
                            } else {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }
                          }),
                    ),
                    const SizedBox(width: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Container(
                        width: MediaQuery.of(context).size.width / 5,
                        color: context.theme.dialogBackgroundColor
                            .withOpacity(0.8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 18, horizontal: 25),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('還是個Minecraft新手嗎？',
                                    style: TextStyle(fontSize: 22)),
                                const SizedBox(height: 8),
                                Text(
                                    '如果您是初次體驗 Minecraft，我們建議您直接安裝最新版本，藉此從零開始體驗 Minecraft 的遊戲世界！',
                                    style: TextStyle(
                                        color: context.theme.subTextColor))
                              ]),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
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
    double height = 115;
    double width = double.infinity;

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Stack(
        children: [
          Blur(
            blur: 5,
            colorOpacity: 0.5,
            blurColor: context.theme.mainColor,
            child: Image(
              height: height,
              width: width,
              image: backgroundImage,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Image.asset('assets/images/background.png',
                    height: height, fit: BoxFit.cover, width: width);
              },
            ),
          ),
          SizedBox(
            height: height,
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
                          onPressed: () {
                            showDialog(
                                context: context,
                                builder: (context) => CreateCollectionPage(
                                    loader: GameLoader.vanilla,
                                    version: widget.versionList.first,
                                    image: backgroundImage));
                          }),
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
