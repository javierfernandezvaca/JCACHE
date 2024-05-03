import 'download_event.dart';
import 'download_status.dart';
import 'file_downloader.dart';

class JDownloadController {
  late JFileDownloader _fileDownloader;

  JFileDownloadEvent currentEvent = JFileDownloadEvent(
    resourceUrl: '',
    status: JFileDownloadStatus.initialized,
    progress: 0,
    contentLength: 0,
    resourcePath: null,
  );

  Stream<JFileDownloadEvent> get progressStream =>
      _fileDownloader.progressStream;

  JDownloadController() {
    _fileDownloader = JFileDownloader();
  }

  Future<String> startDownload(
    String url, {
    int? expiryDays,
  }) {
    _fileDownloader.progressStream.listen((event) {
      currentEvent = event;
    });
    return _fileDownloader.downloadAndCacheFile(
      url,
      expiryDays: expiryDays,
    );
  }

  Future<void> cancelDownload() async {
    await _fileDownloader.cancelDownload();
  }

  Future<void> dispose() async {
    await _fileDownloader.dispose();
  }
}
