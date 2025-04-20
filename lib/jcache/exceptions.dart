// Excepciones personalizadas

/// Excepción lanzada cuando ocurre un error durante la inicialización del sistema de caché.
///
/// `CacheNotInitializedException` se utiliza para indicar que se ha intentado
/// realizar una operación en la caché (como almacenar o recuperar datos) antes
/// de que el sistema de caché haya sido correctamente inicializado.  Esta
/// excepción se lanza típicamente cuando se invoca algún método de [JCacheManager]
/// (excepto `init()`) sin haber llamado previamente al método estático `init()`.
///
/// Indica un error de uso de la librería, sugiriendo que el desarrollador debe
/// asegurar que [JCacheManager.init()] se llame al inicio de la aplicación,
/// antes de cualquier otra operación de caché.
class CacheNotInitializedException implements Exception {
  /// Mensaje descriptivo del error de inicialización de la caché.
  final String message;

  /// Excepción original que causó la excepción de inicialización (opcional).
  final dynamic originalException;

  /// Constructor para crear una instancia de [CacheNotInitializedException].
  ///
  /// Parámetros:
  ///
  /// - `message`: String - Mensaje descriptivo del error. Debe proporcionar
  ///     información clara sobre la causa del problema de inicialización.
  /// - `originalException`: dynamic (Opcional) - Excepción original que
  ///     pudo haber provocado el error de inicialización.  Se utiliza para
  ///     encapsular y propagar la excepción original para fines de depuración
  ///     más detallados.
  CacheNotInitializedException(this.message, {this.originalException});

  @override
  String toString() {
    return 'CacheNotInitializedException: $message${originalException != null ? ' (Original Exception: $originalException)' : ''}';
  }
}

/// Excepción lanzada cuando ocurre un error durante la serialización o deserialización JSON de datos de caché.
///
/// `JsonCacheException` se utiliza para señalar problemas que ocurren al
/// intentar convertir datos a formato JSON (serialización) para almacenarlos
/// en la caché, o al intentar reconstruir datos desde formato JSON
/// (deserialización) al recuperarlos de la caché.
///
/// Este tipo de excepción puede ser lanzada por los métodos [JCacheManager.setData()]
/// al intentar serializar datos a JSON, o por [JCacheManager.getData()],
/// [JCacheManager.getFile()] y [JCacheManager.watch()] al intentar deserializar
/// datos JSON desde la caché.  Indica que ha habido un problema en el manejo
/// de datos en formato JSON, posiblemente debido a datos corruptos en la caché
/// o a errores en el proceso de serialización/deserialización.
class JsonCacheException implements Exception {
  /// Mensaje descriptivo del error de serialización/deserialización JSON.
  final String message;

  /// Excepción original que causó el error de JSON (opcional).
  final dynamic originalException;

  /// Constructor para crear una instancia de [JsonCacheException].
  ///
  /// Parámetros:
  ///
  /// - `message`: String - Mensaje descriptivo del error de JSON. Debe
  ///     indicar la naturaleza del problema de serialización/deserialización.
  /// - `originalException`: dynamic (Opcional) - Excepción original que
  ///     pudo haber provocado el error de JSON (por ejemplo, una [FormatException]).
  ///     Se utiliza para encapsular y propagar la excepción original para
  ///     fines de depuración más detallados.
  JsonCacheException(this.message, {this.originalException});

  @override
  String toString() {
    return 'JsonCacheException: $message${originalException != null ? ' (Original Exception: $originalException)' : ''}';
  }
}

/// Excepción lanzada cuando ocurre un error relacionado con el sistema de archivos al operar con la caché de archivos.
///
/// `FileCacheException` se utiliza para indicar problemas que surgen al
/// realizar operaciones del sistema de archivos que son necesarias para la
/// gestión de la caché de archivos en [JCacheManager].  Esto incluye errores
/// al intentar verificar la existencia de un archivo en caché ([JCacheManager.getFile()]),
/// al intentar eliminar un archivo expirado ([JCacheManager.garbageCollector()],
/// [JCacheManager.getFile()], [JCacheManager.cancelDownload()]), o cualquier
/// otra operación del sistema de archivos relacionada con la caché de archivos.
///
/// Indica que ha habido un problema al interactuar con el sistema de archivos,
/// posiblemente debido a permisos insuficientes, problemas de almacenamiento
/// en disco, archivos no encontrados (en casos inesperados), u otros errores
/// del sistema de archivos.
class FileCacheException implements Exception {
  /// Mensaje descriptivo del error relacionado con el sistema de archivos.
  final String message;

  /// Excepción original del sistema de archivos que causó el error (opcional).
  final dynamic originalException;

  /// Constructor para crear una instancia de [FileCacheException].
  ///
  /// Parámetros:
  ///
  /// - `message`: String - Mensaje descriptivo del error del sistema de archivos.
  ///     Debe indicar la operación del sistema de archivos que falló y la
  ///     naturaleza del problema.
  /// - `originalException`: dynamic (Opcional) - Excepción original del
  ///     sistema de archivos que provocó el error (por ejemplo, [FileSystemException]).
  ///     Se utiliza para encapsular y propagar la excepción original para
  ///     fines de depuración más detallados.
  FileCacheException(this.message, {this.originalException});

  @override
  String toString() {
    return 'FileCacheException: $message${originalException != null ? ' (Original Exception: $originalException)' : ''}';
  }
}
