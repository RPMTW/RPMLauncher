import 'dart:collection';

import 'package:dio/dio.dart';
import 'package:rpmlauncher/Launcher/APIs.dart';
import 'package:xml/xml.dart';

class MinecraftNews extends ListBase<MinecraftNew> {
  final List<MinecraftNew> news;

  MinecraftNews(this.news);

  factory MinecraftNews.fromXml(XmlDocument xmlDocument) {
    List<MinecraftNew> _news = xmlDocument
        .getElement('rss')!
        .getElement('channel')!
        .findAllElements('item')
        .toList()
        .map((e) => MinecraftNew.fromXml(e))
        .toList();
    return MinecraftNews(_news);
  }

  static Future<MinecraftNews> fromWeb() async {
    Response response = await Dio().get(minecraftNewsRSS);
    XmlDocument xmlDocument = XmlDocument.parse(response.data);
    MinecraftNews _news = MinecraftNews.fromXml(xmlDocument);
    return MinecraftNews(_news);
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
  final String sourceImageUri;

  String get imageUri => "https://minecraft.net$sourceImageUri";

  MinecraftNew(this.title, this.link, this.description, this.sourceImageUri);

  factory MinecraftNew.fromXml(XmlElement xmlElement) {
    return MinecraftNew(
        xmlElement.getElement('title')!.text,
        xmlElement.getElement('link')!.text,
        xmlElement.getElement('description')!.text,
        xmlElement.getElement('imageURL')!.text);
  }
}
