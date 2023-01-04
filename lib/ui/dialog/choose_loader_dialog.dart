import 'package:blur/blur.dart';
import 'package:flutter/material.dart';
import 'package:rpmlauncher/model/game/loader.dart';
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
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildLoader('原版', GameLoader.vanilla),
            _buildLoader('Forge', GameLoader.forge),
            _buildLoader('Fabric', GameLoader.fabric),
            _buildLoader('Quilt', GameLoader.quilt)
          ],
        ),
      ),
    );
  }

  Widget _buildLoader(String name, GameLoader loader) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            decoration: BoxDecoration(
                image: DecorationImage(
                    image: AssetImage(loader.getBackgroundAssets()),
                    fit: BoxFit.cover)),
            child: Stack(
              children: [
                Blur(
                  colorOpacity: 0,
                  blur: 2.5,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            context.theme.mainColor.withOpacity(0.3),
                            context.theme.mainColor.withOpacity(0.95)
                          ]),
                    ),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: Image.asset(loader.getIconAssets(),
                            width: 50, height: 50),
                      ),
                      const SizedBox(height: 12),
                      Text(name, style: const TextStyle(fontSize: 25)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
