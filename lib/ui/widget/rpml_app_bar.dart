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
  bool menuExpanded = false;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
          bottomRight: Radius.circular(10), topRight: Radius.circular(10)),
      child: Container(
          constraints: BoxConstraints(maxWidth: menuExpanded ? 270 : 70),
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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: IconButton(
                        onPressed: () {
                          setState(() {
                            menuExpanded = !menuExpanded;
                          });
                        },
                        icon: const Icon(Icons.menu_outlined),
                        selectedIcon: const Icon(Icons.menu_open_outlined),
                        isSelected: menuExpanded,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        color: context.theme.textColor,
                        iconSize: 32,
                        tooltip: '展開選單'),
                  ),
                  _buildActionButton(
                    label: '探索',
                    icon: const Icon(Icons.explore_outlined),
                    selectedIcon: const Icon(Icons.explore_rounded),
                    selected: selectedIndex == 0,
                    onPressed: () {
                      setState(() {
                        selectedIndex = 0;
                        widget.onIndexChanged?.call(selectedIndex);
                      });
                    },
                  ),
                  _buildActionButton(
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
                  _buildActionButton(
                    label: '釘選與最愛',
                    icon: const Icon(Icons.push_pin_outlined),
                    selectedIcon: const Icon(Icons.push_pin_rounded),
                    selected: selectedIndex == 2,
                    onPressed: () {
                      setState(() {
                        selectedIndex = 2;
                        widget.onIndexChanged?.call(selectedIndex);
                      });
                    },
                  ),
                  _buildActionButton(
                    label: '多人遊戲',
                    icon: const Icon(Icons.groups_3_outlined),
                    selectedIcon: const Icon(Icons.groups_3_rounded),
                    selected: selectedIndex == 3,
                    onPressed: () {
                      setState(() {
                        selectedIndex = 3;
                        widget.onIndexChanged?.call(selectedIndex);
                      });
                    },
                  ),
                  _buildActionButton(
                    label: '新聞',
                    icon: const Icon(Icons.newspaper_rounded),
                    selectedIcon: const Icon(Icons.newspaper),
                    selected: selectedIndex == 4,
                    onPressed: () {
                      setState(() {
                        selectedIndex = 4;
                        widget.onIndexChanged?.call(selectedIndex);
                      });
                    },
                  ),
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

  Widget _buildActionButton({
    required String label,
    required Widget icon,
    required Widget selectedIcon,
    required bool selected,
    required VoidCallback onPressed,
  }) {
    final indicator = Container(
      height: 35,
      width: 7,
      decoration: selected
          ? BoxDecoration(
              color: context.theme.primaryColor,
              borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(3),
                  bottomRight: Radius.circular(3)),
            )
          : null,
    );
    const double iconSize = 32;

    return Row(
      children: [
        indicator,
        if (menuExpanded)
          Tooltip(
            message: label,
            child: TextButton.icon(
              label: Text(
                label,
                style: TextStyle(
                  color: context.theme.textColor,
                  fontSize: 16,
                ),
              ),
              onPressed: onPressed,
              style: TextButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  backgroundColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  minimumSize: const Size(150, 60)),
              icon: IconTheme(
                  data: IconThemeData(
                    color: context.theme.textColor,
                    size: iconSize,
                  ),
                  child: selected ? selectedIcon : icon),
            ),
          ),
        if (!menuExpanded)
          IconButton(
            tooltip: label,
            onPressed: onPressed,
            icon: icon,
            selectedIcon: selectedIcon,
            isSelected: selected,
            color: context.theme.textColor,
            iconSize: iconSize,
            style: IconButton.styleFrom(
              backgroundColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
      ],
    );
  }
}
