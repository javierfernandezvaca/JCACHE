import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'cache_manager.dart';
import 'download_event.dart';
import 'download_status.dart';

class JFileDownloader {
  late StreamController<JFileDownloadEvent> _controller;
  String? _url;
  http.StreamedResponse? _response;
  File? _file;
  late int _bytesReceived;
  late int _contentLength;
  StreamSubscription<List<int>>? _streamSubscription;

  Stream<JFileDownloadEvent> get progressStream => _controller.stream;

  JFileDownloader() {
    _controller = StreamController<JFileDownloadEvent>.broadcast();
    _bytesReceived = 0;
    _contentLength = 0;
  }

  Future<String> downloadAndCacheFile(
    String url, {
    int? expiryDays,
  }) async {
    _url = url;
    // Verificar si el archivo ya está en caché
    String? cachedFilePath = await JCacheManager.getFile(
      url,
      expiryDays: expiryDays,
    );
    if (cachedFilePath != null) {
      // Si el archivo ya está en caché, emitir un evento 'completed'
      if (!_controller.isClosed) {
        _controller.sink.add(JFileDownloadEvent(
          resourceUrl: url,
          status: JFileDownloadStatus.completed,
          progress: 1.0,
          contentLength: await File(cachedFilePath).length(),
          resourcePath: cachedFilePath,
        ));
      }
      // Devolver la ruta del archivo en caché
      return cachedFilePath;
    } else {
      if (!url.startsWith('http')) {
        // Si la URL es una ruta de archivo local, se almacena en caché
        await JCacheManager.setFile(
          url: url,
          path: url,
          expiryDays: expiryDays,
        );
        if (!_controller.isClosed) {
          // Emitir un evento 'completed'
          _controller.sink.add(JFileDownloadEvent(
            resourceUrl: url,
            status: JFileDownloadStatus.completed,
            progress: 1.0,
            contentLength: await File(url).length(),
            resourcePath: url,
          ));
        }
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
              // debugPrint('Bytes received: $_bytesReceived');
              sink.add(chunk);
              if (!_controller.isClosed) {
                _controller.sink.add(JFileDownloadEvent(
                  resourceUrl: url,
                  status: JFileDownloadStatus.downloading,
                  progress: _bytesReceived / contentLength,
                  contentLength: _contentLength,
                  resourcePath: null,
                ));
              }
            },
            onDone: () async {
              await sink.close();
              await JCacheManager.setFile(
                url: url,
                path: path,
                expiryDays: expiryDays,
              );
              if (!_controller.isClosed) {
                _controller.sink.add(JFileDownloadEvent(
                  resourceUrl: url,
                  status: JFileDownloadStatus.completed,
                  progress: 1.0,
                  contentLength: _contentLength,
                  resourcePath: path,
                ));
              }
            },
            onError: (e) {
              debugPrint('Error during download: $e');
              if (!_controller.isClosed) {
                _controller.sink.addError(JFileDownloadEvent(
                  resourceUrl: url,
                  status: JFileDownloadStatus.error,
                  progress: _bytesReceived / contentLength,
                  contentLength: _contentLength,
                  resourcePath: null,
                ));
              }
            },
          );
          return path;
        } catch (e) {
          debugPrint('Error initiating download: $e');
          return '';
        }
      }
    }
  }

  Future<void> cancelDownload() async {
    await _streamSubscription?.cancel();
    await _file?.delete();
    if (!_controller.isClosed) {
      _controller.sink.add(JFileDownloadEvent(
        resourceUrl: _url ?? '',
        status: JFileDownloadStatus.cancelled,
        progress: _bytesReceived / (_response!.contentLength ?? 0),
        contentLength: _contentLength,
        resourcePath: null,
      ));
    }
  }

  Future<void> dispose() async {
    await _streamSubscription?.cancel();
    await _controller.close();
  }
}
