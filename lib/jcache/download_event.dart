import 'download_status.dart';

class JFileDownloadEvent {
  final String resourceUrl;
  final JFileDownloadStatus status;
  final double progress;
  final int contentLength;
  final String? resourcePath;

  JFileDownloadEvent({
    required this.resourceUrl,
    required this.status,
    required this.progress,
    required this.contentLength,
    this.resourcePath,
  });
}
