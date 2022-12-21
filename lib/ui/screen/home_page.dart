import 'package:blur/blur.dart';
import 'package:flutter/material.dart';
import 'package:rpmlauncher/config/config.dart';
import 'package:rpmlauncher/ui/screen/settings.dart';
import 'package:rpmlauncher/ui/theme/launcher_theme.dart';
import 'package:rpmlauncher/ui/widget/dialog/UpdaterDialog.dart';
import 'package:rpmlauncher/ui/widget/dialog/quick_setup.dart';
import 'package:rpmlauncher/ui/widget/rpml_app_bar.dart';
import 'package:rpmlauncher/ui/widget/rpml_button.dart';
import 'package:rpmlauncher/ui/widget/rpmtw_design/background.dart';
import 'package:rpmlauncher/util/updater.dart';

class HomePage extends StatefulWidget {
  static const String route = '/';
  final int initialPage;

  const HomePage({Key? key, this.initialPage = 0}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (!launcherConfig.isInit && mounted) {
        showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const QuickSetup());
      } else {
        Updater.checkForUpdate(Updater.fromConfig()).then((info) {
          if (info.needUpdate && mounted) {
            showDialog(
                context: context,
                builder: (context) => UpdaterDialog(info: info));
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Background(
      child: SafeArea(
        child: Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              _buildTitle(context),
              _buildActions(context),
              Align(
                  alignment: Alignment.bottomRight,
                  child: Blur(
                    blur: 100,
                    blurColor: Colors.black,
                    colorOpacity: 0.3,
                    borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomLeft: Radius.circular(12)),
                    child: Container(
                      constraints: BoxConstraints(
                          minWidth: 400,
                          maxWidth: 400,
                          maxHeight: MediaQuery.of(context).size.height - 90),
                      child: Column(
                        children: const [
                          Text('Minecraft 新聞'),
                        ],
                      ),
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Align _buildTitle(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Column(
        children: [
          const RPMLAppBar(),
          Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.home_rounded, size: 50),
                  const SizedBox(width: 10),
                  FittedBox(
                    child: Text(
                      'RPMLauncher',
                      style: TextStyle(
                        fontSize: 34,
                        color: context.theme.textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    const double height = 58;
    const double width = 450;
    final labelStyle = TextStyle(color: context.theme.textColor, fontSize: 20);

    return Align(
      alignment: Alignment.bottomLeft,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Wrap(
          spacing: 18,
          direction: Axis.vertical,
          children: [
            RPMLButton(
              label: '收藏庫',
              onPressed: () {},
              icon: Icon(
                Icons.widgets_outlined,
                color: context.theme.textColor,
              ),
              width: width,
              height: height,
              // labelStyle: labelStyle,
            ),
            RPMLButton(
              label: '探索',
              onPressed: () {},
              icon:
                  Icon(Icons.explore_outlined, color: context.theme.textColor),
              width: width,
              height: height,
              labelStyle: labelStyle,
            ),
            RPMLButton(
              label: '新聞',
              onPressed: () {},
              icon: Icon(Icons.newspaper_outlined,
                  color: context.theme.textColor),
              width: width,
              height: height,
              labelStyle: labelStyle,
            ),
            RPMLButton(
              label: '設定',
              onPressed: () {
                Navigator.of(context).pushNamed(SettingScreen.route);
              },
              icon: Icon(Icons.settings, color: context.theme.textColor),
              width: width,
              height: height,
              labelStyle: labelStyle,
            ),
          ],
        ),
      ),
    );
  }
}
