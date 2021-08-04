import 'dart:convert';
import 'dart:io';

import 'package:rpmlauncher/MCLauncher/APIs.dart';
import 'package:rpmlauncher/Utility/utility.dart';

class MojangHandler{

  static Future<Map> LogIn(Username,Password) async {
    String url = '${MojangAuthAPI}/authenticate';
    Map map = {
      'agent': {'name': 'Minecraft', "version": 1},
      "username": Username,
      "password": Password,
      "requestUser": true
    };
    Map body = await jsonDecode(await utility.apiRequest(url, map));
    if (body.containsKey("error")) {
      return body["error"];
    }
    return body;
  }

  static Future<bool> Validate(AccessToken) async {
    /*
    API Docs: https://wiki.vg/Authentication
    Returns an empty payload (204 No Content) if successful, an error JSON with status 403 Forbidden otherwise.
     */

    String url = '${MojangAuthAPI}/validate';
    Map map = {
      "accessToken": AccessToken,
    };
    HttpClient httpClient = new HttpClient();
    HttpClientRequest request = await httpClient.postUrl(Uri.parse(url));
    request.headers.add('Content-Type', 'application/json');
    request.headers.add('Accept', 'application/json');
    request.add(utf8.encode(json.encode(map)));
    HttpClientResponse response = await request.close();
    var StatusCode = await response.statusCode;
    httpClient.close();

    return StatusCode == 204;
  }

  static Future<Map> Refresh(AccessToken) async {
    /*
    API Docs: https://wiki.vg/Authentication
    Refreshes a valid accessToken. It can be used to keep a user logged in between gaming sessions and is preferred over storing the user's password in a file (see lastlogin).
     */

    String url = '${MojangAuthAPI}/validate';
    Map map = {
      "accessToken": AccessToken,
      "requestUser": true
    };

    Map body = await jsonDecode(await utility.apiRequest(url, map));
    if (body.containsKey("error")) {
      return body["error"];
    }
    return body;
  }
}