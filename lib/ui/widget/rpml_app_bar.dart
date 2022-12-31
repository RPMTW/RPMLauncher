import 'package:blur/blur.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rpmlauncher/ui/screen/collection_page.dart';
import 'package:rpmlauncher/ui/theme/launcher_theme.dart';
import 'package:rpmlauncher/ui/theme/rpml_theme_type.dart';
import 'package:rpmlauncher/ui/widget/account_manage_button.dart';
import 'package:rpmlauncher/util/util.dart';

class RPMLAppBar extends StatefulWidget {
  const RPMLAppBar({Key? key}) : super(key: key);

  @override
  State<RPMLAppBar> createState() => _RPMLAppBarState();
}

class _RPMLAppBarState extends State<RPMLAppBar> {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(10), bottomRight: Radius.circular(10)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 80),
        child: Blur(
          blur: 100,
          blurColor: context.theme.backgroundColor,
          colorOpacity: 0.9,
          overlay: Row(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(15, 17, 11, 17),
                child: InkResponse(
                  borderRadius: BorderRadius.circular(5),
                  onTap: () {
                    Util.openUri('https://rpmtw.com');
                  },
                  child: SvgPicture.asset(
                    context.theme.type == RPMLThemeType.light
                        ? 'assets/images/rpmtw-logo-black.svg'
                        : 'assets/images/rpmtw-logo-white.svg',
                    height: 42,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 17),
                    child: TextField(
                      textAlignVertical: TextAlignVertical.bottom,
                      decoration: InputDecoration(
                        hintText: '想來搜尋點什麼......',
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5),
                          borderSide: BorderSide(
                              width: 2,
                              color: const Color(0XFF7D7D7D).withOpacity(0.2)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5),
                          borderSide: BorderSide(
                              width: 2,
                              color: const Color(0XFF7D7D7D).withOpacity(0.2)),
                        ),
                        suffixIcon: IconButton(
                          onPressed: () {},
                          tooltip: '搜尋',
                          icon: Icon(Icons.manage_search,
                              color: context.theme.textColor),
                        ),
                      ),
                    )),
              ),
              const SizedBox(width: 15),
              Wrap(
                spacing: 10,
                children: [
                  _ActionButton(
                    onPressed: () {},
                    text: '探索',
                    icon: Icon(Icons.explore_rounded,
                        color: context.theme.textColor),
                  ),
                  _ActionButton(
                    onPressed: () {},
                    text: '新聞',
                    icon: Icon(Icons.newspaper_rounded,
                        color: context.theme.textColor),
                  ),
                  _ActionButton(
                    onPressed: () {},
                    text: '下載',
                    icon: Icon(Icons.downloading_rounded,
                        color: context.theme.textColor),
                  ),
                  _ActionButton(
                    onPressed: () {
                      Navigator.of(context).pushNamed(CollectionPage.route);
                    },
                    text: '收藏庫',
                    icon: Icon(Icons.grid_view_rounded,
                        color: context.theme.textColor),
                  ),
                  _ActionButton(
                    onPressed: () {},
                    icon: Icon(Icons.segment_rounded,
                        color: context.theme.textColor),
                  ),
                ],
              ),
              const SizedBox(
                  width: 55,
                  height: 55,
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: AccountManageButton(),
                  ))
            ],
          ),
          child: Container(),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String? text;
  final Widget icon;
  final VoidCallback onPressed;

  const _ActionButton({
    this.text,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 45,
      child: ElevatedButton(
        onPressed: () => onPressed(),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0XFF7B7B7B).withOpacity(0.2),
          shadowColor: Colors.transparent,
          foregroundColor: const Color(0XFF7B7B7B).withOpacity(0.2),
          surfaceTintColor: const Color(0XFF7B7B7B).withOpacity(0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        child: Row(
          children: [
            icon,
            if (text != null) const SizedBox(width: 5),
            if (text != null)
              Text(text!, style: TextStyle(color: context.theme.textColor)),
          ],
        ),
      ),
    );
  }
}
