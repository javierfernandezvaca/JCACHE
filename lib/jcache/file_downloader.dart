import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'cache_manager.dart';
import 'download_event.dart';
import 'download_status.dart';

class JFileDownloader {
  final StreamController<JFileDownloadEvent> _controller =
      StreamController<JFileDownloadEvent>.broadcast();
  int _bytesReceived = 0;
  int _contentLength = 0;
  final http.Client _client = http.Client();
  String? _url;
  http.StreamedResponse? _response;
  File? _file;
  StreamSubscription<List<int>>? _streamSubscription;

  Stream<JFileDownloadEvent> get progressStream => _controller.stream;

  JFileDownloader() {
    // ...
  }

  void emitEvent({
    required String resourceUrl,
    required JFileDownloadStatus status,
    required double progress,
    required int contentLength,
    String? resourcePath,
    String? error,
  }) {
    if (!_controller.isClosed) {
      _controller.sink.add(JFileDownloadEvent(
        resourceUrl: resourceUrl,
        status: status,
        progress: progress,
        contentLength: contentLength,
        resourcePath: resourcePath,
        error: error,
      ));
    }
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
    if ((cachedFilePath != null) && await File(cachedFilePath).exists()) {
      // Si el archivo ya está en caché y el archivo en el sistema de
      // archivos, emitir un evento 'completed'
      emitEvent(
        resourceUrl: url,
        status: JFileDownloadStatus.completed,
        progress: 1.0,
        contentLength: await File(cachedFilePath).length(),
        resourcePath: cachedFilePath,
        error: null,
      );
      // Devolver la ruta del archivo en caché
      return cachedFilePath;
    } else {
      if (!url.startsWith('http') && await File(url).exists()) {
        // Si la URL es una ruta de archivo local y el archivo esta en el
        // sistema de archivos, se almacena en caché
        await JCacheManager.setFile(
          url: url,
          path: url,
          expiryDays: expiryDays,
        );
        // Emitir un evento 'completed'
        emitEvent(
          resourceUrl: url,
          status: JFileDownloadStatus.completed,
          progress: 1.0,
          contentLength: await File(url).length(),
          resourcePath: url,
          error: null,
        );
        // Devolver la ruta del archivo local
        return url;
      } else {
        // Hacer la descarga del mismo y almacenarlo en caché
        try {
          _response = await _client.send(http.Request('GET', Uri.parse(url)));
          _bytesReceived = 0;
          _contentLength = _response!.contentLength ?? 0;
          // debugPrint('Content Length: $_contentLength');
          final directory = await getApplicationDocumentsDirectory();
          final path = '${directory.path}/${url.split('/').last}';
          _file = File(path);
          final sink = _file!.openWrite();
          _streamSubscription = _response!.stream.listen(
            (chunk) {
              _bytesReceived += chunk.length;
              // debugPrint('Bytes received: $_bytesReceived');
              sink.add(chunk);
              // Emitir un evento 'downloading'
              emitEvent(
                resourceUrl: url,
                status: JFileDownloadStatus.downloading,
                progress: _bytesReceived / _contentLength,
                contentLength: _contentLength,
                resourcePath: null,
                error: null,
              );
            },
            onDone: () async {
              await sink.close();
              await JCacheManager.setFile(
                url: url,
                path: path,
                expiryDays: expiryDays,
              );
              // Emitir un evento 'completed'
              emitEvent(
                resourceUrl: url,
                status: JFileDownloadStatus.completed,
                progress: 1.0,
                contentLength: _contentLength,
                resourcePath: path,
                error: null,
              );
            },
            onError: (e) async {
              if (e is http.ClientException) {
                debugPrint('Error during download: ${e.message}');
                await _streamSubscription?.cancel();
                if ((_file != null) && await _file!.exists()) {
                  await _file!.delete();
                }
                // Emitir un evento 'error'
                emitEvent(
                  resourceUrl: url,
                  status: JFileDownloadStatus.error,
                  progress: _bytesReceived / _contentLength,
                  contentLength: _contentLength,
                  resourcePath: null,
                  error: e.message,
                );
              } else {
                debugPrint('Error during download: $e');
                await _streamSubscription?.cancel();
                if ((_file != null) && await _file!.exists()) {
                  await _file!.delete();
                }
                // Emitir un evento 'error'
                emitEvent(
                  resourceUrl: url,
                  status: JFileDownloadStatus.error,
                  progress: _bytesReceived / _contentLength,
                  contentLength: _contentLength,
                  resourcePath: null,
                  error: 'Error during download',
                );
              }
            },
          );
          return path;
        } on SocketException catch (e) {
          debugPrint('Error initiating download: ${e.message}');
          await _streamSubscription?.cancel();
          if ((_file != null) && await _file!.exists()) {
            await _file!.delete();
          }
          // Emitir un evento 'error'
          emitEvent(
            resourceUrl: url,
            status: JFileDownloadStatus.error,
            progress: 0,
            contentLength: _contentLength,
            resourcePath: null,
            error: e.message,
          );
          return '';
        } catch (e) {
          debugPrint('Error initiating download');
          await _streamSubscription?.cancel();
          if ((_file != null) && await _file!.exists()) {
            await _file!.delete();
          }
          // Emitir un evento 'error'
          emitEvent(
            resourceUrl: url,
            status: JFileDownloadStatus.error,
            progress: 0,
            contentLength: _contentLength,
            resourcePath: null,
            error: 'Error initiating download',
          );
          return '';
        }
      }
    }
  }

  Future<void> cancelDownload() async {
    await _streamSubscription?.cancel();
    if ((_file != null) && await _file!.exists()) {
      await _file!.delete();
    }
    // Emitir un evento 'cancelled'
    emitEvent(
      resourceUrl: _url ?? '',
      status: JFileDownloadStatus.cancelled,
      progress: _bytesReceived / (_response!.contentLength ?? 1),
      contentLength: _contentLength,
      resourcePath: null,
      error: null,
    );
  }

  Future<void> dispose() async {
    _client.close();
    await _streamSubscription?.cancel();
    await _controller.close();
  }
}
