import 'dart:ffi';

import 'package:RPMLauncher/Launcher/Forge/ForgeAPI.dart';
import 'package:path/path.dart';

import '../../path.dart';
import '../MinecraftClient.dart';

class ForgeDatas {
  final List<ForgeData> forgeDatas;
  final List forgeDatakeys;

  const ForgeDatas({required this.forgeDatas, required this.forgeDatakeys});

  factory ForgeDatas.fromJson(Map json) {
    List lsit = json.keys.toList();
    List<ForgeData> forgeDatas_ = [];
    lsit.forEach((data) {
      forgeDatas_.add(ForgeData.fromJson(data));
    });
    return ForgeDatas(forgeDatas: forgeDatas_, forgeDatakeys: lsit);
  }

  List<ForgeData> toList() => forgeDatas;

  int getIndex(String DataName) => forgeDatakeys.indexOf(DataName);
}

class ForgeData {
  final String Client;
  final String Server;

  const ForgeData({
    required this.Client,
    required this.Server,
  });

  factory ForgeData.fromJson(Map json) =>
      ForgeData(Client: json['client'], Server: json['server']);

  Map<String, dynamic> toJson() => {'client': Client, 'server': Server};

  Future<void> DownloadData(MinecraftClientHandler Handler, SetState_, String ForgeVersionID) async {
    final url = ForgeAPI.ParseMaven(Client); //目前我們僅支援客戶端安裝
    final List split_ = url.split("/");
    final FileName = split_[split_.length - 1];
    Handler.DownloadFile(
        url,
        FileName,
        join(
          dataHome.absolute.path,
          "temp",
          "forge-installer",
          ForgeVersionID,
          "datas",
        ),
        '', //由於Forge沒提供Sha1，因此無法核對雜湊值
        SetState_);
  }
}
