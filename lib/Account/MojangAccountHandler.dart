import 'dart:convert';
import 'dart:io';

import 'package:rpmlauncher/Launcher/APIs.dart';
import 'package:rpmlauncher/Utility/utility.dart';

class MojangHandler {
/*
API Docs: https://wiki.vg/Authentication
*/

  static Future<dynamic> LogIn(Username, Password) async {
    /*
    The clientToken should be a randomly generated identifier and must be identical for each request.
    The vanilla launcher generates a random (version 4) UUID on first run and saves it, reusing it for every subsequent request.
    In case it is omitted the server will generate a random token based on Java's UUID.toString() which should then be stored by the client.
    This will however also invalidate all previously acquired accessTokens for this user across all clients.
    */

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
    Refreshes a valid accessToken. It can be used to keep a user logged in between gaming sessions and is preferred over storing the user's password in a file (see lastlogin).
    */

    String url = '${MojangAuthAPI}/validate';
    Map map = {"accessToken": AccessToken, "requestUser": true};

    Map body = await jsonDecode(await utility.apiRequest(url, map));
    if (body.containsKey("error")) {
      return body["error"];
    }
    return body;
  }
}
