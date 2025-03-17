import 'dart:developer';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:jcache/jcache/exceptions.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';

import 'cache_manager_data.dart';

/// Clase `JCacheManager` para la gestión de caché en Flutter.
///
/// Esta clase proporciona una interfaz para almacenar y recuperar datos y
/// archivos en caché utilizando `Hive` para la persistencia.
///
/// Características:
///
/// - Persistencia: Utiliza `Hive` para almacenar la caché de forma
///     persistente en el dispositivo.
/// - Soporte para Datos y Archivos: Permite cachear tanto datos serializables
///     (como JSON) como rutas a archivos locales.
/// - Expiración: Implementa un sistema de expiración basado en tiempo,
///     eliminando automáticamente los datos y archivos que han excedido su
///     tiempo de vida útil.
/// - Claves Hash: Utiliza SHA-256 para generar claves hash únicas a partir
///     de las claves proporcionadas por el usuario, garantizando unicidad y
///     seguridad básica.
/// - Recolección de Basura: Incluye un recolector de basura para eliminar
///     periódicamente los elementos expirados y liberar espacio.
/// - Observación de Cambios: Ofrece la capacidad de observar cambios en
///     elementos específicos de la caché mediante `Stream`.
/// - Manejo de Errores: Implementa manejo de errores robusto para
///     operaciones de serialización/deserialización JSON.
class JCacheManager {
  static const String _defaultCacheName = 'J-CACHE-MANAGER-BOX';
  static const String _defaultResourceUrl = 'resourceUrl';
  static const String _defaultResourcePath = 'resourcePath';
  static int _defaultExpiryDays = 7;
  static bool _initialized = false;
  static late Box<String> _cacheBox;

  /// Genera una clave hash única utilizando el algoritmo SHA-256.
  ///
  /// Convierte cualquier cadena de entrada en una clave de longitud fija,
  /// útil para indexar en la caché y para ofuscar las claves originales.
  ///
  /// Parámetros:
  ///   - `input`: La cadena de entrada para generar el hash.
  ///
  /// Devoluciones:
  ///   - Una cadena representando el hash SHA-256 de la entrada.
  static String _generateHashKey(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Inicializa `JCacheManager` para su uso.
  ///
  /// Debe ser llamado una vez al inicio de la aplicación, antes de utilizar
  /// cualquier otra función de `JCacheManager`.
  ///
  /// Inicializa `Hive`, abre la caja de caché y ejecuta el recolector de basura
  /// inicial.
  ///
  /// Parámetros opcionales:
  ///   - `cacheName`: (Opcional) Nombre personalizado para la caja de caché de Hive.
  ///     Si no se proporciona, se usa el nombre por defecto: `_defaultCacheName`.
  ///   - `defaultExpiryDays`: (Opcional) Días de expiración por defecto para la caché.
  ///     Si no se proporciona, se usa el valor por defecto: `_defaultExpiryDays = 7`.
  ///
  /// Ejemplo:
  /// ```dart
  /// void main() async {
  ///   WidgetsFlutterBinding.ensureInitialized();
  ///   // Inicialización con nombre de caché y días de expiración personalizados
  ///   await JCacheManager.init(
  ///     cacheName: 'miCachePersonalizada',
  ///     defaultExpiryDays: 30,
  ///   );
  ///   runApp(const MyApp());
  /// }
  /// ```
  static Future<void> init({
    String? cacheName,
    int? defaultExpiryDays,
  }) async {
    if (!_initialized) {
      final directory = await getApplicationDocumentsDirectory();
      Hive.init(directory.path);
      final boxName = cacheName ?? _defaultCacheName;
      _cacheBox = await Hive.openBox<String>(boxName);
      if (defaultExpiryDays != null) {
        _defaultExpiryDays = defaultExpiryDays;
      }
      _initialized = true;
      garbageCollector();
    }
  }

  // ...

  /// Verifica si un registro de caché ha expirado.
  ///
  /// Compara la fecha de última actualización del registro con la fecha actual,
  /// considerando el tiempo de expiración definido en `expiryDays`.
  ///
  /// Parámetros:
  ///   - `record`: El registro `JCacheManagerData` a verificar.
  ///
  /// Devoluciones:
  ///   - `true` si el registro ha expirado, `false` en caso contrario.
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
  /// int cantidadItems = JCacheManager.length;
  /// ```
  static int get length => _cacheBox.length;

  /// Devuelve `true` si la caché está vacía.
  ///
  /// Ejemplo:
  /// ```dart
  /// bool cacheVacia = JCacheManager.isEmpty;
  /// ```
  static bool get isEmpty => _cacheBox.isEmpty;

  /// Devuelve `true` si la caché no está vacía.
  ///
  /// Ejemplo:
  /// ```dart
  /// bool cacheNoVacia = JCacheManager.isNotEmpty;
  /// ```
  static bool get isNotEmpty => _cacheBox.isNotEmpty;

  /// Comprueba si la caché contiene un elemento con la clave especificada.
  ///
  /// Utiliza la clave hash generada para buscar en la caja de caché.
  ///
  /// Parámetros:
  ///   - `key`: La clave del elemento a buscar.
  ///
  /// Devoluciones:
  ///   - `true` si la caché contiene un elemento con la clave, `false` en caso contrario.
  ///
  /// Ejemplo:
  /// ```dart
  /// bool existeElemento = JCacheManager.contains('miClave');
  /// ```
  static bool contains(String key) =>
      _cacheBox.containsKey(_generateHashKey(key));

  /// Observa los cambios en un elemento específico de la caché.
  ///
  /// Devuelve un `Stream` que emite eventos cada vez que el elemento
  /// con la clave especificada se modifica en la caché.
  ///
  /// Parámetros:
  ///   - `key`: La clave del elemento a observar.
  ///
  /// Devoluciones:
  ///   - Un `Stream<JCacheManagerData>` que emite eventos `JCacheManagerData`
  ///     cuando el elemento cambia. Emite `null` si el elemento es eliminado.
  ///
  /// Ejemplo:
  /// ```dart
  /// Stream<JCacheManagerData> streamDeDatos = JCacheManager.watch('miClave');
  /// streamDeDatos.listen((evento) {
  ///   if (evento != null) {
  ///     print('Dato cambiado: ${evento.data}');
  ///   } else {
  ///     print('Dato eliminado de la caché');
  ///   }
  /// });
  /// ```
  static Stream<JCacheManagerData?> watch(String key) {
    final hashKey = _generateHashKey(key);
    // return _cacheBox.watch(key: hashKey).map((BoxEvent event) {
    return _cacheBox.watch(key: hashKey).map((BoxEvent event) {
      final jsonString = event.value;
      if (jsonString == null) {
        return null;
      } else {
        final e = JCacheManagerData.fromJson(jsonDecode(jsonString));
        return e;
      }
    });
  }

  /// Devuelve una lista de todas las claves hash en la caché.
  ///
  /// Útil para depuración y operaciones de gestión manual de la caché.
  ///
  /// Devoluciones:
  ///   - Una `List<String>` conteniendo todas las claves hash de la caché.
  ///
  /// Ejemplo:
  /// ```dart
  /// List<String> claves = await JCacheManager.getKeys();
  /// ```
  static Future<List<String>> getKeys() async {
    // return _cacheBox.keys.toList().map((e) => e as String).toList();
    List<String> originalKeys = [];
    for (var hashKey in _cacheBox.keys) {
      final jsonString = _cacheBox.get(hashKey as String);
      if (jsonString != null) {
        try {
          final record = JCacheManagerData.fromJson(jsonDecode(jsonString));
          originalKeys.add(record.originalKey);
        } catch (e) {
          debugPrint('Error decoding JSON for key: $hashKey in getKeys: $e');
        }
      }
    }
    return originalKeys;
  }

  /// Almacena datos en la caché.
  ///
  /// Serializa el valor a JSON y lo guarda en la caché asociado a la clave
  /// especificada. Los datos se eliminan automáticamente después de
  /// `expiryDays` días.
  ///
  /// Parámetros:
  ///   - `key`: La clave única para identificar los datos.
  ///   - `value`: El dato a almacenar **de tipo `T`**, debe ser serializable a JSON.
  ///   - `expiryDays`: (Opcional) Número de días hasta que los datos expiren.
  ///     Por defecto es `_defaultExpiryDays = 7`.
  ///
  /// Ejemplo:
  /// ```dart
  /// // Almacenando un Map<String, dynamic>
  /// await JCacheManager.setData<Map<String, dynamic>>(
  ///   key: 'datosUsuario',
  ///   value: {'nombre': 'Juan', 'edad': 30},
  /// );
  ///
  /// // Almacenando un String
  /// await JCacheManager.setData<String>(
  ///   key: 'nombreUsuario',
  ///   value: 'Juan Perez',
  /// );
  /// ```
  static Future<void> setData<T>({
    required String key,
    required T value,
    int? expiryDays,
  }) async {
    final hashKey = _generateHashKey(key);
    final datetime = DateTime.now();
    // Variable para almacenar el valor encoded, nullable por si falla
    // la serialización
    String? encodedValue;
    // ...
    try {
      encodedValue = jsonEncode(JCacheManagerData(
        originalKey: key,
        data: {
          'key': key,
          'data': value,
        },
        expiryDays: expiryDays ?? _defaultExpiryDays,
        dataType: JCacheManagerDataType.data,
        createdAt: datetime,
        updatedAt: datetime,
      ).toJson());
    } on FormatException catch (e) {
      throw JsonCacheException('Error encoding data to JSON for key: $key',
          originalException: e);
    }
    // ...
    await _cacheBox.put(hashKey, encodedValue);
  }

  /// Recupera datos de la caché.
  ///
  /// Deserializa el valor JSON asociado a la clave especificada y lo devuelve.
  /// Si los datos han expirado o no existen, se devuelve `null`.
  ///
  /// Parámetros:
  ///   - `key`: La clave única de los datos a recuperar.
  ///   - `expiryDays`: (Opcional) Nuevo tiempo de expiración para los datos.
  ///     Si se proporciona, actualiza el tiempo de expiración del registro.
  ///     Por defecto es `_defaultExpiryDays = 7`.
  ///
  /// Devoluciones:
  ///   - El dato deserializado **de tipo `T`**, o `null` si no existe o ha expirado,
  ///     o si ocurre un error durante la deserialización.
  ///
  /// Ejemplo:
  /// ```dart
  /// // Ejemplo recuperando un Map<String, dynamic>
  /// Map<String, dynamic>? datosUsuario = await JCacheManager.getData<Map<String, dynamic>>('datosUsuario');
  /// if (datosUsuario != null) {
  ///   print('Datos recuperados: $datosUsuario');
  /// } else {
  ///   print('Datos no encontrados o expirados.');
  /// }
  ///
  /// // Ejemplo recuperando un String
  /// String? nombre = await JCacheManager.getData<String>('nombreUsuario');
  /// if (nombre != null) {
  ///   print('Nombre recuperado: $nombre');
  /// }
  /// ```
  static Future<T?> getData<T>(
    String key, {
    int? expiryDays,
  }) async {
    final hashKey = _generateHashKey(key);
    final jsonString = _cacheBox.get(hashKey);
    // ...
    if (jsonString != null) {
      // Variable para almacenar la información deserializada,
      // nullable por si falla
      JCacheManagerData? information;
      try {
        information = JCacheManagerData.fromJson(jsonDecode(jsonString));
        // } catch (e) {
        //   debugPrint('Error decoding JSON for key: $key. Error: $e');
        //   // Eliminar la entrada corrupta de la caché aquí:
        //   await _cacheBox.delete(hashKey);
        //   // Devuelve null al fallar la deserialización
        //   return null;
        // }
      } on FormatException catch (e) {
        // Eliminar entrada corrupta de la caché
        await _cacheBox.delete(hashKey);
        throw JsonCacheException(
            'Error decoding JSON for key: $key. Entry removed from cache.',
            originalException: e);
      }
      // ...
      if (!_isExpired(information)) {
        information.updatedAt = DateTime.now();
        information.expiryDays = expiryDays ?? _defaultExpiryDays;
        try {
          await _cacheBox.put(
            hashKey,
            // Re-encode para actualizar updatedAt
            jsonEncode(information.toJson()),
          );
        } catch (e) {
          // En este caso, el error al re-encode no debe impedir la devolución
          // de los datos (antiguos pero válidos). Aquí seguimos adelante.
          debugPrint(
              'Error re-encoding data to JSON after update for key: $key. Error: $e');
        }
        return information.data['data'] as T;
      } else {
        await _cacheBox.delete(hashKey);
      }
    }
    return null;
  }

  /// Almacena la ruta de un archivo en la caché.
  ///
  /// Asocia la ruta del archivo con una URL única y la guarda en la caché.
  /// La ruta del archivo se elimina automáticamente después de `expiryDays` días.
  ///
  /// Parámetros:
  ///   - `url`: La URL única para identificar el archivo.
  ///   - `path`: La ruta local del archivo a cachear.
  ///   - `expiryDays`: (Opcional) Número de días hasta que la ruta del archivo expire.
  ///     Por defecto es `_defaultExpiryDays = 7`.
  ///
  /// Ejemplo:
  /// ```dart
  /// await JCacheManager.setFile(
  ///   url: 'https://example.com/miArchivo',
  ///   path: '/ruta/local/mi_archivo.png',
  /// );
  /// ```
  static Future<void> setFile({
    required String url,
    required String path,
    int? expiryDays,
  }) async {
    final hashKey = _generateHashKey(url);
    final datetime = DateTime.now();
    try {
      await _cacheBox.put(
        hashKey,
        jsonEncode(JCacheManagerData(
          originalKey: url,
          data: {
            'key': url,
            _defaultResourceUrl: url,
            _defaultResourcePath: path,
          },
          expiryDays: expiryDays ?? _defaultExpiryDays,
          dataType: JCacheManagerDataType.file,
          createdAt: datetime,
          updatedAt: datetime,
        ).toJson()),
      );
    } on FormatException catch (e) {
      throw JsonCacheException('Error encoding file data to JSON for URL: $url',
          originalException: e);
    }
  }

  /// Recupera la ruta de un archivo desde la caché.
  ///
  /// Devuelve la ruta del archivo asociada a la URL especificada. Si la ruta
  /// ha expirado o no existe, o si el archivo local ya no existe, se devuelve `null`.
  ///
  /// Parámetros:
  ///   - `url`: La URL única del archivo a recuperar.
  ///   - `expiryDays`: (Opcional) Nuevo tiempo de expiración para la ruta del archivo.
  ///     Si se proporciona, actualiza el tiempo de expiración del registro.
  ///     Por defecto es `_defaultExpiryDays = 7`.
  ///
  /// Devoluciones:
  ///   - La ruta del archivo (tipo `String`), o `null` si no existe, ha expirado,
  ///     o el archivo local ya no está presente.
  ///
  /// Ejemplo:
  /// ```dart
  /// String? rutaArchivo = await JCacheManager.getFile('https://example.com/miArchivo');
  /// if (rutaArchivo != null) {
  ///   print('Ruta del archivo recuperada: $rutaArchivo');
  /// } else {
  ///   print('Ruta del archivo no encontrada o expirada.');
  /// }
  /// ```
  static Future<String?> getFile(
    String url, {
    int? expiryDays,
  }) async {
    final hashKey = _generateHashKey(url);
    final jsonString = _cacheBox.get(hashKey);
    if (jsonString != null) {
      // final archive = JCacheManagerData.fromJson(jsonDecode(jsonString));
      JCacheManagerData? archive;
      try {
        archive = JCacheManagerData.fromJson(jsonDecode(jsonString));
      } on FormatException catch (e) {
        await _cacheBox.delete(hashKey);
        throw JsonCacheException(
            'Error decoding JSON for file URL: $url. Entry removed from cache.',
            originalException: e);
      }
      final filePath = archive.data[_defaultResourcePath] as String;
      final file = File(filePath);
      if (!_isExpired(archive)) {
        try {
          if (await file.exists()) {
            archive.updatedAt = DateTime.now();
            archive.expiryDays = expiryDays ?? _defaultExpiryDays;
            try {
              await _cacheBox.put(hashKey, jsonEncode(archive.toJson()));
            } catch (e) {
              debugPrint(
                  'Error re-encoding data to JSON after update for key: $url. Error: $e');
            }
            return filePath;
          } else {
            debugPrint(
                'File not found on path: $filePath for the URL: $url. Invalidating cache.');
            await _cacheBox.delete(hashKey);
            return null;
          }
        } on FileSystemException catch (e) {
          throw FileCacheException(
              'Error checking file existence at path: $filePath for URL: $url',
              originalException: e);
        }
      } else {
        await _cacheBox.delete(hashKey);
        if (await file.exists()) {
          try {
            await file.delete();
            debugPrint('Expired file deleted: $filePath');
          } catch (e) {
            debugPrint('Error deleting expired file: $e');
          }
        }
      }
    }
    return null;
  }

  /// Elimina un elemento de la caché para la clave especificada.
  ///
  /// Elimina tanto datos como rutas de archivos.
  ///
  /// Parámetros:
  ///   - `key`: La clave del elemento a eliminar.
  ///
  /// Ejemplo:
  /// ```dart
  /// await JCacheManager.remove('miClave');
  /// ```
  static Future<void> remove(String key) async {
    final hashKey = _generateHashKey(key);
    await _cacheBox.delete(hashKey);
  }

  /// Elimina los datos y archivos expirados de la caché.
  ///
  /// Recorre todos los elementos de la caché y elimina aquellos que han
  /// excedido su tiempo de expiración. Para los archivos, también intenta
  /// eliminar el archivo físico del sistema de archivos.
  ///
  /// Útil para liberar espacio de almacenamiento y mantener la caché limpia.
  ///
  /// Ejemplo:
  /// ```dart
  /// await JCacheManager.garbageCollector();
  /// ```
  static Future<void> garbageCollector() async {
    // Obtener la lista de las claves para evitar problemas de
    // modificación concurrente
    final keys = _cacheBox.keys.toList();
    // Iteración asíncrona para evitar bloqueos de UI
    await Future.forEach<dynamic>(keys, (key) async {
      final jsonString = _cacheBox.get(key);
      if (jsonString != null) {
        final value = JCacheManagerData.fromJson(jsonDecode(jsonString));
        final filePath = value.data[_defaultResourcePath] as String;
        if (_isExpired(value)) {
          await _cacheBox.delete(key);
          if (value.dataType == JCacheManagerDataType.file) {
            final file = File(filePath);
            if (await file.exists()) {
              try {
                await file.delete();
                debugPrint('Expired file deleted: $filePath');
              } catch (e) {
                debugPrint('Error deleting expired file: $e');
              }
            }
          }
        }
      }
    });
  }

  /// Libera los recursos utilizados por la caché.
  ///
  /// Debe ser llamado cuando la aplicación se cierra o cuando la caché ya no
  /// es necesaria para liberar recursos como conexiones a la base de datos.
  ///
  /// Ejemplo:
  /// ```dart
  /// await JCacheManager.dispose();
  /// ```
  static Future<void> dispose() async {
    // Cerrar la caja cuando ya no se necesite
    await _cacheBox.close();
  }

  /// Elimina todos los datos de la caché.
  ///
  /// Borra completamente todos los elementos almacenados en la caché, tanto
  /// datos como rutas de archivos.
  ///
  /// Útil para liberar espacio de almacenamiento o resetear la caché.
  ///
  /// Ejemplo:
  /// ```dart
  /// await JCacheManager.clear();
  /// ```
  static Future<void> clear() async {
    await _cacheBox.clear();
  }

  /// Imprime información detallada de un registro específico de la caché.
  ///
  /// Útil para depuración e inspección del contenido de la caché.
  ///
  /// Parámetros:
  ///   - `key`: La clave del registro a imprimir.
  ///
  /// Ejemplo:
  /// ```dart
  /// JCacheManager.print('miClave');
  /// ```
  ///
  /// Nota: La información se imprime en la consola de depuración.
  /// Si el registro no existe o ha expirado, no se imprime nada.
  static void print(String key) {
    final hashKey = _generateHashKey(key);
    final jsonString = _cacheBox.get(hashKey);
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
