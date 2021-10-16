import 'dart:io';

import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';
import 'package:rpmlauncher/Account/MojangAccountHandler.dart';
import 'package:rpmlauncher/Model/Account.dart';
import 'package:rpmlauncher/Utility/Extensions.dart';
import 'package:rpmlauncher/Utility/i18n.dart';
import 'package:rpmlauncher/Widget/CheckDialog.dart';
import 'package:flutter/material.dart';
import 'package:rpmlauncher/Widget/OkClose.dart';
import 'package:rpmlauncher/Widget/RWLLoading.dart';

import '../main.dart';
import 'MSOauth2Login.dart';
import 'MojangAccount.dart';

class _AccountScreenState extends State<AccountScreen> {
  late int chooseIndex = -1;

  @override
  void initState() {
    chooseIndex = Account.getIndex();
    super.initState();
    setState(() {});
  }

  String skinTypeItem = i18n.format('account.skin.variant.classic');
  List<String> skinTypeItems = [
    i18n.format('account.skin.variant.classic'),
    i18n.format('account.skin.variant.slim')
  ];

  var title_ = TextStyle(
    fontSize: 20.0,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(i18n.format("account.title")),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          tooltip: i18n.format("gui.back"),
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
                i18n.format("account.add.microsoft.title"),
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
                  i18n.format("account.add.mojang.title"),
                  textAlign: TextAlign.center,
                  style: title_,
                )),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "\n${i18n.format("account.minecraft.title")}\n",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 25.0,
                  ),
                ),
                SizedBox(
                  width: 20,
                ),
                ElevatedButton(
                    onPressed: () {
                      setState(() {});
                    },
                    child: Text(
                      "重新載入帳號",
                      textAlign: TextAlign.center,
                      style: title_,
                    )),
              ],
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
                              setState(() {});
                            },
                            title: Text(account.username,
                                textAlign: TextAlign.center),
                            subtitle: i18nText("account.type",
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
                                  tooltip: "更換Skin",
                                  onPressed: () {
                                    showDialog(
                                        context: context,
                                        builder: (context) {
                                          return StatefulBuilder(
                                              builder: (context, _setstate) {
                                            return AlertDialog(
                                              title: Text(
                                                  i18n.format('gui.tips.info'),
                                                  textAlign: TextAlign.center),
                                              content: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text("請選擇要上傳的Skin檔案與Skin類型",
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
                                                                label:
                                                                    "可攜式網路圖形",
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
                                                                  future: MojangHandler.UpdateSkin(
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
                                                                              Text(i18n.format('gui.tips.info')),
                                                                          content:
                                                                              Text("上傳成功"),
                                                                          actions: [
                                                                            OkClose()
                                                                          ],
                                                                        );
                                                                      } else {
                                                                        return AlertDialog(
                                                                          title:
                                                                              Text(i18n.format('gui.error.info')),
                                                                          content:
                                                                              Text("上傳失敗"),
                                                                          actions: [
                                                                            OkClose()
                                                                          ],
                                                                        );
                                                                      }
                                                                    } else {
                                                                      return AlertDialog(
                                                                        title: Text(
                                                                            "正在上傳Skin中..."),
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
                                                    child: Text("選擇檔案")),
                                              ],
                                            );
                                          });
                                        });
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete),
                                  tooltip: "刪除帳號",
                                  onPressed: () {
                                    showDialog(
                                        context: context,
                                        builder: (context) {
                                          return CheckDialog(
                                              title: "刪除帳號",
                                              content: "您確定要刪除此帳號嗎？ (此動作將無法復原)",
                                              onPressedOK: () {
                                                Navigator.of(context).pop();
                                                Account.removeByIndex(index);
                                                setState(() {});
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
                    return Text("找不到帳號", style: TextStyle(fontSize: 30));
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
