import 'dart:convert';
import 'dart:io' as io;

import 'package:flutter/material.dart';
import 'package:path/path.dart';
import '../path.dart';

import '../main.dart';
import 'MicrosoftAccount.dart';
import 'MojangAccount.dart';

var java_path;

class AccountScreen_ extends State<AccountScreen> {
  late io.Directory AccountFolder;
  late io.File AccountFile;
  late Map Account;
  late io.Directory ConfigFolder;
  late io.File ConfigFile;
  late Map config;
  late int choose_index;
  @override
  void initState() {
    choose_index = -1;
    ConfigFolder = configHome;
    ConfigFile =
        io.File(join(ConfigFolder.absolute.path, "RPMLauncher", "config.json"));
    config = json.decode(ConfigFile.readAsStringSync());
    AccountFolder = configHome;
    AccountFile = io.File(
        join(AccountFolder.absolute.path, "RPMLauncher", "accounts.json"));
    Account = json.decode(AccountFile.readAsStringSync());
    if (Account["mojang"] == null) {
      Account["mojang"] = [];
    }
    if (config.containsKey("account_index")) {
      choose_index= config["account_index"];
    }
    super.initState();
    setState(() {});
  }

  void _onItemTapped(int index) {
    setState(() {
      var _selectedIndex = index;
    });
  }

  @override
  var title_ = TextStyle(
    fontSize: 20.0,
  );


  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: AppBar(
        title: Text("管理Minecraft帳號"),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          tooltip: '返回',
          onPressed: () {
            ConfigFile.writeAsStringSync(json.encode(config));
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => new MyApp()),
            );
          },
        ),
      ),
      body: Container(
          height: double.infinity,
          width: double.infinity,
          alignment: Alignment.center,
          child: Column(children: [
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
              ),
            ),
            Expanded(
              child: Builder(
                builder: (context) {
                  print(Account);
                  if (Account.isNotEmpty) {
                    return ListView.builder(
                      itemBuilder: (context, index) {
                        return ListTile(
                          tileColor: choose_index == index
                              ? Colors.black12
                              : Theme.of(context).scaffoldBackgroundColor,
                          onTap: () {
                            choose_index = index;
                            config["account_index"]=choose_index;
                            setState(() {});
                          },
                          title: Center(
                            child: Text(Account["mojang"][index]
                                ["selectedProfile"]["name"]),
                          ),
                        );
                      },
                      itemCount: Account["mojang"].length,
                    );
                  } else {
                    return Container();
                  }
                },
              ),
            ),
          ])),
    );
  }
}

class AccountScreen extends StatefulWidget {
  @override
  AccountScreen_ createState() => AccountScreen_();
}
