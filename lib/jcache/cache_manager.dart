import 'dart:developer';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

import 'cache_manager_data.dart';

/// Clase `JCacheManager` para manejar la caché en Flutter.
///
/// Esta clase utiliza `Hive` para almacenar datos y archivos en la caché.
/// Cada dato o archivo se almacena con una clave única y tiene un tiempo
/// de expiración personalizado.
/// Los datos y archivos expirados se eliminan automáticamente.
class JCacheManager {
  static late Box<String> _cacheBox;
  static bool _initialized = false;
  static const String _defaultCacheName = 'J-CACHE-MANAGER-BOX';
  static const _defaultExpiryDays = 7;
  static const String _defaultResourceUrl = 'resourceUrl';
  static const String _defaultResourcePath = 'resourcePath';

  /// Inicializa JCacheManager para su correcto uso.
  ///
  /// Esta función debe ser llamada antes de usar cualquier otra función
  /// de `JCacheManager`.
  ///
  /// Ejemplo:
  /// ```dart
  /// void main() async {
  ///   WidgetsFlutterBinding.ensureInitialized();
  ///   // Initialize JCacheManager
  ///   await JCacheManager.init();
  ///   runApp(const MyApp());
  /// }
  /// ```
  static Future<void> init() async {
    if (!_initialized) {
      final directory = await getApplicationDocumentsDirectory();
      Hive.init(directory.path);
      _cacheBox = await Hive.openBox<String>(_defaultCacheName);
      _initialized = true;
      garbageCollector();
    }
  }

  // ...

  //
  // Verifica si los datos han expirado:
  //
  // Los datos se consideran expirados si han pasado más días desde su
  // último acceso que el número de días especificado en `expiryDays`
  // cuando se almacenaron los datos.
  static bool _isExpired(JCacheManagerData record) {
    return record.updatedAt
        .add(Duration(days: record.expiryDays))
        .isBefore(DateTime.now());
  }

  // ...

  /// Devuelve el número de elementos en la caché.
  ///
  /// Ejemplo:
  /// ```dart
  /// int numItems = JCacheManager.length;
  /// ```
  static int get length => _cacheBox.length;

  /// Devuelve `true` si la caché está vacía, `false` en caso contrario.
  ///
  /// Ejemplo:
  /// ```dart
  /// bool isEmpty = JCacheManager.isEmpty;
  /// ```
  static bool get isEmpty => _cacheBox.isEmpty;

  /// Devuelve `true` si la caché no está vacía, `false` en caso contrario.
  ///
  /// Ejemplo:
  /// ```dart
  /// bool isNotEmpty = JCacheManager.isNotEmpty;
  /// ```
  static bool get isNotEmpty => _cacheBox.isNotEmpty;

  /// Comprueba si la caché contiene un elemento con la clave dada.
  ///
  /// Parámetros:
  /// - `key`: La clave del elemento.
  ///
  /// Devoluciones:
  /// - `true` si la caché contiene un elemento con la clave dada, `false`
  /// en caso contrario.
  ///
  /// Ejemplo:
  /// ```dart
  /// bool isMember = JCacheManager.contains('myData');
  /// ```
  static bool contains(String key) => _cacheBox.containsKey(key);

  /// Observa los cambios en el elemento con la clave dada.
  ///
  /// Parámetros:
  /// - `key`: La clave del elemento.
  ///
  /// Devoluciones:
  /// - Un `Stream<JCacheManagerData>` que emite eventos cuando el
  /// elemento cambia.
  ///
  /// Ejemplo:
  /// ```dart
  /// Stream<JCacheManagerData> stream = JCacheManager.watch('myData');
  /// stream.listen((event) {
  ///   print('Data changed: ${event.value}');
  /// });
  /// ```
  static Stream<JCacheManagerData> watch(String key) {
    return _cacheBox
        .watch(key: key)
        .map((BoxEvent event) {
          // Obtiene el valor del evento como una cadena JSON
          final jsonString = event.value;
          if (jsonString != null) {
            // Deserializa la cadena JSON a JCacheManagerData
            final e = JCacheManagerData.fromJson(jsonDecode(jsonString));
            // Devuelve JCacheManagerData
            return e;
          }
          // Si jsonString es null, devuelve null
          return null;
        })
        .where((data) => data != null)
        .cast<JCacheManagerData>();
  }

  /// Devuelve una lista de todas las claves en la caché.
  ///
  /// Esta función puede ser útil para depurar o para operaciones de
  /// limpieza manual.
  ///
  /// Devoluciones:
  /// - Una lista de todas las claves en la caché.
  ///
  /// Ejemplo:
  /// ```dart
  /// List<String> keys = await JCacheManager.getKeys();
  /// ```
  static Future<List<String>> getKeys() async {
    return _cacheBox.keys.toList().map((e) => e as String).toList();
  }

  /// Almacena datos en la caché.
  ///
  /// Los datos se almacenan con una clave única y se eliminan automáticamente
  /// después de `expiryDays` días.
  ///
  /// Parámetros:
  /// - `key`: La clave única para los datos. Debe tener una longitud de
  /// hasta 255 caracteres.
  /// - `value`: Los datos en formato JSON.
  /// - `expiryDays`: El número de días antes de que los datos expiren.
  /// Por defecto es `_defaultExpiryDays = 7`.
  ///
  /// Ejemplo:
  /// ```dart
  /// await JCacheManager.setData(
  ///   key: 'myData',
  ///   value: {'name': 'John', 'age': 30},
  /// );
  /// ```
  ///
  /// Nota: La longitud máxima de la clave es de 255 caracteres. Si la clave
  /// es más larga, los datos no se almacenarán y se mostrará un mensaje
  /// de error.
  static Future<void> setData({
    required String key,
    required Map<String, dynamic> value,
    int? expiryDays,
  }) async {
    if (key.length <= 255) {
      final datetime = DateTime.now();
      await _cacheBox.put(
        key,
        jsonEncode(JCacheManagerData(
          data: value,
          expiryDays: expiryDays ?? _defaultExpiryDays,
          dataType: JCacheManagerDataType.data,
          createdAt: datetime,
          updatedAt: datetime,
        ).toJson()),
      );
    } else {
      debugPrint('KEY exceeds 255 character limit: $key');
    }
  }

  /// Recupera datos desde la caché.
  ///
  /// Si los datos han expirado, se eliminan automáticamente y se
  /// devuelve `null`.
  ///
  /// Parámetros:
  /// - `key`: La clave única de los datos.
  /// - `expiryDays`: El nuevo número de días antes de que los datos
  /// expiren. Por defecto es `_defaultExpiryDays = 7`.
  ///
  /// Devoluciones:
  /// - Los datos en formato JSON, o `null` si los datos no existen o han
  /// expirado.
  ///
  /// Ejemplo:
  /// ```dart
  /// Map<String, dynamic>? data = await JCacheManager.getData('myData');
  /// ```
  static Future<Map<String, dynamic>?> getData(
    String key, {
    int? expiryDays,
  }) async {
    final jsonString = _cacheBox.get(key);
    if (jsonString != null) {
      final information = JCacheManagerData.fromJson(jsonDecode(jsonString));
      if (!_isExpired(information)) {
        // Actualiza la fecha del último acceso
        information.updatedAt = DateTime.now();
        // Actualiza los días en lo que expirarán los datos
        information.expiryDays = expiryDays ?? _defaultExpiryDays;
        await _cacheBox.put(key, jsonEncode(information.toJson()));
        // Devuelve los datos JSON
        return information.data;
      } else {
        // Los datos han expirado, elimínalos
        await _cacheBox.delete(key);
      }
    }
    return null;
  }

  /// Almacena archivos en la caché.
  ///
  /// La ruta del archivo se almacena con una URL única y se elimina
  /// automáticamente después de `expiryDays` días.
  ///
  /// Parámetros:
  /// - `url`: La URL única para el archivo. Debe tener una longitud de
  /// hasta 255 caracteres.
  /// - `path`: La ruta del archivo.
  /// - `expiryDays`: El número de días antes de que la ruta del archivo
  /// expire. Por defecto es `_defaultExpiryDays = 7`.
  ///
  /// Ejemplo:
  /// ```dart
  /// await JCacheManager.setFile(
  ///   url: 'https://example.com/myFile',
  ///   path: '/path/to/myFile',
  /// );
  /// ```
  ///
  /// Nota: La longitud máxima de la URL es de 255 caracteres. Si la URL es
  /// más larga, la ruta del archivo no se almacenará y se mostrará un mensaje
  /// de error.
  static Future<void> setFile({
    required String url,
    required String path,
    int? expiryDays,
  }) async {
    if (url.length <= 255) {
      final datetime = DateTime.now();
      await _cacheBox.put(
        url,
        jsonEncode(JCacheManagerData(
          data: {
            _defaultResourceUrl: url,
            _defaultResourcePath: path,
          },
          expiryDays: expiryDays ?? _defaultExpiryDays,
          dataType: JCacheManagerDataType.file,
          createdAt: datetime,
          updatedAt: datetime,
        ).toJson()),
      );
    } else {
      debugPrint('URL exceeds 255 character limit: $url');
    }
  }

  /// Recupera archivos desde la caché.
  ///
  /// Si la ruta del archivo ha expirado, se elimina automáticamente y se
  /// devuelve `null`.
  ///
  /// Parámetros:
  /// - `url`: La URL única del archivo.
  /// - `expiryDays`: El nuevo número de días antes de que la ruta del
  /// archivo expire. Por defecto es `_defaultExpiryDays = 7`.
  ///
  /// Devoluciones:
  /// - La ruta del archivo, o `null` si la ruta del archivo no existe o
  /// ha expirado.
  ///
  /// Ejemplo:
  /// ```dart
  /// String? filePath = await JCacheManager.getFile('https://example.com/myFile');
  /// ```
  static Future<String?> getFile(
    String url, {
    int? expiryDays,
  }) async {
    final jsonString = _cacheBox.get(url);
    if (jsonString != null) {
      final archive = JCacheManagerData.fromJson(jsonDecode(jsonString));
      if (!_isExpired(archive)) {
        // Actualiza la fecha del último acceso
        archive.updatedAt = DateTime.now();
        // Actualiza los días en lo que expirará el archivo
        archive.expiryDays = expiryDays ?? _defaultExpiryDays;
        await _cacheBox.put(url, jsonEncode(archive.toJson()));
        // Devuelve la ruta del archivo
        return archive.data[_defaultResourcePath];
      } else {
        // El archivo ha expirado, elimínalo
        await _cacheBox.delete(url);
        final file = File(archive.data[_defaultResourcePath]);
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
    return null;
  }

  /// Elimina el dato o archivo para una clave dada.
  ///
  /// Parámetros:
  /// - `key`: La clave del dato o archivo.
  ///
  /// Ejemplo:
  /// ```dart
  /// await JCacheManager.remove('myData');
  /// ```
  static Future<void> remove(String key) async {
    await _cacheBox.delete(key);
  }

  /// Elimina los datos y archivos expirados.
  ///
  /// Esta función puede ser útil para liberar espacio de almacenamiento.
  ///
  /// Ejemplo:
  /// ```dart
  /// await JCacheManager.garbageCollector();
  /// ```
  static Future<void> garbageCollector() async {
    for (final key in _cacheBox.keys) {
      final jsonString = _cacheBox.get(key);
      if (jsonString != null) {
        final value = JCacheManagerData.fromJson(jsonDecode(jsonString));
        if (_isExpired(value)) {
          await remove(key);
          if (value.dataType == JCacheManagerDataType.file) {
            final file = File(value.data[_defaultResourcePath]);
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

  /// Libera los recursos del uso de la cache.
  ///
  /// Esta función debe ser llamada cuando la aplicación se cierra.
  /// Aquí se cierra la cache cuando ya no es necesario su uso.
  ///
  /// Ejemplo:
  /// ```dart
  /// await JCacheManager.dispose();
  /// ```
  static Future<void> dispose() async {
    // Cerrar la caja cuando ya no se necesite
    await _cacheBox.close();
  }

  /// Borra todos los datos en la caché.
  ///
  /// Este método puede ser útil para liberar espacio de almacenamiento o
  /// para reiniciar la caché.
  ///
  /// Ejemplo:
  /// ```dart
  /// await JCacheManager.clear();
  /// ```
  static Future<void> clear() async {
    await _cacheBox.clear();
  }

  /// Imprime la información detallada de un registro en la caché.
  ///
  /// Este método puede ser útil para depurar o para inspeccionar el
  /// contenido de la caché.
  ///
  /// Parámetros:
  /// - `key`: La clave del registro.
  ///
  /// Ejemplo:
  /// ```dart
  /// JCacheManager.print('myData');
  /// ```
  ///
  /// Nota: Este método imprime la información en la consola. Si el registro
  /// no existe o ha expirado, no se imprime nada.
  static void print(String key) {
    final jsonString = _cacheBox.get(key);
    if (jsonString != null) {
      final record = JCacheManagerData.fromJson(jsonDecode(jsonString));
      final data = record.data;
      var encoder = JsonEncoder.withIndent(' ' * 2);
      var formattedJson = encoder.convert(data);
      log(
        record.dataType == JCacheManagerDataType.data ? 'DATA' : 'FILE',
        name: 'JCACHE',
      );
      log(record.expiryDays.toString(), name: 'Expiry Days');
      log(record.createdAt.toString(), name: 'Created At');
      log(record.updatedAt.toString(), name: 'Updated At');
      log(key, name: 'Key');
      log(formattedJson, name: 'Value');
    }
  }

  // ...
}
