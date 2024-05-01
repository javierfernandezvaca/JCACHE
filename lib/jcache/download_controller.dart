import 'download_event.dart';
import 'download_status.dart';
import 'file_downloader.dart';

class JDownloadController {
  final JFileDownloader _fileDownloader = JFileDownloader();
  JFileDownloadEvent currentEvent = JFileDownloadEvent(
    url: '',
    status: JFileDownloadStatus.initialized,
    progress: 0,
    contentLength: 0,
    path: null,
  );

  Stream<JFileDownloadEvent> get progressStream =>
      _fileDownloader.progressStream;

  Future<String> startDownload(
    String url, {
    int? expiryInDays,
  }) {
    _fileDownloader.progressStream.listen((event) {
      currentEvent = event;
    });
    return _fileDownloader.downloadAndCacheFile(
      url,
      expiryInDays: expiryInDays,
    );
  }

  Future<void> cancelDownload() async {
    await _fileDownloader.cancelDownload();
  }

  Future<void> dispose() async {
    await _fileDownloader.dispose();
  }
}
