import 'dart:convert';
import 'dart:html';

import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:rpmlauncher/MCLauncher/APIs.dart';

class FabricInstaller {
  Future<bool> IsCompatibleVersion(VersionID) async {
    final url = Uri.parse(
        "${APis().FabricApi}/versions/loader/1.17/0.11.6/profile/json");
    Response response = await get(url);
    Map<String, dynamic> body = jsonDecode(response.body);
    return true;
  }
}
