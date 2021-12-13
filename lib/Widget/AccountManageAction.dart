import 'package:flutter/material.dart';
import 'package:rpmlauncher/Model/Account/Account.dart';
import 'package:rpmlauncher/Screen/Account.dart';
import 'package:rpmlauncher/Utility/I18n.dart';

class AccountManageButton extends StatelessWidget {
  const AccountManageButton({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Account? currentAccount = Account.getDefault();

    if (Account.hasAccount) {
      return Tooltip(
        message: I18n.format("account.title"),
        child: InkResponse(
          radius: 40,
          highlightShape: BoxShape.rectangle,
          borderRadius: BorderRadius.all(Radius.circular(30)),
          child: Row(
            children: [
              SizedBox(
                  width: 30, height: 30, child: currentAccount!.imageWidget),
              SizedBox(
                width: 5,
              ),
              Text(currentAccount.username),
              SizedBox(
                width: 10,
              ),
            ],
          ),
          onTap: () => AccountScreen.push(context),
        ),
      );
    } else {
      return IconButton(
        icon: Icon(Icons.manage_accounts),
        onPressed: () {
          AccountScreen.push(context);
        },
        tooltip: I18n.format("account.title"),
      );
    }
  }
}
