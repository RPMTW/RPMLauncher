import 'dart:convert';

import 'package:rpmlauncher/Launcher/APIs.dart';
import 'package:rpmlauncher/Utility/i18n.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';

class FTBHandler {
  static Future<List> getModPackList() async {
    final url = Uri.parse("$FTBModPackAPI/modpack/popular/installs/FTB/all");
    Response response = await get(url);
    Map body = json.decode(response.body);
    return body["packs"];
  }

  static Future<List<String>> getTags() async {
    final url = Uri.parse("$FTBModPackAPI/tag/popular/100");
    Response response = await get(url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'});
    Map body = json.decode(response.body);
    return body["tags"].cast<String>();
  }

  static Future<List<String>> getVersions() async {
    List<String> tags = await getTags();
    RegExp versionRegExp = RegExp(r"1[0-9]."); //開頭為 1 並且含有至少一個 . 則為版本標籤
    tags = tags.where((tag) => versionRegExp.hasMatch(tag)).toList();
    tags.sort((a, b) {
      int Aint = int.parse(a.replaceAll(".", ""));
      int Bint = int.parse(b.replaceAll('.', ''));

      return Bint.compareTo(Aint);
    });
    return tags;
  }

  static Future<Map> getVersionInfo(int modPackID, int versionID) async {
    final url = Uri.parse("$FTBModPackAPI/modpack/$modPackID/$versionID");
    Response response = await get(url);
    Map FileInfo = json.decode(response.body);
    return FileInfo;
  }

  static Text parseReleaseType(String releaseType) {
    late Text releaseTypeText;
    if (releaseType == "Release") {
      releaseTypeText = Text(I18n.format("edit.instance.mods.release"),
          style: TextStyle(color: Colors.lightGreen));
    } else if (releaseType == "Beta") {
      releaseTypeText = Text(I18n.format("edit.instance.mods.beta"),
          style: TextStyle(color: Colors.lightBlue));
    } else if (releaseType == "Alpha") {
      releaseTypeText = Text(I18n.format("edit.instance.mods.alpha"),
          style: TextStyle(color: Colors.red));
    } else {
      releaseTypeText = Text(releaseType, style: TextStyle(color: Colors.grey));
    }
    return releaseTypeText;
  }
}
