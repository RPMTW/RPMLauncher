import 'package:rpmlauncher/launcher/download/library_artifact_download_task.dart';
import 'package:rpmlauncher/model/game/version/mc_version_library.dart';
import 'package:rpmlauncher/task/isolate_task.dart';

class LibraryDownloadTask extends IsolateTask<void> {
  final List<MCVersionLibrary> libraries;

  LibraryDownloadTask(this.libraries);

  @override
  String get name => 'library_download_task';

  @override
  Future execute() async {
    setMessage('正在下載遊戲函式庫中...');
    for (final library in libraries) {
      if (library.shouldDownload()) {
        final artifact = library.downloads.artifact;
        final natives = library.downloads.classifiers?.getNatives();

        if (artifact != null) {
          addPostSubTask(LibraryArtifactDownloadTask(artifact));
        }
        if (natives != null) {
          addPostSubTask(LibraryArtifactDownloadTask(natives));
        }
      }
    }
    return;
  }
}
