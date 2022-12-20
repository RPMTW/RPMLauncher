import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
    return Container(
      color: context.theme.mainColor.withOpacity(0.30),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 55),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: InkResponse(
                borderRadius: BorderRadius.circular(5),
                onTap: () {
                  Util.openUri("https://rpmtw.com");
                },
                child: SvgPicture.asset(
                  context.theme.type == RPMLThemeType.light
                      ? 'assets/images/rpmtw-logo-black.svg'
                      : 'assets/images/rpmtw-logo-white.svg',
                  height: 50,
                ),
              ),
            ),
            Expanded(
                child: TextField(
              decoration: InputDecoration(
                hintText: '搜尋點東西...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5),
                  borderSide: BorderSide.none,
                ),
              ),
            )),
            const SizedBox(width: 15),
            IconButton(
              onPressed: () {},
              tooltip: '搜尋',
              icon: Icon(Icons.search, color: context.theme.textColor),
            ),
            IconButton(
              onPressed: () {},
              tooltip: '收藏庫',
              icon:
                  Icon(Icons.widgets_outlined, color: context.theme.textColor),
            ),
            IconButton(
              onPressed: () {},
              tooltip: '設定',
              icon:
                  Icon(Icons.settings_outlined, color: context.theme.textColor),
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
      ),
    );
  }
}
