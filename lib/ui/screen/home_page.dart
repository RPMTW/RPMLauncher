import 'package:flutter/material.dart';
import 'package:rpmlauncher/config/config.dart';
import 'package:rpmlauncher/ui/widget/dialog/UpdaterDialog.dart';
import 'package:rpmlauncher/ui/widget/dialog/quick_setup.dart';
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
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.home, size: 50),
                    SizedBox(width: 10),
                    Text(
                      'RPMLauncher',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
