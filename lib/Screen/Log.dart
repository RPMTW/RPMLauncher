import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart';

import '../parser.dart';
import '../path.dart';

class LogScreen_ extends State<LogScreen> {
  late var instance_folder;

  LogScreen_(instance_folder_) {
    instance_folder = instance_folder_;
  }

  var log_ = "";
  late Directory ConfigFolder;
  late File ConfigFile;
  late File AccountFile;
  late Map Account;
  late var cfg_file;
  late Directory InstanceDir;
  late ScrollController _scrollController;
  late var config;
  String log_text = "";

  void initState() {
    AccountFile = File(join(ConfigFolder.absolute.path, "accounts.json"));
    Account = json.decode(AccountFile.readAsStringSync());
    ConfigFolder = configHome;
    Directory LauncherFolder = dataHome;
    InstanceDir = Directory(join(LauncherFolder.absolute.path, "instances"));
    Directory AssetsDir =
        Directory(join(LauncherFolder.absolute.path, "assets"));
    cfg_file = CFG(File(join(
                InstanceDir.absolute.path, instance_folder, "instance.cfg"))
            .readAsStringSync())
        .GetParsed();
    ConfigFile = File(join(ConfigFolder.absolute.path, "config.json"));
    var args = jsonDecode(
        File(join(InstanceDir.absolute.path, instance_folder, "args.json"))
            .readAsStringSync());
    config = json.decode(ConfigFile.readAsStringSync());
    var auth_player_name = Account["mojang"][0]["availableProfiles"][0]["name"];
    var version_name = cfg_file["version"];
    _scrollController = new ScrollController(
      keepScrollOffset: true,
    );
    //log_=Process.start("/usr/lib/jvm/jre-16-openjdk/bin/java", ["-jar","/home/sunny/server/fabric-server-launch.jar"]).asStream();
    start(
        args,
        auth_player_name,
        version_name,
        join(InstanceDir.absolute.path, instance_folder),
        AssetsDir,
        Account["mojang"][0]["availableProfiles"][0]["uuid"],
        Account["mojang"][0]["accessToken"],
        Account.keys.first,
        join(InstanceDir.absolute.path, instance_folder, "natives"),
        File(join(ConfigFolder.absolute.path, "libraries")));
    super.initState();
    setState(() {});
  }

  start(
      args,
      auth_player_name,
      version_name,
      game_directory,
      assets_root,
      auth_uuid,
      auth_access_token,
      user_type,
      natives_directory,
      classpath) async {
    Directory.current = join(InstanceDir.absolute.path, instance_folder);
    var process = await Process.start("", []);

    await process.stdout.transform(utf8.decoder).listen((event) {
      log_ = log_ + event;
    });
    //process.stdout.pipe(print);
    const oneSec = const Duration(seconds: 1);
    new Timer.periodic(oneSec, (Timer t) => setState(() {}));
    print(await process.exitCode);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text("Instance log"),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
                child: SingleChildScrollView(
                    controller: _scrollController, child: Text(log_))),
          ],
        ));
  }
}

class LogScreen extends StatefulWidget {
  late var instance_folder;

  LogScreen(instance_folder_) {
    instance_folder = instance_folder_;
  }

  @override
  LogScreen_ createState() => LogScreen_(instance_folder);
}
