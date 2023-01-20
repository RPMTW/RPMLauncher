import 'package:blur/blur.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rpmlauncher/ui/dialog/download_manger_dialog.dart';
import 'package:rpmlauncher/ui/theme/launcher_theme.dart';
import 'package:rpmlauncher/ui/theme/rpml_theme_type.dart';
import 'package:rpmlauncher/ui/widget/round_divider.dart';
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
        constraints: const BoxConstraints(maxWidth: 80),
        child: Blur(
          blur: 50,
          blurColor: context.theme.backgroundColor,
          colorOpacity: 0.8,
          overlay: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
                child: Tooltip(
                  message: '開啟 RPMTW 官方網站',
                  child: InkResponse(
                    borderRadius: BorderRadius.circular(5),
                    onTap: () {
                      Util.openUri('https://rpmtw.com');
                    },
                    child: SvgPicture.asset(
                      context.theme.type == RPMLThemeType.light
                          ? 'assets/images/rpmtw-logo-black.svg'
                          : 'assets/images/rpmtw-logo-white.svg',
                      height: 50,
                    ),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: RoundDivider(size: 2.5),
              ),
              const SizedBox(height: 15),
              Wrap(
                spacing: 12,
                direction: Axis.vertical,
                children: [
                  _ActionButton(
                    label: '探索',
                    icon: const Icon(Icons.explore_rounded),
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
                    const SizedBox(height: 12),
                    _ActionButton(
                      label: '展開側邊欄',
                      icon: const Icon(Icons.swipe_right_alt_outlined),
                      selected: true,
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22)
            ],
          ),
          child: Container(),
        ),
      ),
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
    return SizedBox(
      height: 55,
      width: 55,
      child: Tooltip(
        message: label,
        child: IconButton(
          onPressed: onPressed,
          style: IconButton.styleFrom(
            backgroundColor:
                selected ? context.theme.textColor : Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          color: selected ? context.theme.mainColor : context.theme.textColor,
          iconSize: 35,
          icon: icon,
          selectedIcon: selectedIcon,
          isSelected: selected,
        ),
      ),
    );
  }
}
