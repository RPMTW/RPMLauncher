import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:rpmlauncher/i18n/i18n.dart';
import 'package:rpmlauncher/util/data.dart';
import 'package:rpmlauncher/util/logger.dart';

class MojangHandler {
/*
API Docs: https://wiki.vg/Authentication
*/

  static Future<bool> updateSkin(
      String accessToken, File file, String variant) async {
    variant = variant == I18n.format('account.skin.variant.classic')
        ? 'classic'
        : variant;
    variant =
        variant == I18n.format('account.skin.variant.slim') ? 'slim' : variant;

    String url = 'https://api.minecraftservices.com/minecraft/profile/skins';

    http.MultipartRequest request = http.MultipartRequest('PUT', Uri.parse(url))
      ..fields['variant'] = variant
      ..files.add(await http.MultipartFile.fromPath('file', file.absolute.path,
          contentType: MediaType('image', 'png')));
    request.headers.addAll({'Authorization': "Bearer $accessToken"});
    http.StreamedResponse response = await request.send();

    bool success = response.stream.bytesToString().toString().isNotEmpty;
    if (!success) {
      logger.error(ErrorType.network, response.reasonPhrase);
    }

    return success;
  }
}
