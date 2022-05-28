import 'package:flutter/material.dart';
import 'package:rpmlauncher/model/account/Account.dart';
import 'package:rpmlauncher/screen/Account.dart';
import 'package:rpmlauncher/util/I18n.dart';

class AccountManageButton extends StatelessWidget {
  const AccountManageButton({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Account? currentAccount = AccountStorage().getDefault();

    if (AccountStorage().hasAccount) {
      return Tooltip(
        message: I18n.format("account.title"),
        child: InkResponse(
          radius: 40,
          highlightShape: BoxShape.rectangle,
          borderRadius: const BorderRadius.all(Radius.circular(30)),
          child: Row(
            children: [
              SizedBox(
                  width: 30, height: 30, child: currentAccount!.imageWidget),
              const SizedBox(
                width: 5,
              ),
              Text(currentAccount.username),
              const SizedBox(
                width: 10,
              ),
            ],
          ),
          onTap: () => AccountScreen.push(context),
        ),
      );
    } else {
      return IconButton(
        icon: const Icon(Icons.manage_accounts),
        onPressed: () {
          AccountScreen.push(context);
        },
        tooltip: I18n.format("account.title"),
      );
    }
  }
}
