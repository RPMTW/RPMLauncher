import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:rpmlauncher/Launcher/APIs.dart';
import 'package:rpmlauncher/Utility/I18n.dart';
import 'package:rpmlauncher/Utility/Utility.dart';
import 'package:http_parser/http_parser.dart';
import 'package:rpmlauncher/main.dart';

class MojangHandler {
/*
API Docs: https://wiki.vg/Authentication
*/

  static Future<dynamic> logIn(String username, String password) async {
    /*
    The clientToken should be a randomly generated identifier and must be identical for each request.
    The vanilla launcher generates a random (version 4) UUID on first run and saves it, reusing it for every subsequent request.
    In case it is omitted the server will generate a random token based on Java's UUID.toString() which should then be stored by the client.
    This will however also invalidate all previously acquired accessTokens for this user across all clients.
    */

    String url = '$mojangAuthAPI/authenticate';
    Map map = {
      'agent': {'name': 'Minecraft', "version": 1},
      "username": username,
      "password": password,
      "requestUser": true
    };
    Map body = await jsonDecode(await Uttily.apiRequest(url, map));
    if (body.containsKey("error")) {
      return body["error"];
    }
    return body;
  }

  static Future<bool> validate(String accessToken) async {
    /*
    Returns an empty payload (204 No Content) if successful, an error JSON with status 403 Forbidden otherwise.
    */

    String url = '$mojangAuthAPI/validate';
    Map map = {
      "accessToken": accessToken,
    };
    HttpClient httpClient = HttpClient();
    HttpClientRequest request = await httpClient.postUrl(Uri.parse(url));
    request.headers.add('Content-Type', 'application/json');
    request.headers.add('Accept', 'application/json');
    request.add(utf8.encode(json.encode(map)));
    HttpClientResponse response = await request.close();
    int statusCode = response.statusCode;
    httpClient.close();

    return statusCode == 204;
  }

  static Future<Map> refresh(accessToken) async {
    /*
    Refreshes a valid accessToken. It can be used to keep a user logged in between gaming sessions and is preferred over storing the user's password in a file (see lastlogin).
    */

    String url = '$mojangAuthAPI/validate';
    Map map = {"accessToken": accessToken, "requestUser": true};

    Map body = await jsonDecode(await Uttily.apiRequest(url, map));
    if (body.containsKey("error")) {
      return body["error"];
    }
    return body;
  }

  static Future<bool> updateSkin(
      String accessToken, File file, String variant) async {
    variant = variant == I18n.format('account.skin.variant.classic')
        ? 'classic'
        : variant;
    variant =
        variant == I18n.format('account.skin.variant.slim') ? 'slim' : variant;

    String url = 'https://api.minecraftservices.com/minecraft/profile/skins';

    MultipartRequest request = http.MultipartRequest('PUT', Uri.parse(url))
      ..fields['variant'] = variant
      ..files.add(await http.MultipartFile.fromPath('file', file.absolute.path,
          contentType: MediaType('image', 'png')));

    StreamedResponse response = await request.send();

    bool success = response.stream.bytesToString().toString().isNotEmpty;
    if (!success) {
      logger.send(response.reasonPhrase);
    }

    return success;
  }
}
