import 'dart:io';
import 'package:http/http.dart';
import 'dart:convert';
import 'dart:core';
import 'package:args/args.dart';

void main(List<String> args) async {
  File UpdateJson = File("update.json");
  UpdateJson.createSync(recursive: true);

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
  String version_id = results.rest[1];
  String type = results.rest[2];
  String changelog = results.rest[3];

  if (!updateJson['version_list'].containsKey(version)) {
    updateJson['version_list'][version] = {};
  }

  String baseUrl =
      "https://github.com/RPMTW/RPMLauncher/releases/download/$version.$version_id";

  updateJson['version_list'][version][version_id] = {
    "download_url": {
      "windows_7": "$baseUrl/RPMLauncher-$version_id-windows_7.zip",
      "windows_10_11": "$baseUrl/RPMLauncher-$version_id-windows_10_11.zip",
      "linux": "$baseUrl/RPMLauncher-$version_id-linux.zip",
      "macos": "$baseUrl/RPMLauncher-$version_id-macos.zip"
    },
    "changelog": changelog,
    "type": type
  };

  updateJson[type]['latest_version'] = version;
  updateJson[type]['latest_version_code'] = version_id;

  UpdateJson.writeAsStringSync(json.encode(updateJson));
}
