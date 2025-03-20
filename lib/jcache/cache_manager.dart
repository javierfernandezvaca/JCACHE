import 'dart:developer';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:jcache/jcache/exceptions.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cryptography/cryptography.dart' as cryptography;

import 'cache_manager_data.dart';

/// **Clase `JCacheManager` para la gestión de caché en Flutter.**
///
/// Proporciona una interfaz completa para almacenar y recuperar eficientemente
/// datos y archivos en caché dentro de aplicaciones Flutter, utilizando
/// `Hive` para una persistencia rápida y confiable en el dispositivo.
///
/// **Características Principales:**
///
/// - **Persistencia Robusta:**  Utiliza `Hive`, una base de datos NoSQL ligera,
///     para almacenar la caché de manera persistente en el almacenamiento local
///     del dispositivo, asegurando que los datos persistan entre sesiones de la
///     aplicación.
/// - **Soporte Versátil para Datos y Archivos:**  Permite cachear tanto datos
///     serializables (como objetos JSON, Maps, Listas, Strings, etc.) mediante
///     `setData` y `getData`, como rutas a archivos locales (imágenes, documentos,
///     etc.) utilizando `setFile` y `getFile`.
/// - **Sistema de Expiración Inteligente:** Implementa un mecanismo de expiración
///     basado en tiempo configurable. Los datos y archivos en caché se eliminan
///     automáticamente después de un período definido (`expiryDuration`), ayudando a
///     mantener la caché limpia y optimizada en términos de espacio.
/// - **Generación Segura de Claves Hash:** Emplea el algoritmo SHA-256 para
///     generar claves hash únicas a partir de las claves proporcionadas por el
///     usuario. Esto garantiza la unicidad de las claves dentro de la caché y
///     proporciona una ofuscación básica de las claves originales.
/// - **Recolector de Basura Automático:** Incluye un recolector de basura
///     (`garbageCollector`) que se ejecuta periódicamente (en la inicialización
///     y puede ser llamado manualmente) para eliminar elementos expirados y
///     archivos asociados, liberando espacio de almacenamiento y manteniendo
///     la caché eficiente.
/// - **Observación Reactiva de Cambios:** Ofrece la capacidad de observar cambios
///     en elementos específicos de la caché a través de `Stream`s. La función
///     `watch` permite a los componentes de la aplicación reaccionar en tiempo
///     real a las modificaciones o eliminaciones de datos en caché.
/// - **Manejo Excepcional de Errores:** Incorpora un manejo de errores robusto
///     con excepciones personalizadas (`JsonCacheException`, `FileCacheException`)
///     para operaciones críticas como la serialización/deserialización JSON y
///     operaciones del sistema de archivos, facilitando la detección y gestión
///     de problemas.
/// - **Encriptación Opcional de Valores:** Permite habilitar la encriptación de los
///     valores almacenados en caché para proteger la confidencialidad de los datos
///     sensibles. La encriptación se basa en AES-256 y utiliza una clave derivada
///     de una cadena de texto (`encryptionKey`) proporcionada en la inicialización.
///
/// **Uso Principal:**
///
/// `JCacheManager` es ideal para mejorar el rendimiento de aplicaciones Flutter
/// que requieren acceso frecuente a datos o archivos que no cambian
/// constantemente. Almacenar en caché respuestas de APIs, configuraciones,
/// imágenes descargadas u otros recursos puede reducir significativamente la
/// latencia, el uso de ancho de banda y mejorar la experiencia del usuario.
///
/// **Ejemplo de Inicialización:**
///
/// ```dart
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await JCacheManager.init(
///     cacheName: 'miCachePersonalizada',  // Nombre para cache (opcional)
///     defaultExpiryDuration: Duration(days: 15), // Duración de expiración (opcional)
///     encryptionKey: 'MiFraseDePasoSecretaYLarga', // Habilitar encriptación (opcional)
///   );
///   runApp(const MyApp());
/// }
/// ```
class JCacheManager {
  static const String _defaultCacheName = 'J-CACHE-MANAGER-BOX';
  static const String _defaultResourceUrl = 'resourceUrl';
  static const String _defaultResourcePath = 'resourcePath';
  static Duration _defaultExpiryDuration = const Duration(days: 7);
  static bool _initialized = false;
  static late Box<String> _cacheBox;

  static void _checkInitialized() {
    if (!_initialized) {
      throw CacheNotInitializedException(
        'JCacheManager must be initialized with init() before any operations.',
      );
    }
  }

  static String _generateHashKey(String input) {
    final bytes = utf8.encode(input);
    final digest = crypto.sha256.convert(bytes);
    return digest.toString();
  }

  // static Uint8List _deriveKeyFromSeedSimple(String seed) {
  //   final seedBytes = utf8.encode(seed);
  //   final digest = crypto.sha256.convert(seedBytes);
  //   final encryptionKeyBytes = Uint8List.fromList(digest.bytes);
  //   return encryptionKeyBytes;
  // }
  static Future<Uint8List> _deriveKeyFromSeedSimple(String seed) {
    return _deriveKeyWithPBKDF2(seed);
  }

  // ...

  static const String _encryptionSaltKey = 'jcache_encryption_salt';

  static Future<Uint8List> _generateSecureSalt() async {
    final secureRandom = crypto.sha256
        .convert(Uint8List(32))
        .bytes; // Usar SHA-256 para generar bytes aleatorios seguros
    return Uint8List.fromList(
        secureRandom.sublist(0, 16)); // Tomar los primeros 16 bytes como salt
  }

  static Future<Uint8List> _getEncryptionSalt() async {
    // Intentar obtener el salt existente de Hive. Si no existe, generar uno nuevo y guardarlo.
    final existingSaltBase64 = _cacheBox.get(_encryptionSaltKey);
    if (existingSaltBase64 != null) {
      return Uint8List.fromList(base64Decode(existingSaltBase64));
    } else {
      final salt = await _generateSecureSalt();
      _cacheBox.put(
          _encryptionSaltKey, base64Encode(salt)); // Guardar el salt en Hive
      return salt;
    }
  }

  static Future<Uint8List> _deriveKeyWithPBKDF2(String seed) async {
    const iterations =
        100000; // Número de iteraciones PBKDF2 (¡Valor alto para seguridad!)

    // 1. Obtener o generar un Salt único para esta caja de caché
    final salt = await _getEncryptionSalt();

    // 2. Derivar la clave usando PBKDF2 desde el paquete 'cryptography'
    final key = await cryptography.Pbkdf2(
      macAlgorithm:
          // Usar HMAC-SHA256 como función pseudoaleatoria
          cryptography.Hmac.sha256(),
      // Número de iteraciones
      iterations: iterations,
      // Longitud de la clave en bits (32 bytes)
      bits: 256,
    ).deriveKey(
      // Semilla (String convertida a SecretKey)
      secretKey:
          cryptography.SecretKey(utf8.encode(seed)), // ¡Usar el salt generado!
      // nonce: cryptography.SecretNonce(salt),
      nonce: salt,
    );
    return Uint8List.fromList(
        await key.extractBytes()); // Convertir a Uint8List antes de retornar
  }

  // ...

  static bool _isExpired(JCacheManagerData record) {
    return record.updatedAt.add(record.expiryDuration).isBefore(DateTime.now());
  }

  /// **Inicializa `JCacheManager` para su correcto funcionamiento.**
  ///
  /// Este método estático debe ser invocado **una sola vez** al inicio de la
  /// aplicación, preferiblemente antes de utilizar cualquier otra función de
  /// `JCacheManager`. Se encarga de configurar el entorno de caché, incluyendo:
  ///
  /// - Inicialización de `Hive`: Configura el directorio de almacenamiento para
  ///     `Hive`, la base de datos utilizada para la persistencia de la caché.
  /// - Apertura de la Caja de Caché: Abre (o crea si no existe) la caja de `Hive`
  ///     donde se almacenarán los datos de la caché. Se puede personalizar el
  ///     nombre de la caja.
  /// - Configuración de Expiración por Defecto: Permite establecer la duración de
  ///     expiración por defecto para los elementos de la caché. Si no se
  ///     especifica, se utiliza un valor por defecto predefinido.
  /// - Habilitación Opcional de Encriptación: Permite habilitar la encriptación
  ///     de los valores almacenados en la caché. Si se proporciona una cadena de
  ///     texto en el parámetro `encryptionKey`, se derivará una clave de
  ///     encriptación a partir de ella y se utilizará para encriptar los datos
  ///     en Hive. Si `encryptionKey` no se proporciona (es `null`), la caché
  ///     se abrirá sin encriptación.
  /// - Ejecución del Recolector de Basura Inicial: Lanza el recolector de basura
  ///     (`garbageCollector`) para limpiar cualquier entrada expirada que pudiera
  ///     existir de sesiones anteriores.
  ///
  /// **Parámetros Opcionales:**
  ///
  /// - `cacheName`: `String?` (Opcional) - Nombre personalizado para la caja de
  ///     caché de `Hive`. Si no se proporciona, se utiliza el nombre por defecto
  ///     `_defaultCacheName`.
  /// - `defaultExpiryDuration`: `Duration?` (Opcional) - Duración que se utilizará
  ///     como tiempo de expiración por defecto para los elementos de la caché. Si
  ///     no se proporciona, se usa el valor por defecto `_defaultExpiryDuration = 7 días`.
  /// - `encryptionKey`: `String?` (Opcional) - Cadena de texto (semilla) para
  ///     derivar la clave de encriptación AES-256. Si se proporciona, se habilita
  ///     la encriptación de los valores en caché. **¡Advertencia de seguridad!**
  ///     La seguridad de la encriptación depende completamente de la fortaleza
  ///     de esta cadena. Utilice una frase de paso larga y compleja. **Si se
  ///     pierde o se cambia esta clave, los datos encriptados serán irrecuperables.**
  ///
  /// **Ejemplo de Uso:**
  ///
  /// ```dart
  /// void main() async {
  ///   WidgetsFlutterBinding.ensureInitialized();
  ///   await JCacheManager.init(
  ///     cacheName: 'miCachePersonalizada',            // Nombre para cache (opcional)
  ///     defaultExpiryDuration: Duration(days: 15),    // Duración de expiración (opcional)
  ///     encryptionKey: 'MiFraseDePasoSecretaYLarga',  // Habilitar encriptación (opcional)
  ///   );
  ///   runApp(const MyApp());
  /// }
  /// ```
  static Future<void> init({
    String? cacheName,
    Duration? defaultExpiryDuration,
    String? encryptionKey,
  }) async {
    if (!_initialized) {
      final directory = await getApplicationDocumentsDirectory();
      Hive.init(directory.path);
      final boxName = cacheName ?? _defaultCacheName;
      HiveCipher? encryptionCipher;
      if (encryptionKey != null) {
        Uint8List derivedEncryptionKey =
            await _deriveKeyFromSeedSimple(encryptionKey);
        if (derivedEncryptionKey.length != 32) {
          throw ArgumentError(
              'Internal error deriving encryption key. Expected a 32-byte key, but got incorrect length.');
        }
        encryptionCipher = HiveAesCipher(derivedEncryptionKey);
      }
      _cacheBox = await Hive.openBox<String>(
        boxName,
        encryptionCipher: encryptionCipher,
      );
      if (defaultExpiryDuration != null) {
        if (defaultExpiryDuration.isNegative) {
          throw ArgumentError(
              'defaultExpiryDuration cannot be negative. It must be a positive value.');
        }
        _defaultExpiryDuration = defaultExpiryDuration;
      }
      _initialized = true;
      garbageCollector();
    }
  }

  /// **Devuelve el número total de elementos almacenados actualmente en la caché.**
  ///
  /// Esta propiedad getter proporciona acceso al número de entradas que existen
  /// en la caja de caché de `Hive` en el momento de la consulta. Incluye tanto
  /// datos como rutas de archivos que han sido almacenados.
  ///
  /// **Ejemplo de Uso:**
  ///
  /// ```dart
  /// int cantidadItems = JCacheManager.length;
  /// print('La caché contiene $cantidadItems elementos.');
  /// ```
  static int get length {
    _checkInitialized();
    return _cacheBox.length;
  }

  /// **Verifica si la caché está vacía.**
  ///
  /// Esta propiedad getter retorna un valor booleano que indica si la caja de
  /// caché de `Hive` no contiene ningún elemento en su interior.
  ///
  /// **Devoluciones:**
  ///
  /// - `bool` - Retorna `true` si la caché no contiene elementos, `false` si
  ///     contiene al menos un elemento.
  ///
  /// **Ejemplo de Uso:**
  ///
  /// ```dart
  /// bool cacheVacia = JCacheManager.isEmpty;
  /// if (cacheVacia) {
  ///   print('La caché está vacía.');
  /// } else {
  ///   print('La caché contiene elementos.');
  /// }
  /// ```
  static bool get isEmpty {
    _checkInitialized();
    return _cacheBox.isEmpty;
  }

  /// **Verifica si la caché NO está vacía.**
  ///
  /// Esta propiedad getter retorna un valor booleano que indica si la caja de
  /// caché de `Hive` contiene al menos un elemento. Es la negación de `isEmpty`.
  ///
  /// **Devoluciones:**
  ///
  /// - `bool` - Retorna `true` si la caché contiene al menos un elemento, `false`
  ///     si está vacía.
  ///
  /// **Ejemplo de Uso:**
  ///
  /// ```dart
  /// bool cacheNoVacia = JCacheManager.isNotEmpty;
  /// if (cacheNoVacia) {
  ///   print('La caché contiene elementos.');
  /// } else {
  ///   print('La caché está vacía.');
  /// }
  /// ```
  static bool get isNotEmpty {
    _checkInitialized();
    return _cacheBox.isNotEmpty;
  }

  /// **Comprueba si la caché contiene un elemento asociado a la clave especificada.**
  ///
  /// Utiliza la clave proporcionada para generar su clave hash correspondiente
  /// y luego verifica si esta clave hash existe dentro de la caja de caché de
  /// `Hive`. Este método no recupera el elemento, solo verifica su existencia.
  ///
  /// **Parámetros:**
  ///
  /// - `key`: `String` - La clave del elemento cuya existencia se desea comprobar.
  ///
  /// **Devoluciones:**
  ///
  /// - `bool` - Retorna `true` si la caché contiene un elemento con la clave
  ///     especificada, `false` en caso contrario.
  ///
  /// **Ejemplo de Uso:**
  ///
  /// ```dart
  /// bool existeElemento = JCacheManager.contains('miClave');
  /// if (existeElemento) {
  ///   print('La caché contiene un elemento con la clave "miClave".');
  /// } else {
  ///   print('La caché NO contiene un elemento con la clave "miClave".');
  /// }
  /// ```
  static bool contains(String key) {
    _checkInitialized();
    return _cacheBox.containsKey(_generateHashKey(key));
  }

  /// **Observa los cambios en un elemento específico de la caché mediante un `Stream`.**
  ///
  /// Devuelve un `Stream` que emite eventos (`JCacheManagerData?`) cada vez que
  /// el elemento asociado a la clave especificada se modifica o elimina de la
  /// caché. Esto permite una observación reactiva de los cambios en la caché.
  ///
  /// **Parámetros:**
  ///
  /// - `key`: `String` - La clave del elemento de caché cuyos cambios se desean observar.
  ///
  /// **Devoluciones:**
  ///
  /// - `Stream<JCacheManagerData?>` - Un `Stream` que emite eventos de tipo
  ///     `JCacheManagerData?`. Cada evento representa un cambio en el elemento
  ///     de caché:
  ///     - Emite un objeto `JCacheManagerData` cuando el elemento se modifica.
  ///     - Emite `null` cuando el elemento es eliminado de la caché.
  ///
  /// **Ejemplo de Uso:**
  ///
  /// ```dart
  /// Stream<JCacheManagerData?> streamDeDatos = JCacheManager.watch('miClave');
  /// streamDeDatos.listen((evento) {
  ///   if (evento != null) {
  ///     print('Dato cambiado: ${evento.data}');
  ///   } else {
  ///     print('Dato eliminado de la caché');
  ///   }
  /// });
  /// ```
  ///
  /// **Nota:**
  ///
  /// El `Stream` permanece activo y emitirá eventos para futuros cambios en el
  /// elemento de caché hasta que se cancele la suscripción al `Stream`.
  static Stream<JCacheManagerData?> watch(String key) {
    _checkInitialized();
    final hashKey = _generateHashKey(key);
    return _cacheBox.watch(key: hashKey).map((BoxEvent event) {
      final jsonString = event.value;
      if (jsonString == null) {
        return null;
      } else {
        try {
          final e = JCacheManagerData.fromJson(jsonDecode(jsonString));
          return e;
        } on FormatException catch (e) {
          debugPrint(
              'JCacheManager: [watch] Error decoding JSON for key: "$key" in stream. FormatException: $e');
          return null;
        } catch (e) {
          debugPrint(
              'JCacheManager: [watch] Unexpected error processing stream event for key: "$key". Error: $e');
          return null;
        }
      }
    });
  }

  /// **Devuelve una lista de las claves originales (no hash) de todos los elementos en la caché.**
  ///
  /// Recorre todas las claves hash almacenadas en la caja de caché de `Hive`,
  /// deserializa cada entrada para obtener el registro `JCacheManagerData`
  /// asociado y extrae la clave original (`originalKey`) de cada registro.
  ///
  /// **Devoluciones:**
  ///
  /// - `Future<List<String>>` - Un `Future` que se completa con una lista de
  ///     cadenas de texto. Cada cadena en la lista representa una clave original
  ///     de un elemento actualmente presente en la caché.
  ///
  /// **Ejemplo de Uso:**
  ///
  /// ```dart
  /// List<String> claves = await JCacheManager.getKeys();
  /// if (claves.isNotEmpty) {
  ///   print('Claves en la caché: ${claves.join(', ')}');
  /// } else {
  ///   print('La caché no contiene elementos.');
  /// }
  /// ```
  ///
  /// **Nota:**
  ///
  /// Este método realiza operaciones de lectura y deserialización para cada
  /// elemento en la caché. Para cachés muy grandes, podría tener un impacto
  /// en el rendimiento, por lo que se recomienda usar con moderación,
  /// principalmente para propósitos de depuración o gestión manual.
  static Future<List<String>> getKeys() async {
    _checkInitialized();
    List<String> originalKeys = [];
    for (var hashKey in _cacheBox.keys) {
      final jsonString = _cacheBox.get(hashKey as String);
      if (jsonString != null) {
        try {
          final record = JCacheManagerData.fromJson(jsonDecode(jsonString));
          originalKeys.add(record.originalKey);
        } catch (e) {
          debugPrint(
              'JCacheManager: [getKeys] Corrupt entry detected for hashKey: $hashKey. Error: $e');
        }
      }
    }
    return originalKeys;
  }

  /// **Almacena datos serializables en la caché.**
  ///
  /// Serializa el valor proporcionado a formato JSON y lo almacena en la caché
  /// asociado a la clave especificada. Los datos se almacenan de forma
  /// persistente utilizando `Hive` y se eliminarán automáticamente de la
  /// caché después de un período definido por `expiryDuration`.
  ///
  /// **Tipos de Datos Soportados:**
  ///
  /// El tipo de dato `T` del parámetro `value` debe ser serializable a JSON.
  /// Esto incluye tipos primitivos (String, int, double, bool), `List`, `Map`
  /// y objetos personalizados que puedan ser convertidos a JSON mediante
  /// `jsonEncode`.
  ///
  /// **Parámetros:**
  ///
  /// - `key`: `String` - La clave única bajo la cual se almacenarán los datos.
  ///     Esta clave será utilizada posteriormente para recuperar los datos.
  /// - `value`: `T` - El dato que se desea almacenar en la caché. Debe ser de un
  ///     tipo serializable a JSON.
  /// - `expiryDuration`: `Duration?` (Opcional) - Duración después de la cual los
  ///     datos almacenados se considerarán expirados y serán eliminados por el
  ///     recolector de basura. Si no se especifica, se utiliza el valor por defecto
  ///     `_defaultExpiryDuration`.
  ///
  /// **Ejemplos de Uso:**
  ///
  /// ```dart
  /// // Almacenando un Map<String, dynamic>
  /// await JCacheManager.setData<Map<String, dynamic>>(
  ///   key: 'datosUsuario',
  ///   value: {'nombre': 'Juan', 'edad': 30},
  ///   expiryDuration: Duration(hours: 2), // Expira en 2 horas
  /// );
  ///
  /// // Almacenando un String
  /// await JCacheManager.setData<String>(
  ///   key: 'nombreUsuario',
  ///   value: 'Juan Perez',
  ///   expiryDuration: Duration(days: 30), // Expira en 30 días
  /// );
  /// ```
  ///
  /// **Excepciones:**
  ///
  /// - `JsonCacheException`: Se lanza si ocurre un error durante la
  ///     serialización del `value` a formato JSON.
  static Future<void> setData<T>({
    required String key,
    required T value,
    Duration? expiryDuration,
  }) async {
    _checkInitialized();
    if (expiryDuration != null && expiryDuration.isNegative) {
      throw ArgumentError(
          'expiryDuration cannot be negative. It must be a positive value.');
    }
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
        expiryDuration: expiryDuration ?? _defaultExpiryDuration,
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

  /// **Recupera datos de la caché asociados a una clave específica.**
  ///
  /// Busca en la caché un elemento asociado a la clave proporcionada. Si se
  /// encuentra un elemento válido (no expirado), lo deserializa desde formato
  /// JSON y lo devuelve. Si el elemento no existe, ha expirado o no puede
  /// ser deserializado, se devuelve `null`.
  ///
  /// **Parámetros:**
  ///
  /// - `key`: `String` - La clave única de los datos que se desean recuperar.
  /// - `expiryDuration`: `Duration?` (Opcional) - Nueva duración de expiración para los datos
  ///     recuperados. Si se proporciona, se actualiza el tiempo de expiración del
  ///     registro en la caché, extendiendo su validez por la duración
  ///     especificada. Si no se proporciona, se mantiene la duración de expiración
  ///     original o el valor por defecto `_defaultExpiryDuration` si no se había
  ///     establecido previamente.
  ///
  /// **Devoluciones:**
  ///
  /// - `Future<T?>` - Un `Future` que se completa con el dato deserializado de
  ///     tipo `T` si se encuentra un elemento válido para la clave especificada.
  ///     Retorna `null` en los siguientes casos:
  ///     - No existe ningún elemento asociado a la clave en la caché.
  ///     - El elemento existente ha expirado.
  ///     - Ocurre un error durante la deserialización JSON del elemento.
  ///
  /// **Ejemplos de Uso:**
  ///
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
  ///
  /// **Excepciones:**
  ///
  /// - `JsonCacheException`: Se lanza si ocurre un error durante la
  ///     deserialización del valor JSON desde la caché. En este caso, la entrada
  ///     corrupta se elimina automáticamente de la caché.
  static Future<T?> getData<T>(
    String key, {
    Duration? expiryDuration,
  }) async {
    _checkInitialized();
    if (expiryDuration != null && expiryDuration.isNegative) {
      throw ArgumentError(
          'expiryDuration cannot be negative. It must be a positive value.');
    }
    final hashKey = _generateHashKey(key);
    final jsonString = _cacheBox.get(hashKey);
    // ...
    if (jsonString != null) {
      JCacheManagerData? information;
      try {
        information = JCacheManagerData.fromJson(jsonDecode(jsonString));
      } on FormatException catch (e) {
        debugPrint(
            'JCacheManager: [getData] Error decoding JSON for key: "$key". FormatException: $e');
        // Eliminar entrada corrupta de la caché
        await _cacheBox.delete(hashKey);
        throw JsonCacheException(
            'Error decoding JSON for key: $key. Entry removed from cache.',
            originalException: e);
      }
      // ...
      if (!_isExpired(information)) {
        information.updatedAt = DateTime.now();
        information.expiryDuration = expiryDuration ?? _defaultExpiryDuration;
        try {
          await _cacheBox.put(
            hashKey,
            // Re-encode para actualizar updatedAt
            jsonEncode(information.toJson()),
          );
        } catch (e) {
          debugPrint(
              'JCacheManager: [getData] Metadata update failed for key: "$key" after data retrieval. Data retrieval successful, but update to cache entry may have failed. Error: $e');
        }
        return information.data['data'] as T;
      } else {
        await _cacheBox.delete(hashKey);
      }
    }
    return null;
  }

  /// **Almacena la ruta a un archivo local en la caché, asociado a una URL única.**
  ///
  /// Asocia una URL única con la ruta local de un archivo y guarda esta
  /// información en la caché. Esto es útil para cachear la ubicación de
  /// archivos descargados o generados localmente, utilizando la URL como clave
  /// para su posterior recuperación. La ruta del archivo se almacenará
  /// de forma persistente y estará sujeta a expiración.
  ///
  /// **Parámetros:**
  ///
  /// - `url`: `String` - La URL única que se utilizará como clave para identificar
  ///     y recuperar la ruta del archivo en caché. Idealmente, debería ser la URL
  ///     de origen del archivo o un identificador único relacionado.
  /// - `path`: `String` - La ruta local del archivo que se desea cachear. Debe
  ///     ser una ruta válida en el sistema de archivos del dispositivo.
  /// - `expiryDuration`: `Duration?` (Opcional) - Duración después de la cual la
  ///     entrada de la ruta del archivo en caché se considerará expirada. Tras
  ///     la expiración, la entrada podrá ser eliminada por el recolector de basura.
  ///     Si no se especifica, se utiliza el valor por defecto `_defaultExpiryDuration`.
  ///
  /// **Ejemplo de Uso:**
  ///
  /// ```dart
  /// await JCacheManager.setFile(
  ///   url: 'https://example.com/miArchivo',
  ///   path: '/ruta/local/mi_archivo.png',
  ///   expiryDuration: Duration(hours: 12), // Expira en 12 horas
  /// );
  /// ```
  ///
  /// **Excepciones:**
  ///
  /// - `JsonCacheException`: Se lanza si ocurre un error durante la
  ///     serialización de los datos de la ruta del archivo a formato JSON.
  static Future<void> setFile({
    required String url,
    required String path,
    Duration? expiryDuration,
  }) async {
    _checkInitialized();
    if (expiryDuration != null && expiryDuration.isNegative) {
      throw ArgumentError(
          'expiryDuration cannot be negative. It must be a positive value.');
    }
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
          expiryDuration: expiryDuration ?? _defaultExpiryDuration,
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

  /// **Recupera la ruta a un archivo local desde la caché, utilizando su URL asociada.**
  ///
  /// Busca en la caché la ruta de un archivo local que fue previamente
  /// almacenada utilizando la URL especificada como clave. Si se encuentra una
  /// entrada válida (no expirada) y el archivo local aún existe en la ruta
  /// especificada, se devuelve la ruta del archivo. En caso contrario, se
  /// devuelve `null`.
  ///
  /// **Proceso de Recuperación y Validación:**
  ///
  /// 1. **Búsqueda en Caché:** Se busca la entrada en la caché utilizando la URL
  ///    proporcionada, generando su clave hash correspondiente.
  /// 2. **Deserialización y Expiración:** Si se encuentra una entrada, se
  ///    deserializa desde JSON y se verifica si ha expirado (`_isExpired`).
  /// 3. **Verificación de Existencia del Archivo:** Si la entrada no ha expirado,
  ///    se verifica que el archivo local aún exista en la ruta almacenada.
  /// 4. **Retorno de la Ruta o `null`:** Si todas las verificaciones son exitosas,
  ///    se devuelve la ruta del archivo. De lo contrario, se devuelve `null`
  ///    y la entrada en caché se invalida (se elimina).
  ///
  /// **Parámetros:**
  ///
  /// - `url`: `String` - La URL única del archivo cuya ruta local se desea
  ///     recuperar desde la caché. Debe ser la misma URL utilizada al
  ///     almacenar la ruta con `setFile`.
  /// - `expiryDuration`: `Duration?` (Opcional) - Nueva duración de expiración para la ruta
  ///     del archivo recuperada. Si se proporciona, se actualiza el tiempo de
  ///     expiración del registro en la caché, extendiendo su validez. Si no se
  ///     proporciona, se mantiene la duración de expiración original o el valor
  ///     por defecto `_defaultExpiryDuration` si no se había establecido previamente.
  ///
  /// **Devoluciones:**
  ///
  /// - `Future<String?>` - Un `Future` que se completa con la ruta del archivo
  ///     (tipo `String`) si se encuentra una entrada válida en la caché y el
  ///     archivo local existe. Retorna `null` en los siguientes casos:
  ///     - No existe ninguna entrada en caché para la URL especificada.
  ///     - La entrada en caché ha expirado.
  ///     - El archivo local en la ruta almacenada ya no existe.
  ///     - Ocurre un error durante la deserialización JSON de la entrada.
  ///
  /// **Ejemplo de Uso:**
  ///
  /// ```dart
  /// String? rutaArchivo = await JCacheManager.getFile('https://example.com/miArchivo');
  /// if (rutaArchivo != null) {
  ///   print('Ruta del archivo recuperada: $rutaArchivo');
  /// } else {
  ///   print('Ruta del archivo no encontrada o expirada.');
  /// }
  /// ```
  ///
  /// **Excepciones:**
  ///
  /// - `JsonCacheException`: Se lanza si ocurre un error durante la
  ///     deserialización del valor JSON desde la caché. En este caso, la entrada
  ///     corrupta se elimina automáticamente de la caché.
  /// - `FileCacheException`: Se lanza si ocurre un error del sistema de archivos
  ///     al intentar verificar la existencia del archivo local en la ruta
  ///     almacenada.
  static Future<String?> getFile(
    String url, {
    Duration? expiryDuration,
  }) async {
    _checkInitialized();
    if (expiryDuration != null && expiryDuration.isNegative) {
      throw ArgumentError(
          'expiryDuration cannot be negative. It must be a positive value.');
    }
    final hashKey = _generateHashKey(url);
    final jsonString = _cacheBox.get(hashKey);
    if (jsonString != null) {
      // final archive = JCacheManagerData.fromJson(jsonDecode(jsonString));
      JCacheManagerData? archive;
      try {
        archive = JCacheManagerData.fromJson(jsonDecode(jsonString));
      } on FormatException catch (e) {
        debugPrint(
            'JCacheManager: [getFile] Error decoding JSON for file URL: "$url". FormatException: $e');
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
            archive.expiryDuration = expiryDuration ?? _defaultExpiryDuration;
            try {
              await _cacheBox.put(hashKey, jsonEncode(archive.toJson()));
            } catch (e) {
              debugPrint(
                  'JCacheManager: [getFile] Metadata update failed for URL: "$url" after file retrieval. File retrieval successful, but update to cache entry may have failed. Error: $e');
            }
            return filePath;
          } else {
            debugPrint(
                'JCacheManager: [getFile] File not found on path: $filePath for the URL: $url. Invalidating cache.');
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
            debugPrint(
                'JCacheManager: [getFile] Expired file deleted: $filePath');
          } catch (e) {
            debugPrint(
                'JCacheManager: [getFile] Error deleting expired file: $e');
          }
        }
      }
    }
    return null;
  }

  /// **Elimina un elemento de la caché, identificado por su clave.**
  ///
  /// Busca y elimina de la caja de caché de `Hive` el elemento asociado a la
  /// clave especificada. Este método puede utilizarse para invalidar
  /// manualmente entradas de caché, ya sean datos o rutas de archivos.
  ///
  /// **Parámetros:**
  ///
  /// - `key`: `String` - La clave del elemento que se desea eliminar de la caché.
  ///
  /// **Ejemplo de Uso:**
  ///
  /// ```dart
  /// await JCacheManager.remove('miClave');
  /// print('Elemento con clave "miClave" eliminado de la caché.');
  /// ```
  ///
  /// **Nota:**
  ///
  /// La eliminación es permanente. Una vez que el elemento es eliminado,
  /// necesitará ser re-almacenado en la caché si se requiere nuevamente.
  static Future<void> remove(String key) async {
    _checkInitialized();
    final hashKey = _generateHashKey(key);
    await _cacheBox.delete(hashKey);
  }

  /// **Ejecuta el recolector de basura para eliminar elementos expirados de la caché.**
  ///
  /// Este método realiza una limpieza de la caché, recorriendo todos los
  /// elementos almacenados y eliminando aquellos que han excedido su tiempo
  /// de expiración (`expiryDuration`). Para las entradas que representan rutas de
  /// archivos, también intenta eliminar el archivo físico del sistema de
  /// archivos, liberando espacio de almacenamiento.
  ///
  /// **Funcionamiento del Recolector de Basura:**
  ///
  /// 1. **Iteración de Claves:** Obtiene una lista de todas las claves presentes
  ///    en la caja de caché de `Hive`.
  /// 2. **Verificación de Expiración:** Para cada clave, recupera la entrada
  ///    correspondiente, la deserializa y verifica si ha expirado utilizando
  ///    `_isExpired`.
  /// 3. **Eliminación de Entradas Expiradas:** Si una entrada ha expirado, se
  ///    elimina de la caja de caché.
  /// 4. **Eliminación de Archivos Expirados (para rutas de archivos):** Si la
  ///    entrada expirada representa una ruta de archivo, se intenta eliminar
  ///    el archivo físico en la ruta especificada. Los errores durante la
  ///    eliminación del archivo se registran pero no detienen el proceso.
  /// 5. **Registro de Resultados:** Al finalizar, registra un resumen de la
  ///    operación, indicando cuántas entradas y archivos fueron eliminados.
  ///
  /// **Ejemplo de Uso:**
  ///
  /// ```dart
  /// await JCacheManager.garbageCollector();
  /// print('Recolector de basura ejecutado. Entradas expiradas eliminadas.');
  /// ```
  ///
  /// **Nota:**
  ///
  /// Se recomienda ejecutar el recolector de basura periódicamente, especialmente
  /// en aplicaciones que hacen un uso intensivo de la caché, para mantenerla
  /// optimizada y evitar el consumo excesivo de espacio de almacenamiento.
  static Future<void> garbageCollector() async {
    _checkInitialized();
    // Obtener la lista de las claves para evitar problemas de
    // modificación concurrente
    final keys = _cacheBox.keys.toList();
    // Iteración asíncrona para evitar bloqueos de UI
    await Future.forEach<dynamic>(keys, (key) async {
      final jsonString = _cacheBox.get(key);
      if (jsonString != null) {
        final value = JCacheManagerData.fromJson(jsonDecode(jsonString));
        if (_isExpired(value)) {
          await _cacheBox.delete(key);
          if (value.dataType == JCacheManagerDataType.file) {
            final filePath = value.data[_defaultResourcePath] as String;
            final file = File(filePath);
            if (await file.exists()) {
              try {
                await file.delete();
                debugPrint(
                    'JCacheManager: [garbageCollector] Expired file deleted: $filePath');
              } catch (e) {
                debugPrint(
                    'JCacheManager: [garbageCollector] Error deleting expired file: $filePath. Error: $e');
              }
            }
          }
        }
      }
    });
  }

  /// **Libera los recursos utilizados por la caché al cerrar la caja de `Hive`.**
  ///
  /// Este método debe ser llamado cuando la aplicación se cierra o cuando la
  /// caché ya no es necesaria para liberar recursos del sistema que podrían
  /// estar retenidos por la caja de caché de `Hive`, como conexiones a archivos
  /// o memoria.
  ///
  /// **Ejemplo de Uso:**
  ///
  /// ```dart
  /// await JCacheManager.dispose();
  /// print('Recursos de la caché liberados.');
  /// ```
  ///
  /// **Importante:**
  ///
  /// Después de llamar a `dispose`, la caja de caché no debe ser utilizada
  /// nuevamente sin reinicializar `JCacheManager` con `init()`.
  static Future<void> dispose() async {
    _checkInitialized();
    // Cerrar la caja cuando ya no se necesite
    await _cacheBox.close();
  }

  /// **Elimina TODOS los datos de la caché, vaciando completamente la caja de `Hive`.**
  ///
  /// Borra de forma irreversible todos los elementos almacenados en la caché,
  /// incluyendo tanto datos como rutas de archivos. Esta operación libera
  /// completamente el espacio de almacenamiento utilizado por la caché.
  ///
  /// **Ejemplo de Uso:**
  ///
  /// ```dart
  /// await JCacheManager.clear();
  /// print('Caché completamente vaciada.');
  /// ```
  ///
  /// **Advertencia:**
  ///
  /// Esta operación es destructiva y permanente. Todos los datos en caché se
  /// perderán y no podrán ser recuperados. Utilizar con precaución.
  static Future<void> clear() async {
    _checkInitialized();
    await _cacheBox.clear();
  }

  /// **Imprime información detallada sobre un registro específico de la caché en la consola de depuración.**
  ///
  /// Útil para fines de depuración e inspección del contenido de la caché.
  /// Permite examinar en detalle un elemento de la caché identificado por su
  /// clave, mostrando su tipo, duración de expiración, fechas de creación y
  /// actualización, clave y valor almacenado en formato JSON formateado.
  ///
  /// **Parámetros:**
  ///
  /// - `key`: `String` - La clave del registro de caché cuya información se
  ///     desea imprimir en la consola.
  ///
  /// **Ejemplo de Uso:**
  ///
  /// ```dart
  /// JCacheManager.print('miClave'); // Imprime detalles del elemento con clave 'miClave'
  /// ```
  ///
  /// **Nota:**
  ///
  /// La información se imprime utilizando `dart:developer.log`, que muestra
  /// los datos en la consola de depuración con etiquetas descriptivas. Si no
  /// existe un registro para la clave especificada o si ha expirado, no se
  /// imprime nada.
  static void print(String key) {
    _checkInitialized();
    final hashKey = _generateHashKey(key);
    final jsonString = _cacheBox.get(hashKey);
    if (jsonString != null) {
      JCacheManagerData? record;
      try {
        record = JCacheManagerData.fromJson(jsonDecode(jsonString));
        final data = record.data;
        var encoder = JsonEncoder.withIndent(' ' * 2);
        var formattedJson = encoder.convert(data);
        log(
          record.dataType == JCacheManagerDataType.data ? 'DATA' : 'FILE',
          name: 'JCACHE',
        );
        log(record.expiryDuration.toString(), name: 'Expiry Duration');
        log(record.createdAt.toString(), name: 'Created At');
        log(record.updatedAt.toString(), name: 'Updated At');
        log(key, name: 'Key');
        log(formattedJson, name: 'Value');
      } on FormatException catch (e) {
        debugPrint(
            'JCacheManager: [print] Error decoding JSON for key: "$key". FormatException: $e');
        debugPrint(
            'JCacheManager: [print] Could not print cache entry for key: "$key" due to JSON format error.');
      } catch (e) {
        debugPrint(
            'JCacheManager: [print] Unexpected error while trying to print cache entry for key: "$key". Error: $e');
      }
    } else {
      debugPrint(
          'JCacheManager: [print] No cache entry found for key: "$key".');
    }
  }

  // ...
}
