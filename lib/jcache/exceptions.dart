// Excepciones personalizadas

/// Excepción lanzada cuando ocurre un error de serialización o
/// deserialización JSON.
class JsonCacheException implements Exception {
  final String message;
  final dynamic originalException;

  JsonCacheException(this.message, {this.originalException});

  @override
  String toString() {
    return 'JsonCacheException: $message${originalException != null ? ' (Original Exception: $originalException)' : ''}';
  }
}

/// Excepción lanzada cuando ocurre un error relacionado con el sistema de
/// archivos al operar con la caché de archivos.
class FileCacheException implements Exception {
  final String message;
  final dynamic originalException;

  FileCacheException(this.message, {this.originalException});

  @override
  String toString() {
    return 'FileCacheException: $message${originalException != null ? ' (Original Exception: $originalException)' : ''}';
  }
}
