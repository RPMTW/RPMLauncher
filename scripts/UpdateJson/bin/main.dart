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
  parser.addFlag('build_id');
  parser.addFlag('type');
  parser.addFlag('changelog');

  var results = parser.parse(args);

  String version = results.rest[0];
  String buildID = results.rest[1];
  String type = results.rest[2];
  String changelog = results.rest[3];

  if (!updateJson['version_list'].containsKey(version)) {
    updateJson['version_list'][version] = {};
  }

  String baseUrl =
      "https://github.com/RPMTW/RPMLauncher/releases/download/$version+$buildID";

  updateJson['version_list'][version][buildID] = {
    "download_url": {
      "windows": "$baseUrl/RPMLauncher-Windows-Installer.exe",
      "linux": "$baseUrl/RPMLauncher-Linux.zip",
      "linux-appimage": "$baseUrl/RPMLauncher-Linux.AppImage",
      "macos": "$baseUrl/RPMLauncher-MacOS-Installer.dmg"
    },
    "changelog": changelog,
    "type": type
  };

  updateJson[type]['latest_version'] = version;
  updateJson[type]['latest_build_id'] = buildID;
  updateJson[type]['latest_version_full'] = "$version+$buildID";

  updateJsonFile.writeAsStringSync(json.encode(updateJson));
}
