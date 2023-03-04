import 'package:flutter/material.dart';
import 'package:rpmlauncher/ui/dialog/download_manger_dialog.dart';
import 'package:rpmlauncher/ui/theme/launcher_theme.dart';
import 'package:rpmlauncher/util/data.dart';
import 'package:rpmlauncher/util/io_util.dart';
import 'package:rpmlauncher/util/util.dart';

class RPMLAppBar extends StatefulWidget {
  final Function(int index)? onIndexChanged;

  const RPMLAppBar({super.key, required this.onIndexChanged});

  @override
  State<RPMLAppBar> createState() => _RPMLAppBarState();
}

class _RPMLAppBarState extends State<RPMLAppBar> {
  int selectedIndex = 1;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
          bottomRight: Radius.circular(10), topRight: Radius.circular(10)),
      child: Container(
          constraints: const BoxConstraints(maxWidth: 70),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Tooltip(
                message: '開啟 RPMTW 官方網站',
                child: InkResponse(
                  borderRadius: BorderRadius.circular(5),
                  onTap: () {
                    Util.openUri('https://rpmtw.com');
                  },
                  child: Image.asset('assets/images/logo.png',
                      height: 50, width: 50),
                ),
              ),
              const SizedBox(height: 15),
              Wrap(
                spacing: 12,
                direction: Axis.vertical,
                children: [
                  _ActionButton(
                    label: '探索',
                    icon: const Icon(Icons.explore_outlined),
                    selectedIcon: const Icon(Icons.explore),
                    selected: selectedIndex == 0,
                    onPressed: () {
                      setState(() {
                        selectedIndex = 0;
                        widget.onIndexChanged?.call(selectedIndex);
                      });
                    },
                  ),
                  _ActionButton(
                    label: '收藏庫',
                    icon: const Icon(Icons.interests_outlined),
                    selectedIcon: const Icon(Icons.interests),
                    selected: selectedIndex == 1,
                    onPressed: () {
                      setState(() {
                        selectedIndex = 1;
                        widget.onIndexChanged?.call(selectedIndex);
                      });
                    },
                  ),
                  _ActionButton(
                    label: '新聞',
                    icon: const Icon(Icons.newspaper_rounded),
                    selectedIcon: const Icon(Icons.newspaper),
                    selected: selectedIndex == 2,
                    onPressed: () {
                      setState(() {
                        selectedIndex = 2;
                        widget.onIndexChanged?.call(selectedIndex);
                      });
                    },
                  ),
                  _ActionButton(
                    label: '釘選的收藏',
                    icon: const Icon(Icons.push_pin_rounded),
                    selectedIcon: const Icon(Icons.push_pin),
                    selected: selectedIndex == 3,
                    onPressed: () {
                      setState(() {
                        selectedIndex = 3;
                        widget.onIndexChanged?.call(selectedIndex);
                      });
                    },
                  )
                ],
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                        onPressed: () {
                          DownloadMangerDialog.show(context);
                        },
                        tooltip: '下載管理',
                        icon: Icon(
                          Icons.downloading_rounded,
                          color: context.theme.textColor,
                        )),
                    IconButton(
                        onPressed: () {
                          IOUtil.openFileManager(dataHome);
                        },
                        tooltip: '開啟儲存位置',
                        icon: Icon(
                          Icons.folder_open_rounded,
                          color: context.theme.textColor,
                        )),
                    IconButton(
                        onPressed: () {},
                        tooltip: '檢查更新',
                        icon: Icon(
                          Icons.model_training_rounded,
                          color: context.theme.textColor,
                        )),
                    IconButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/settings');
                        },
                        tooltip: '設定',
                        icon: Icon(
                          Icons.tune_rounded,
                          color: context.theme.textColor,
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 22)
            ],
          )),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Widget icon;
  final Widget? selectedIcon;
  final bool selected;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    this.selectedIcon,
    required this.selected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final indicator = Container(
      height: 35,
      width: 6,
      decoration: selected
          ? BoxDecoration(
              color: context.theme.primaryColor,
              borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(3),
                  bottomRight: Radius.circular(3)),
            )
          : null,
    );

    return Row(
      children: [
        indicator,
        Tooltip(
          message: label,
          child: IconButton(
            onPressed: onPressed,
            style: IconButton.styleFrom(
              backgroundColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            color: context.theme.textColor,
            iconSize: 35,
            icon: icon,
            selectedIcon: selectedIcon,
            isSelected: selected,
          ),
        ),
      ],
    );
  }
}
