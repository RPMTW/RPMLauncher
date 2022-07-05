import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart';
import 'package:rpmlauncher/account/mojang_account_handler.dart';
import 'package:rpmlauncher/launcher/GameRepository.dart';
import 'package:rpmlauncher/model/account/Account.dart';
import 'package:rpmlauncher/route/PushTransitions.dart';
import 'package:rpmlauncher/screen/home_page.dart';
import 'package:rpmlauncher/util/I18n.dart';
import 'package:rpmlauncher/widget/dialog/CheckDialog.dart';
import 'package:flutter/material.dart';
import 'package:rpmlauncher/widget/rpmtw_design/OkClose.dart';
import 'package:rpmlauncher/widget/RWLLoading.dart';
import 'package:rpmlauncher/util/launcher_path.dart';

import 'package:rpmlauncher/util/data.dart';
import 'package:rpmtw_dart_common_library/rpmtw_dart_common_library.dart';
import 'MSOauth2Login.dart';
import 'MojangAccount.dart';

class _AccountScreenState extends State<AccountScreen> {
  int? chooseIndex;

  @override
  void initState() {
    chooseIndex = AccountStorage().getIndex();
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
        title: Text(I18n.format("account.title")),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: I18n.format("gui.back"),
          onPressed: () {
            navigator
                .push(PushTransitions(builder: (context) => const HomePage()));
          },
        ),
      ),
      body: Container(
          height: double.infinity,
          width: double.infinity,
          alignment: Alignment.center,
          child: Column(children: [
            const SizedBox(
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
            const SizedBox(
              height: 10,
            ),
            ElevatedButton(
                style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(Colors.green)),
                onPressed: () {
                  showDialog(
                      context: context,
                      builder: (context) => const MojangAccount());
                },
                child: Text(
                  I18n.format("account.add.mojang.title"),
                  textAlign: TextAlign.center,
                  style: title_,
                )),
            Text(
              "\n${I18n.format("account.minecraft.title")}\n",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 25.0,
              ),
            ),
            Expanded(
              child: Builder(
                builder: (context) {
                  if (AccountStorage().hasAccount) {
                    return ListView.builder(
                      itemBuilder: (context, index) {
                        Account account = AccountStorage().getByIndex(index);
                        return ListTile(
                            tileColor: chooseIndex == index
                                ? Colors.black12
                                : Theme.of(context).scaffoldBackgroundColor,
                            onTap: () {
                              chooseIndex = index;
                              AccountStorage().setIndex(index);
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
                            leading: account.imageWidget,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.contact_page),
                                  tooltip: I18n.format("account.skin.tooltip"),
                                  onPressed: () {
                                    showDialog(
                                        context: context,
                                        builder: (context) {
                                          return _UploadSkinDialog(
                                              account: account);
                                        });
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
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
                                              onPressedOK: (context) {
                                                Navigator.of(context).pop();
                                                AccountStorage()
                                                    .removeByIndex(index);
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
                      itemCount: AccountStorage().getCount(),
                    );
                  } else {
                    return I18nText("account.delete.notfound",
                        style: const TextStyle(fontSize: 30));
                  }
                },
              ),
            ),
          ])),
    );
  }
}

class _UploadSkinDialog extends StatefulWidget {
  const _UploadSkinDialog({
    Key? key,
    required this.account,
  }) : super(key: key);

  final Account account;

  @override
  State<_UploadSkinDialog> createState() => _UploadSkinDialogState();
}

class _UploadSkinDialogState extends State<_UploadSkinDialog> {
  final List<String> skinTypeItems = [
    I18n.format('account.skin.variant.classic'),
    I18n.format('account.skin.variant.slim')
  ];
  late String skinTypeItem;

  @override
  void initState() {
    skinTypeItem = skinTypeItems.first;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(I18n.format('gui.tips.info'), textAlign: TextAlign.center),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          I18nText("account.skin.tips", textAlign: TextAlign.center),
          DropdownButton<String>(
            value: skinTypeItem,
            onChanged: (String? newValue) {
              skinTypeItem = newValue!;
              setState(() {});
            },
            items: skinTypeItems.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
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
              final FilePickerResult? result =
                  await FilePicker.platform.pickFiles(type: FileType.image);

              if (result != null) {
                PlatformFile file = result.files.single;

                if (!mounted) return;
                Navigator.pop(context);
                showDialog(
                    context: context,
                    builder: (context) {
                      return FutureBuilder(
                          future: MojangHandler.updateSkin(
                              widget.account.accessToken,
                              File(file.path!),
                              skinTypeItem),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              if (snapshot.data == true) {
                                return AlertDialog(
                                  title: Text(I18n.format('gui.tips.info')),
                                  content: I18nText('account.upload.success'),
                                  actions: const [OkClose()],
                                );
                              } else {
                                return AlertDialog(
                                  title: I18nText('gui.error.info'),
                                  content: I18nText('account.upload.success'),
                                  actions: const [OkClose()],
                                );
                              }
                            } else {
                              return AlertDialog(
                                title: I18nText("account.upload.uploading"),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
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
            child: I18nText("account.skin.file.select")),
      ],
    );
  }
}

class AccountScreen extends StatefulWidget {
  static const String route = "/account";
  static Future<void> push(BuildContext context) {
    return Navigator.of(context).pushNamed(route);
  }

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}
