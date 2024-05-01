import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'cache_manager.dart';
import 'download_event.dart';
import 'download_status.dart';

class JFileDownloader {
  final _controller = StreamController<JFileDownloadEvent>.broadcast();
  String? _url;
  http.StreamedResponse? _response;
  File? _file;
  int _bytesReceived = 0;
  int _contentLength = 0;
  StreamSubscription<List<int>>? _streamSubscription;

  Stream<JFileDownloadEvent> get progressStream => _controller.stream;

  Future<String> downloadAndCacheFile(
    String url, {
    int? expiryInDays,
  }) async {
    _url = url;
    // Verificar si el archivo ya está en caché
    String? cachedFilePath = await JCacheManager.getCachedFile(
      url,
      expiryInDays: expiryInDays,
    );
    if (cachedFilePath != null) {
      // Si el archivo ya está en caché, emitir un evento 'completed'
      _controller.sink.add(JFileDownloadEvent(
        url: url,
        status: JFileDownloadStatus.completed,
        progress: 1.0,
        contentLength: await File(cachedFilePath).length(),
        path: cachedFilePath,
      ));
      // Devolver la ruta del archivo en caché
      return cachedFilePath;
    } else {
      if (!url.startsWith('http')) {
        // Si la URL es una ruta de archivo local, se almacena en caché
        await JCacheManager.cacheFile(
          url: url,
          path: url,
          expiryInDays: expiryInDays,
        );
        // Emitir un evento 'completed'
        _controller.sink.add(JFileDownloadEvent(
          url: url,
          status: JFileDownloadStatus.completed,
          progress: 1.0,
          contentLength: await File(url).length(),
          path: url,
        ));
        // Devolver la ruta del archivo local
        return url;
      } else {
        // Hacer la descarga del mismo y almacenarlo en caché
        final client = http.Client();
        try {
          _response = await client.send(http.Request('GET', Uri.parse(url)));
          _bytesReceived = 0;
          final contentLength = _response!.contentLength ?? 0;
          _contentLength = contentLength;
          debugPrint('Content Length: $contentLength');
          final directory = await getTemporaryDirectory();
          final path = '${directory.path}/${url.split('/').last}';
          _file = File(path);
          final sink = _file!.openWrite();
          _streamSubscription = _response!.stream.listen(
            (chunk) {
              _bytesReceived += chunk.length;
              debugPrint('Bytes received: $_bytesReceived');
              sink.add(chunk);
              _controller.sink.add(JFileDownloadEvent(
                url: url,
                status: JFileDownloadStatus.downloading,
                progress: _bytesReceived / contentLength,
                contentLength: _contentLength,
              ));
            },
            onDone: () async {
              await sink.close();
              await JCacheManager.cacheFile(
                url: url,
                path: path,
                expiryInDays: expiryInDays,
              );
              _controller.sink.add(JFileDownloadEvent(
                url: url,
                status: JFileDownloadStatus.completed,
                progress: 1.0,
                contentLength: _contentLength,
                path: path,
              ));
            },
            onError: (e) {
              debugPrint('Error during download: $e');
              _controller.sink.addError(JFileDownloadEvent(
                url: url,
                status: JFileDownloadStatus.error,
                progress: _bytesReceived / contentLength,
                contentLength: _contentLength,
                path: null,
              ));
            },
          );
          return path;
        } catch (e) {
          debugPrint('Error initiating download: $e');
          // ignore: use_rethrow_when_possible
          throw e;
        }
      }
    }
  }

  Future<void> cancelDownload() async {
    await _streamSubscription?.cancel();
    await _file?.delete();
    _controller.sink.add(JFileDownloadEvent(
      url: _url ?? '',
      status: JFileDownloadStatus.cancelled,
      progress: _bytesReceived / (_response!.contentLength ?? 0),
      contentLength: _contentLength,
      path: null,
    ));
  }

  Future<void> dispose() async {
    await _controller.close();
  }
}
