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
        parsed[data_] = i.replaceAll(parsed[line_data[0]] ?? "" + "=", "");
      }
    }
  }

  GetParsed() {
    return (this.parsed);
  }
}
void main(){
  String readed=File("/home/sunnyayyl/.local/share/RPMLauncher/instance/All of Fabric 3 - 1.16.5/instance.cfg").readAsStringSync();
  print(CFG(readed).GetParsed());
}