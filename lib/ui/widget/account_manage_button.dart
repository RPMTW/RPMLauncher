import 'package:flutter/material.dart';
import 'package:rpmlauncher/i18n/i18n.dart';
import 'package:rpmlauncher/model/account/account.dart';
import 'package:rpmlauncher/ui/pages/account_page.dart';
import 'package:rpmlauncher/ui/theme/launcher_theme.dart';

class AccountManageButton extends StatelessWidget {
  const AccountManageButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Account? currentAccount = AccountStorage.getDefault();

    if (AccountStorage.hasAccount) {
      return Tooltip(
        message: I18n.format('account.title'),
        child: InkResponse(
          borderRadius: BorderRadius.circular(30),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: currentAccount!.imageWidget,
          ),
          onTap: () => AccountScreen.push(context),
        ),
      );
    } else {
      return IconButton(
        icon: Icon(Icons.manage_accounts, color: context.theme.textColor),
        onPressed: () {
          AccountScreen.push(context);
        },
        tooltip: I18n.format('account.title'),
      );
    }
  }
}
