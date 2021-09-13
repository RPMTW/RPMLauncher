import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:rpmlauncher/Launcher/APIs.dart';
import 'package:rpmlauncher/Utility/Loggger.dart';
import 'package:rpmlauncher/Utility/i18n.dart';
import 'package:rpmlauncher/Utility/utility.dart';
import 'package:http_parser/http_parser.dart';
import 'package:rpmlauncher/main.dart';

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

  static Future<bool> UpdateSkin(
      String AccessToken, File file, String variant) async {
    variant = variant == i18n.Format('account.skin.variant.classic')
        ? 'classic'
        : variant;
    variant =
        variant == i18n.Format('account.skin.variant.slim') ? 'slim' : variant;

    String url = 'https://api.minecraftservices.com/minecraft/profile/skins';

    MultipartRequest request = http.MultipartRequest('PUT', Uri.parse(url))
      ..fields['variant'] = variant
      ..files.add(await http.MultipartFile.fromPath('file', file.absolute.path,
          contentType: MediaType('image', 'png')));

    StreamedResponse response = await request.send();

    bool Success = response.stream.bytesToString().toString().isNotEmpty;
    if (!Success) {
      logger.send(response.reasonPhrase);
    }

    return Success;
  }
}
