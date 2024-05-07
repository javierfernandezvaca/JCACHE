import 'download_status.dart';

class JFileDownloadEvent {
  final String resourceUrl;
  final JFileDownloadStatus status;
  final double progress;
  final int contentLength;
  final String? resourcePath;
  final String? error;

  JFileDownloadEvent({
    required this.resourceUrl,
    required this.status,
    required this.progress,
    required this.contentLength,
    this.resourcePath,
    this.error,
  });
}
