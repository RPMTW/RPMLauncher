import 'dart:convert';

import 'package:rpmlauncher/Launcher/APIs.dart';
import 'package:rpmlauncher/Utility/I18n.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:rpmlauncher/Utility/RPMHttpClient.dart';
import 'package:dio/dio.dart' as dio;

class FTBHandler {
  static Future<List> getModPackList() async {
    dio.Response response = await RPMHttpClient()
        .get("$ftbModPackAPI/modpack/popular/installs/FTB/all");
    Map body = RPMHttpClient.json(response.data);
    return body["packs"];
  }

  static Future<List<String>> getTags() async {
    dio.Response response = await RPMHttpClient().get(
      "$ftbModPackAPI/tag/popular/100",
    );
    Map body = RPMHttpClient.json(response.data);
    return body["tags"].cast<String>();
  }

  static Future<List<String>> getVersions() async {
    List<String> tags = await getTags();
    RegExp versionRegExp = RegExp(r"1[0-9]."); //開頭為 1 並且含有至少一個 . 則為版本標籤
    tags = tags.where((tag) => versionRegExp.hasMatch(tag)).toList();
    tags.sort((a, b) {
      int aint = int.parse(a.replaceAll(".", ""));
      int bint = int.parse(b.replaceAll('.', ''));

      return bint.compareTo(aint);
    });
    return tags;
  }

  static Future<Map> getVersionInfo(int modPackID, int versionID) async {
    final url = Uri.parse("$ftbModPackAPI/modpack/$modPackID/$versionID");
    Response response = await get(url);
    Map fileInfo = json.decode(response.body);
    return fileInfo;
  }

  static Text parseReleaseType(String releaseType) {
    late Text releaseTypeText;
    if (releaseType == "release") {
      releaseTypeText = Text(I18n.format("edit.instance.mods.release"),
          style: TextStyle(color: Colors.lightGreen));
    } else if (releaseType == "beta") {
      releaseTypeText = Text(I18n.format("edit.instance.mods.beta"),
          style: TextStyle(color: Colors.lightBlue));
    } else if (releaseType == "alpha") {
      releaseTypeText = Text(I18n.format("edit.instance.mods.alpha"),
          style: TextStyle(color: Colors.red));
    } else {
      releaseTypeText = Text(releaseType, style: TextStyle(color: Colors.grey));
    }
    return releaseTypeText;
  }

  static String getWebUrlFromName(String modPackName) {
    modPackName = modPackName.toLowerCase();
    List<String> source = modPackName.split("");
    List<String> output = [];
    final RegExp english = RegExp(r"^\w+$");
    source.forEach((e) {
      if (english.hasMatch(e)) {
        output.add(e);
      } else {
        output.add("_");
      }
    });
    return "https://feed-the-beast.com/modpack/" + output.join("");
  }
}
