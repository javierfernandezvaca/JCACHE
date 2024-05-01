import 'download_status.dart';

class JFileDownloadEvent {
  final String url;
  final JFileDownloadStatus status;
  final double progress;
  final int contentLength;
  final String? path;
  // ...

  JFileDownloadEvent({
    required this.url,
    required this.status,
    required this.progress,
    required this.contentLength,
    this.path,
  });
}
