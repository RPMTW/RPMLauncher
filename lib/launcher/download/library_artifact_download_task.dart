import 'dart:io';

import 'package:rpmlauncher/model/game/version/library_download_artifact.dart';
import 'package:rpmlauncher/task/task.dart';
import 'package:rpmlauncher/util/io_util.dart';
import 'package:rpmlauncher/util/rpml_http_client.dart';

class LibraryArtifactDownloadTask extends Task<void> {
  final LibraryDownloadArtifact artifact;

  LibraryArtifactDownloadTask(this.artifact) : super(async: true);

  @override
  String get name => 'library_artifact_download_task';

  @override
  Future<void> execute() async {
    final filePath = artifact.getFilePath();
    final file = File(filePath);

    if (!IOUtil.isCachedFileSha1(file, artifact.sha1)) {
      await httpClient.download(artifact.url, filePath,
          onReceiveProgress: (count, total) =>
              setProgressByCount(count, total));
    }
  }
}
