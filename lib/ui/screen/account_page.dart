import 'package:path/path.dart';
import 'package:rpmlauncher/launcher/game_repository.dart';
import 'package:rpmlauncher/model/account/account.dart';
import 'package:rpmlauncher/i18n/i18n.dart';
import 'package:rpmlauncher/ui/dialog/check_dialog.dart';
import 'package:flutter/material.dart';
import 'package:rpmlauncher/util/launcher_path.dart';

import 'package:rpmlauncher/util/data.dart';
import 'package:rpmtw_dart_common_library/rpmtw_dart_common_library.dart';
import 'ms_oauth_login.dart';

class _AccountScreenState extends State<AccountScreen> {
  int? chooseIndex;

  @override
  void initState() {
    chooseIndex = AccountStorage.getIndex();
    super.initState();
    LauncherPath.currentConfigHome.watch(recursive: true).listen((event) {
      if (absolute(event.path) ==
              absolute(GameRepository.getAccountFile().path) &&
          mounted) {
        setState(() {});
      }
    });
  }

  TextStyle title_ = const TextStyle(
    fontSize: 20.0,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(I18n.format('account.title')),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: I18n.format('gui.back'),
          onPressed: () {
            navigator.pop();
          },
        ),
      ),
      body: Container(
        height: double.infinity,
        width: double.infinity,
        alignment: Alignment.center,
        child: Builder(
          builder: (context) {
            if (AccountStorage.hasAccount) {
              return ListView.builder(
                itemBuilder: (context, index) {
                  final account = AccountStorage.getByIndex(index);

                  return ListTile(
                      tileColor: chooseIndex == index
                          ? Theme.of(context).colorScheme.onInverseSurface
                          : null,
                      onTap: () {
                        chooseIndex = index;
                        AccountStorage.setIndex(index);
                        if (mounted) {
                          setState(() {});
                        }
                      },
                      title:
                          Text(account.username, textAlign: TextAlign.center),
                      subtitle: I18nText('account.type',
                          args: {
                            'account_type': account.type.name.toCapitalized()
                          },
                          textAlign: TextAlign.center),
                      leading: SizedBox(
                          width: 50, height: 50, child: account.imageWidget),
                      minLeadingWidth: 50,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.contact_page),
                            tooltip: I18n.format('account.skin.tooltip'),
                            onPressed: () {},
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            tooltip: I18n.format('account.delete.tooltip'),
                            onPressed: () {
                              showDialog(
                                  context: context,
                                  builder: (context) {
                                    return CheckDialog(
                                        title: I18n.format(
                                            'account.delete.tooltip'),
                                        message: I18n.format(
                                            'account.delete.content'),
                                        onPressedOK: (context) {
                                          Navigator.of(context).pop();
                                          AccountStorage.removeByIndex(index);
                                          if (mounted) {
                                            setState(() {});
                                          }
                                        });
                                  });
                            },
                          ),
                        ],
                      ));
                },
                itemCount: AccountStorage.getCount(),
              );
            } else {
              return I18nText('account.delete.notfound',
                  style: const TextStyle(fontSize: 30));
            }
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const MSLoginWidget(),
          );
        },
        label: I18nText(
          'account.add.title',
          textAlign: TextAlign.center,
          style: title_,
        ),
      ),
    );
  }
}

class AccountScreen extends StatefulWidget {
  static const String route = '/account';

  const AccountScreen({super.key});

  static Future<void> push(BuildContext context) {
    return Navigator.of(context).pushNamed(route);
  }

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}
