import 'package:rpmlauncher/model/game/version/library_download_artifact.dart';
import 'package:rpmlauncher/model/game/version/mc_version_library.dart';
import 'package:rpmlauncher/task/fetch_task.dart';
import 'package:rpmlauncher/task/isolate_task.dart';
import 'package:rpmlauncher/task/task_size.dart';

class LibraryDownloadTask extends IsolateTask<void> {
  final List<MCVersionLibrary> libraries;

  LibraryDownloadTask(this.libraries);

  @override
  String get name => 'library_download_task';

  @override
  TaskSize get size => TaskSize.large;

  @override
  Future execute() async {
    setMessage('正在下載遊戲函式庫中...');
    for (final library in libraries) {
      if (library.shouldDownload()) {
        final artifact = library.downloads.artifact;
        final natives = library.downloads.classifiers?.getNatives();

        if (artifact != null) {
          _download(artifact);
        }
        if (natives != null) {
          _download(natives);
        }
      }
    }
    return;
  }

  void _download(LibraryDownloadArtifact artifact) {
    addPostSubTask(FetchTask(
        url: artifact.url,
        path: artifact.getFilePath(),
        hash: artifact.sha1,
        fileSize: artifact.size));
  }
}
