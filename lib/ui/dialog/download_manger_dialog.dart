import 'package:blur/blur.dart';
import 'package:flutter/material.dart';
import 'package:rpmlauncher/i18n/i18n.dart';
import 'package:rpmlauncher/ui/theme/launcher_theme.dart';
import 'package:rpmlauncher/ui/widget/round_divider.dart';
import 'package:uuid/uuid.dart';

class DownloadMangerDialog extends StatefulWidget {
  const DownloadMangerDialog({super.key});

  static Future<void> show(BuildContext context) async {
    await showGeneralDialog(
        context: context,
        transitionDuration: const Duration(milliseconds: 400),
        barrierDismissible: true,
        barrierLabel: 'download_manager_dialog${const Uuid().v4()}',
        pageBuilder: (context, animation, secondaryAnimation) {
          return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(-1, 0),
                end: Offset.zero,
              ).chain(CurveTween(curve: Curves.easeInOut)).animate(animation),
              child: const DownloadMangerDialog());
        });
  }

  @override
  State<DownloadMangerDialog> createState() => _DownloadMangerDialogState();
}

class _DownloadMangerDialogState extends State<DownloadMangerDialog> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      alignment: Alignment.topLeft,
      insetPadding: EdgeInsets.zero,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 15),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      context.theme.backgroundColor,
                      context.theme.backgroundColor.withOpacity(0.8),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.3), blurRadius: 25),
                  ],
                ),
                child: Blur(
                  blur: 3,
                  colorOpacity: 0,
                  overlay: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        IntrinsicHeight(
                          child: Row(
                            children: [
                              const Icon(Icons.downloading_rounded, size: 50),
                              const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: RoundDivider(
                                      size: 1.5, color: Color(0XFF4F4F4F))),
                              Text(
                                '下載管理',
                                style: TextStyle(
                                    fontSize: 23,
                                    color: context.theme.textColor),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                  child: Container(),
                ),
              ),
            ),
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(50),
                  child: Container(
                    color: context.theme.dialogBackgroundColor,
                    width: 90,
                    height: 45,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                            tooltip: '下載設定',
                            onPressed: () {},
                            icon: Icon(Icons.tune_rounded,
                                color: context.theme.primaryColor)),
                        IconButton(
                            tooltip: I18n.format('gui.close'),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            icon: const Icon(Icons.menu_open_rounded))
                      ],
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
