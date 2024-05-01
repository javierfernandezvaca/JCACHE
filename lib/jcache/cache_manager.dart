import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

import 'configs.dart';
import 'cache_manager_data.dart';

class JCacheManager {
  static late Box<String> _cacheBox;
  static bool _initialized = false;

  // Inicializa Hive y abre la caja
  static Future<void> _init() async {
    if (!_initialized) {
      final directory = await getApplicationDocumentsDirectory();
      Hive.init(directory.path);
      _initialized = true;
      _cacheBox = await Hive.openBox<String>(jDefaultCacheName);
      await deleteExpiredCacheManagerData();
    }
  }

  // Verifica si los datos han expirado
  static bool _isExpired(JCacheManagerData data) {
    return data.lastAccessed
        .add(Duration(days: data.expiryInDays))
        .isBefore(DateTime.now());
  }

  // Almacena datos JSON en la caché
  static Future<void> cacheData({
    required String key,
    required Map<String, dynamic> value,
    int expiryInDays = jDefaultExpiryInDays,
  }) async {
    await _init();
    await _cacheBox.put(
      key,
      jsonEncode(JCacheManagerData(
        data: value,
        lastAccessed: DateTime.now(),
        expiryInDays: expiryInDays,
        dataType: JCacheManagerDataType.data,
      ).toJson()),
    );
  }

  // Recupera datos JSON desde la caché
  static Future<Map<String, dynamic>?> getCachedData(
    String key, {
    int expiryInDays = jDefaultExpiryInDays,
  }) async {
    await _init();
    final jsonString = _cacheBox.get(key);
    if (jsonString != null) {
      final value = JCacheManagerData.fromJson(jsonDecode(jsonString));
      if (!_isExpired(value)) {
        // Actualiza la fecha del último acceso
        value.lastAccessed = DateTime.now();
        // Actualiza los días en lo que expirarán los datos
        value.expiryInDays = expiryInDays;
        await _cacheBox.put(key, jsonEncode(value.toJson()));
        // Devuelve los datos JSON
        return value.data;
      } else {
        // Los datos han expirado, elimínalos
        await _cacheBox.delete(key);
      }
    }
    return null;
  }

  // Almacena la ruta del archivo en la caché
  static Future<void> cacheFile({
    required String url,
    required String path,
    int? expiryInDays,
  }) async {
    await _init();
    await _cacheBox.put(
      url,
      jsonEncode(JCacheManagerData(
        data: {
          'path': path,
        },
        lastAccessed: DateTime.now(),
        expiryInDays: expiryInDays ?? jDefaultExpiryInDays,
        dataType: JCacheManagerDataType.file,
      ).toJson()),
    );
  }

  // Recupera la ruta del archivo desde la caché
  static Future<String?> getCachedFile(
    String url, {
    int? expiryInDays,
  }) async {
    await _init();
    final jsonString = _cacheBox.get(url);
    if (jsonString != null) {
      final value = JCacheManagerData.fromJson(jsonDecode(jsonString));
      if (!_isExpired(value)) {
        // Actualiza la fecha del último acceso
        value.lastAccessed = DateTime.now();
        // Actualiza los días en lo que expirará el archivo
        value.expiryInDays = expiryInDays ?? jDefaultExpiryInDays;
        await _cacheBox.put(url, jsonEncode(value.toJson()));
        // Devuelve la ruta del archivo
        return value.data['path'];
      } else {
        // El archivo ha expirado, elimínalo
        await _cacheBox.delete(url);
        final file = File(value.data['path']);
        if (await file.exists()) {
          try {
            await file.delete();
          } catch (e) {
            throw ('Error deleting file: $e');
          }
        }
      }
    }
    return null;
  }

  // Elimina los datos y archivos expirados
  static Future<void> deleteExpiredCacheManagerData() async {
    await _init();
    for (final key in _cacheBox.keys) {
      final jsonString = _cacheBox.get(key);
      if (jsonString != null) {
        final value = JCacheManagerData.fromJson(jsonDecode(jsonString));
        if (_isExpired(value)) {
          await _cacheBox.delete(key);
          if (value.dataType == JCacheManagerDataType.file) {
            final file = File(value.data['path']);
            if (await file.exists()) {
              try {
                await file.delete();
              } catch (e) {
                // Se registra el error y se continua con la ejecución
                // del programa
                debugPrint('Error deleting file: $e');
              }
            }
          }
        }
      }
    }
  }

  static Future<void> dispose() async {
    // Cerrar la caja cuando ya no se necesite
    await _cacheBox.close();
  }

  // ...
}
