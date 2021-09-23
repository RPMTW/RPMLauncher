import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:rpmlauncher/Launcher/GameRepository.dart';
import 'package:rpmlauncher/Launcher/Libraries.dart';
import 'package:archive/archive.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:path/path.dart';
import 'package:rpmlauncher/Utility/ModLoader.dart';
import 'package:rpmlauncher/Utility/i18n.dart';
import 'package:rpmlauncher/main.dart';

import 'Arguments.dart';
import 'CheckData.dart';

double Progress = 0.0;
String NowEvent = i18n.format('version.list.downloading.ready');
bool finish = false;

abstract class MinecraftClient {
  Map get Meta;

  MinecraftClientHandler get handler;

  get setState;
}

class MinecraftClientHandler {
  num DoneTaskLength = 0;
  num TotalTaskLength = 1;

  void ChangeProgress(setState_) {
    Progress = DoneTaskLength / TotalTaskLength;
    setState_(() {});
  }

  Future DownloadFile(
      String url, String filename, String path, fileSha1, SetState_) async {
    var dir_ = path;
    File file = await File(join(dir_, filename))
      ..createSync(recursive: true);
    if (CheckData().CheckSha1Sync(file, fileSha1)) {
      DoneTaskLength++;
      return;
    }
    ChangeProgress(SetState_);
    try {
      await http.get(Uri.parse(url)).then((response) async {
        await file.writeAsBytes(response.bodyBytes);
      });
    } catch (err) {
      logger.send(err);
    }
    DoneTaskLength++; //Download Done
    ChangeProgress(SetState_);
  }

  Future GetClientJar(body, VersionID, SetState_) async {
    DownloadFile(
        body["downloads"]["client"]["url"],
        "client.jar",
        join(dataHome.absolute.path, "versions", VersionID),
        body["downloads"]["client"]["sha1"],
        SetState_);
  }

  Future GetArgs(body, VersionID) async {
    File ArgsFile =
        File(join(dataHome.absolute.path, "versions", VersionID, "args.json"));
    await ArgsFile.create(recursive: true);
    await ArgsFile.writeAsString(
        json.encode(Arguments().GetArgsString(VersionID, body)));
  }

  Future DownloadAssets(data, version, SetState_) async {
    final url = Uri.parse(data["assetIndex"]["url"]);
    Response response = await get(url);
    Map<String, dynamic> body = json.decode(response.body);
    TotalTaskLength = TotalTaskLength + body["objects"].keys.length;
    File IndexFile = File(
        join(dataHome.absolute.path, "assets", "indexes", "${version}.json"))
      ..createSync(recursive: true);
    IndexFile.writeAsStringSync(response.body);
    for (var i in body["objects"].keys) {
      String hash = body["objects"][i]["hash"].toString();
      await DownloadFile(
              "https://resources.download.minecraft.net/${hash.substring(0, 2)}/${hash}",
              hash,
              join(dataHome.absolute.path, "assets", "objects",
                  hash.substring(0, 2)),
              hash,
              SetState_)
          .timeout(new Duration(milliseconds: 130), onTimeout: () {});
    }
  }

  Future DownloadLib(body, version, SetState_) async {
    Libraries.fromList(body['libraries']).libraries.forEach((lib) {
      if (lib.isnatives) {
        if (lib.downloads.classifiers != null) {
          TotalTaskLength++;
          DownloadNatives(lib.downloads.classifiers!, version, SetState_);
        }
        Artifact artifact = lib.downloads.artifact;
        TotalTaskLength++;
        List split_ = artifact.path.split("/");
        DownloadFile(
            artifact.url,
            split_[split_.length - 1],
            join(
                dataHome.absolute.path,
                "versions",
                version,
                "libraries",
                ModLoader().None,
                split_.sublist(0, split_.length - 2).join("/")),
            artifact.sha1,
            SetState_);
      }
    });
  }

  Future DownloadNatives(Classifiers classifiers, version, SetState_) async {
    List split_ = classifiers.path.split("/");
    await DownloadFile(
        classifiers.url,
        split_[split_.length - 1],
        GameRepository.getNativesDir(version).absolute.path,
        classifiers.sha1,
        SetState_);
    await UnZip(split_[split_.length - 1],
        GameRepository.getNativesDir(version).absolute.path);
  }

  Future UnZip(fileName, dir_) async {
    File file = new File(join(dir_, fileName));
    final bytes = await file.readAsBytesSync();
    final archive = await ZipDecoder().decodeBytes(bytes);
    for (final file in archive.files) {
      final FileName = file.name;
      if (FileName.contains("META-INF")) continue;
      if (file.isFile) {
        if (FileName.endsWith(".git") || FileName.endsWith(".sha1")) continue;
        final data = file.content as List<int>;
        await File(join(dir_, FileName))
          ..createSync(recursive: true)
          ..writeAsBytesSync(data);
      } else {
        await Directory(join(dir_, FileName))
          ..create(recursive: true);
      }
    }
    file.delete(recursive: true);
  }

  Future<MinecraftClientHandler> Install(Meta, VersionID, SetState) async {
    SetState(() {
      NowEvent = i18n.format('version.list.downloading.library');
    });
    await this.DownloadLib(Meta, VersionID, SetState);
    SetState(() {
      NowEvent = i18n.format('version.list.downloading.main');
    });
    await this.GetClientJar(Meta, VersionID, SetState);
    SetState(() {
      NowEvent = i18n.format('version.list.downloading.args');
    });
    await this.GetArgs(Meta, VersionID);
    SetState(() {
      NowEvent = i18n.format('version.list.downloading.assets');
    });
    await this.DownloadAssets(Meta, VersionID, SetState);
    return this;
  }
}
