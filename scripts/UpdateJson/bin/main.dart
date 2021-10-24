import 'dart:io';
import 'package:http/http.dart';
import 'dart:convert';
import 'dart:core';
import 'package:args/args.dart';

void main(List<String> args) async {
  File updateJsonFile = File("update.json");
  updateJsonFile.createSync(recursive: true);

  Response response = await get(Uri.parse(
      "https://raw.githubusercontent.com/RPMTW/RPMTW-website-data/main/data/RPMLauncher/update.json"));

  Map updateJson = json.decode(response.body);

  var parser = ArgParser();

  parser.addFlag('version');
  parser.addFlag('version_id');
  parser.addFlag('type');
  parser.addFlag('changelog');

  var results = parser.parse(args);

  String version = results.rest[0];
  String versionId = results.rest[1];
  String type = results.rest[2];
  String changelog = results.rest[3];

  if (!updateJson['version_list'].containsKey(version)) {
    updateJson['version_list'][version] = {};
  }

  String baseUrl =
      "https://github.com/RPMTW/RPMLauncher/releases/download/$version.$versionId";

  updateJson['version_list'][version][versionId] = {
    "download_url": {
      "windows_7": "$baseUrl/RPMLauncher-Windows7.zip",
      "windows_10_11": "$baseUrl/Installer - 點我安裝.exe",
      "linux": "$baseUrl/RPMLauncher-Linux.zip",
      "macos": "$baseUrl/rpmlauncher.tar.bz2"
    },
    "changelog": changelog,
    "type": type
  };

  updateJson[type]['latest_version'] = version;
  updateJson[type]['latest_version_code'] = versionId;
  updateJson[type]['latest_version_full'] = "$version.$versionId";

  updateJsonFile.writeAsStringSync(json.encode(updateJson));
}
