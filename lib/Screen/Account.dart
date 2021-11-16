import 'dart:io';

import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';
import 'package:path/path.dart';
import 'package:rpmlauncher/Account/MojangAccountHandler.dart';
import 'package:rpmlauncher/Launcher/GameRepository.dart';
import 'package:rpmlauncher/Model/Game/Account.dart';
import 'package:rpmlauncher/Utility/Extensions.dart';
import 'package:rpmlauncher/Utility/I18n.dart';
import 'package:rpmlauncher/Widget/Dialog/CheckDialog.dart';
import 'package:flutter/material.dart';
import 'package:rpmlauncher/Widget/OkClose.dart';
import 'package:rpmlauncher/Widget/RWLLoading.dart';
import 'package:rpmlauncher/Utility/RPMPath.dart';

import '../main.dart';
import 'MSOauth2Login.dart';
import 'MojangAccount.dart';

class _AccountScreenState extends State<AccountScreen> {
  late int chooseIndex = -1;

  @override
  void initState() {
    chooseIndex = Account.getIndex();
    super.initState();
    RPMPath.currentConfigHome.watch(recursive: true).listen((event) {
      if (absolute(event.path) ==
          absolute(GameRepository.getAccountFile().path)) {
        Account.updateAccountData();
      }
      if (mounted) {
        setState(() {});
      }
    });
  }

  String skinTypeItem = I18n.format('account.skin.variant.classic');
  List<String> skinTypeItems = [
    I18n.format('account.skin.variant.classic'),
    I18n.format('account.skin.variant.slim')
  ];

  var title_ = TextStyle(
    fontSize: 20.0,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(I18n.format("account.title")),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          tooltip: I18n.format("gui.back"),
          onPressed: () {
            navigator.push(PushTransitions(builder: (context) => HomePage()));
          },
        ),
      ),
      body: Container(
          height: double.infinity,
          width: double.infinity,
          alignment: Alignment.center,
          child: Column(children: [
            SizedBox(
              height: 10,
            ),
            ElevatedButton(
              style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(Colors.green)),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => MSLoginWidget(),
                );
              },
              child: Text(
                I18n.format("account.add.microsoft.title"),
                textAlign: TextAlign.center,
                style: title_,
              ),
            ),
            SizedBox(
              height: 10,
            ),
            ElevatedButton(
                style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(Colors.green)),
                onPressed: () {
                  showDialog(
                      context: context, builder: (context) => MojangAccount());
                },
                child: Text(
                  I18n.format("account.add.mojang.title"),
                  textAlign: TextAlign.center,
                  style: title_,
                )),
            Text(
              "\n${I18n.format("account.minecraft.title")}\n",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 25.0,
              ),
            ),
            Expanded(
              child: Builder(
                builder: (context) {
                  if (Account.getCount() != 0) {
                    return ListView.builder(
                      itemBuilder: (context, index) {
                        Account account = Account.getByIndex(index);
                        return ListTile(
                            tileColor: chooseIndex == index
                                ? Colors.black12
                                : Theme.of(context).scaffoldBackgroundColor,
                            onTap: () {
                              chooseIndex = index;
                              Account.setIndex(index);
                              if (mounted) {
                                setState(() {});
                              }
                            },
                            title: Text(account.username,
                                textAlign: TextAlign.center),
                            subtitle: I18nText("account.type",
                                args: {
                                  "account_type":
                                      account.type.name.toCapitalized()
                                },
                                textAlign: TextAlign.center),
                            leading: Image.network(
                              'https://minotar.net/helm/${account.uuid}/40.png',
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes !=
                                          null
                                      ? loadingProgress.cumulativeBytesLoaded
                                              .toInt() /
                                          loadingProgress.expectedTotalBytes!
                                              .toInt()
                                      : null,
                                );
                              },
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.contact_page),
                                  tooltip: I18n.format("account.skin.tooltip"),
                                  onPressed: () {
                                    showDialog(
                                        context: context,
                                        builder: (context) {
                                          return StatefulBuilder(
                                              builder: (context, _setstate) {
                                            return AlertDialog(
                                              title: Text(
                                                  I18n.format('gui.tips.info'),
                                                  textAlign: TextAlign.center),
                                              content: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  I18nText("account.skin.tips",
                                                      textAlign:
                                                          TextAlign.center),
                                                  DropdownButton<String>(
                                                    value: skinTypeItem,
                                                    onChanged:
                                                        (String? newValue) {
                                                      skinTypeItem = newValue!;
                                                      _setstate(() {});
                                                    },
                                                    items: skinTypeItems.map<
                                                            DropdownMenuItem<
                                                                String>>(
                                                        (String value) {
                                                      return DropdownMenuItem<
                                                          String>(
                                                        value: value,
                                                        child: Text(
                                                          value,
                                                        ),
                                                      );
                                                    }).toList(),
                                                  ),
                                                ],
                                              ),
                                              actions: [
                                                TextButton(
                                                    onPressed: () async {
                                                      final XFile? file =
                                                          await FileSelectorPlatform
                                                              .instance
                                                              .openFile(
                                                                  acceptedTypeGroups: [
                                                            XTypeGroup(
                                                                label: I18n.format(
                                                                    'account.skin.file.png'),
                                                                extensions: [
                                                                  'png',
                                                                ])
                                                          ]);

                                                      if (file != null) {
                                                        Navigator.pop(context);
                                                        showDialog(
                                                            context: context,
                                                            builder: (context) {
                                                              return FutureBuilder(
                                                                  future: MojangHandler.updateSkin(
                                                                      account
                                                                          .accessToken,
                                                                      File(file
                                                                          .path),
                                                                      skinTypeItem),
                                                                  builder: (context,
                                                                      snapshot) {
                                                                    if (snapshot
                                                                        .hasData) {
                                                                      if (snapshot
                                                                              .data ==
                                                                          true) {
                                                                        return AlertDialog(
                                                                          title:
                                                                              Text(I18n.format('gui.tips.info')),
                                                                          content:
                                                                              I18nText('account.upload.success'),
                                                                          actions: [
                                                                            OkClose()
                                                                          ],
                                                                        );
                                                                      } else {
                                                                        return AlertDialog(
                                                                          title:
                                                                              I18nText('gui.error.info'),
                                                                          content:
                                                                              I18nText('account.upload.success'),
                                                                          actions: [
                                                                            OkClose()
                                                                          ],
                                                                        );
                                                                      }
                                                                    } else {
                                                                      return AlertDialog(
                                                                        title: I18nText(
                                                                            "account.upload.uploading"),
                                                                        content:
                                                                            Column(
                                                                          mainAxisSize:
                                                                              MainAxisSize.min,
                                                                          children: [
                                                                            SizedBox(
                                                                              height: 10,
                                                                            ),
                                                                            RWLLoading(),
                                                                            SizedBox(
                                                                              height: 10,
                                                                            ),
                                                                          ],
                                                                        ),
                                                                      );
                                                                    }
                                                                  });
                                                            });
                                                      }
                                                    },
                                                    child: I18nText(
                                                        "account.skin.file.select")),
                                              ],
                                            );
                                          });
                                        });
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete),
                                  tooltip:
                                      I18n.format("account.delete.tooltip"),
                                  onPressed: () {
                                    showDialog(
                                        context: context,
                                        builder: (context) {
                                          return CheckDialog(
                                              title: I18n.format(
                                                  "account.delete.tooltip"),
                                              message: I18n.format(
                                                  'account.delete.content'),
                                              onPressedOK: () {
                                                Navigator.of(context).pop();
                                                Account.removeByIndex(index);
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
                      itemCount: Account.getCount(),
                    );
                  } else {
                    return I18nText("account.delete.notfound",
                        style: TextStyle(fontSize: 30));
                  }
                },
              ),
            ),
          ])),
    );
  }
}

class AccountScreen extends StatefulWidget {
  static const String route = "/account";

  @override
  _AccountScreenState createState() => _AccountScreenState();
}
