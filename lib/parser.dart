import 'dart:io';
class CFG {
  late final String data;
  Map parsed = {};

  CFG(String data) {
    this.data = data;
    for (var i in this.data.split("\n")) {
      List<String> line_data = i.split("=");
      String? data_ = line_data[0];
      if (data_.isNotEmpty) {
        parsed[data_] = i.replaceFirst(data_,"").replaceFirst("=", "");
      }
    }
  }

  GetParsed() {
    return (this.parsed);
  }
}
