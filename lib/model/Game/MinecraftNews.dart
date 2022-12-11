import 'dart:collection';
import 'dart:convert';

import 'package:rpmlauncher/launcher/apis.dart';
import 'package:rpmlauncher/util/RPMHttpClient.dart';

class MinecraftNews extends ListBase<MinecraftNew> {
  final List<MinecraftNew> news;

  MinecraftNews(this.news);

  factory MinecraftNews.formMap(Map json) {
    List<MinecraftNew> news =
        json['article_grid'].map((e) => MinecraftNew.formMap(e)).toList().cast<MinecraftNew>();

    return MinecraftNews(news);
  }

  static Future<MinecraftNews> fromWeb() async {
    final response = await RPMHttpClient().get(minecraftNewsJson);
    return MinecraftNews.formMap(response.data);
  }

  @override
  int get length => news.length;
  @override
  set length(int length) => news.length = length;
  @override
  MinecraftNew operator [](int index) {
    return news[index];
  }

  @override
  void operator []=(int index, MinecraftNew value) {
    news[index] = value;
  }
}

class MinecraftNew {
  final String title;
  final String link;
  final String description;
  final String imageUri;

  MinecraftNew(this.title, this.link, this.description, this.imageUri);

  factory MinecraftNew.formMap(Map map) {
    final Map titlePart = map['preferred_tile'] ?? map['default_tile'];

    return MinecraftNew(
        titlePart['title'],
        'https://www.minecraft.net${map['article_url']}',
        titlePart['sub_header'],
        'https://www.minecraft.net${titlePart['image']['imageURL']}');
  }
}
