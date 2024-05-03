# JCACHE

## Descripción

**JCache** es un paquete de Flutter que proporciona una solución completa para el almacenamiento en caché de archivos y datos. Puede manejar archivos de cualquier tipo, ya sean locales o descargados de Internet, y permite definir un tiempo de expiración para los archivos y datos en caché.

Además, este poderoso paquete puede ser utilizado como una solución de almacenamiento local, al puro estilo `clave`, `valor`.

## Características

- `Almacenamiento en caché de archivos`: **JCache** puede almacenar en caché archivos de cualquier tipo. Los archivos pueden ser locales o descargados de Internet.

- `Almacenamiento en caché de datos`: Además de los archivos; **JCache** también puede almacenar en caché datos en formato `JSON`.

- `Expiración de los archivos y datos`: Puedes definir un tiempo de expiración personalizado para cada archivo y dato en caché. Después de este tiempo, los archivos y datos se consideran obsoletos y se eliminan de la caché.

- `JCacheManager`: Esta es la clase administradora de la caché. Se encarga de todas las operaciones de caché, como almacenar, recuperar y eliminar archivos y datos obsoletos.

- `JCacheWidget`: Este es un poderoso y flexible widget encargado de obtener un archivo desde la caché. Proporciona una interfaz fácil de usar para descargar y cachear archivos en una aplicación Flutter.

## Instalación

Añada la librería **JCache** a su archivo `pubspec.yaml`:

```yaml
dependencies:
  jcache:
```

## Uso

En Flutter, la gestión de la caché es una parte esencial para garantizar un 
rendimiento óptimo de la aplicación y una experiencia de usuario fluida. `JCacheManager` y `JCacheWidget` son dos formas eficaces de administrar los datos y archivos en la caché respectivamente.

Para utilizar este complemento despues de haberlo instalado previamente; puede hacerlo de la siguiente manera:

```dart
// Añadir la librería.
import 'package:jcache/jcache.dart';

// ...

// Inicializar la cache.
await JCacheManager.init();

// ...

// Define some example data:

/// Unique key for the user data.
final userKey = 'user';

/// URL of the user's image.
final userImageUrl = 'https://example.com/image.png';

/// Local path of the user's image.
final userImagePath = '/path/local/image.png';

/// Map containing the user's data.
final userData = {
  'name': 'John Doe',
  'age': 35,
  'resourceUrl': userImageUrl,
  'resourcePath': userImagePath,
};
```

### JCacheManager

`JCacheManager` es una clase que proporciona métodos para administrar la caché. Cada dato se almacena con una clave única y tiene un tiempo de expiración, después del cual se elimina automáticamente. Esto permite un manejo eficiente de la memoria y garantiza que los datos no se vuelvan obsoletos.

Para `JCacheManager`, puedes hacer lo siguiente:

```dart
// Store the data in the cache.
await JCacheManager.setData(key: userKey, value: userData);

// Retrieve the data from the cache.
Map<String, dynamic>? data = await JCacheManager.getData(userKey);
```

```dart
// Store the file path in the cache.
await JCacheManager.setFile(url: userImageUrl, path: userImagePath);

// Retrieve the file path from the cache.
String? image = await JCacheManager.getFile(userKey);
```

```dart
// Listen for changes in a record.
Stream<JCacheManagerData> userStream = JCacheManager.watch(userKey);
userStream.listen((event) {
  debugPrint('Data changed: ${event.data}');
});
```

```dart
// Remove a record from the cache.
JCacheManager.remove(userKey);

// Clear all records from the cache.
JCacheManager.clear();
```

```dart
// Get all keys in the cache.
List<String> keys = await JCacheManager.getKeys();

// Print a record from the cache.
JCacheManager.print(userKey);

// And more ...
```

### JCacheWidget

`JCacheWidget` es un widget de Flutter especializado en la descarga y administración en caché de archivos. Este widget es particularmente útil cuando se trabaja con archivos que se descargan de Internet, como imágenes, documentos, audios, videos, entre otros.

Cuando se utiliza `JCacheWidget`, el widget intentará primero recuperar el archivo de la caché local. Si el archivo no está en la caché o ha expirado (según su tiempo de expiración configurado), `JCacheWidget` descargará el archivo de la URL proporcionada y lo almacenará en la caché para su uso futuro. Todo este proceso es óptimo y automático.

Esto tiene varias ventajas:
- Mejora la eficiencia de la red al reducir la cantidad de descargas necesarias.
- Mejora la experiencia del usuario al permitir un acceso más rápido a los archivos ya descargados, incluso cuando el dispositivo está `offline`.

Para `JCacheWidget`, puedes hacer lo siguiente:

```dart
JCacheWidget(
  url: userImageUrl,
  expiryDays: 5,
  onInitialized: (event, controller) {
    return const Icon(Icons.image);
  },
  onDownloading: (event, controller) {
    return const CircularProgressIndicator();
  },
  onCompleted: (event, controller) {
    File archive = File(event.resourcePath!);
    return Image.file(archive);
  },
  onError: (event, controller) {
    return const Text('Error...');
  },
  onCancelled: (event, controller) {
    return const Text('Cancelled...');
  },
);
```

## Resumen

**JCache** es excelente en el manejo de la caché. Con su capacidad para almacenar en caché tanto archivos como datos, se convierte en una herramienta indispensable para cualquier desarrollador de Flutter.

Además con su widget especializado `JCacheWidget`, te proporciona una interfaz fácil de usar para descargar y cachear archivos en tu aplicación Flutter. Y con su clase `JCacheManager`, tienes un administrador de caché que se encarga de todas las operaciones de caché, desde almacenar datos hasta recuperarlos y eliminar los datos obsoletos.

**JCache** no solo mejora la eficiencia de tu aplicación al reducir la necesidad de descargas repetidas, sino que también mejora la experiencia del usuario al proporcionar un acceso más rápido a los datos y archivos que necesita.

Este es un paquete que te ofrece un control completo sobre el almacenamiento en caché en tus aplicaciones Flutter. Es una herramienta poderosa, flexible y fácil de usar que puede llevar tus aplicaciones al siguiente nivel.

Así que, te invitamos a probar `JCache`; seguro que te encantará la facilidad y la flexibilidad que ofrece. ¡Feliz codificación!