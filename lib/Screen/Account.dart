import 'dart:convert';
import 'dart:io' as io;

import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:xdg_directories/xdg_directories.dart';

import '../main.dart';
import 'MicrosoftAccount.dart';
import 'MojangAccount.dart';

var java_path;

Future Account() async {
  late io.File AccountFile;
  late Map Account;

  AccountFile = io.File(
      join(configHome.absolute.path, "RPMLauncher", "accounts.json"));
  Account = await json.decode(AccountFile.readAsStringSync());
  if (Account["mojang"] == null) {
    Account["mojang"] = [];
  }
  return Account;
}

class AccountScreen_ extends State<AccountScreen> {
  int choose_index = 0;
  late Future AccountChoose;

  @override
  void initState() {
    AccountFolder = configHome;
    AccountFile = io.File(
        join(AccountFolder.absolute.path, "RPMLauncher", "accounts.json"));
    Account = json.decode(AccountFile.readAsStringSync());
    if (Account["mojang"] == null) {
      Account["mojang"] = [];
    }

    super.initState();
    setState(() {});
  }

  @override
  var title_ = TextStyle(
    fontSize: 20.0,
  );

  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text("管理Minecraft帳號"),
        centerTitle: true,
        leading: new IconButton(
          icon: new Icon(Icons.arrow_back),
          tooltip: '返回',
          onPressed: () {
            Navigator.push(
              context,
              new MaterialPageRoute(builder: (context) => new MyApp()),
            );
          },
        ),
      ),
      body: Container(
          height: double.infinity,
          width: double.infinity,
          alignment: Alignment.center,
          child: ListView(
            children: [
              Column(children: [
                Text(
                  "Mojang 帳號",
                  textAlign: TextAlign.center,
                  style: title_,
                ),
                TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        new MaterialPageRoute(
                            builder: (context) => MojangAccount()),
                      );
                    },
                    child: Text(
                      "新增 Mojang 帳號",
                      textAlign: TextAlign.center,
                      style: title_,
                    )),
                Builder(
                  builder: (context) {
                    print(Account);
                    if (Account.isNotEmpty&&Account["mojang"].length!=0) {
                      return ListView.builder(
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Account["mojang"][index]["user"]["username"],
                          );
                        },
                        itemCount: Account.length,
                      );
                    } else {
                      return Container();
                    }
                  },
                ),
                Text(
                  "\n\nMicrosoft 帳號",
                  textAlign: TextAlign.center,
                  style: title_,
                ),
                TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        new MaterialPageRoute(
                            builder: (context) => MicrosoftAccount()),
                      );
                    },
                    child: Text(
                      "新增 Microsoft 帳號",
                      textAlign: TextAlign.center,
                      style: title_,
                    )),
              ]),
            ],
          )),
    );
  }
}

class AccountScreen extends StatefulWidget {
  @override
  AccountScreen_ createState() => AccountScreen_();
}
