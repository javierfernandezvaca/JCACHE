# JCACHE

## Descripción

**JCache** es un paquete de Flutter que proporciona una solución completa para el almacenamiento en caché de archivos y datos. Puede manejar archivos de cualquier tipo, ya sean locales o descargados de Internet, y permite definir un tiempo de expiración para los archivos y datos en caché.

Además, este poderoso paquete puede ser utilizado como una solución de almacenamiento local, al puro estilo `clave`, `valor`.

## Características

- `Almacenamiento en caché de archivos`: **JCache** puede almacenar en caché archivos de cualquier tipo. Los archivos pueden ser locales o descargados de Internet.

- `Almacenamiento en caché de datos`: Además de los archivos; **JCache** también puede almacenar en caché datos en formato `JSON`.

- `Expiración de los archivos y datos`: Puedes definir un tiempo de expiración personalizado para cada archivo y dato en caché. Después de este tiempo, los archivos y datos se consideran obsoletos y se eliminan de la caché.

- `JCacheWidget`: Este es un poderoso y flexible widget encargado de obtener un archivo desde la caché. Proporciona una interfaz fácil de usar para descargar y cachear archivos en una aplicación Flutter.

- `JCacheManager`: Esta es la clase administradora de la caché. Se encarga de todas las operaciones de caché, como almacenar, recuperar y eliminar archivos y datos obsoletos.

## Instalación

Añada la librería **JCACHE** a su archivo `pubspec.yaml`:

```yaml
dependencies:
  jcache:
```

## Uso
Ejemplo básico de cómo cachear un archivo de imagen:

```dart
import 'package:jcache/jcache.dart';

// ...

JCacheWidget(
  url: 'https://example.com/image.png',
  expiryInDays: 5,
  onDownloading: (event, controller) {
    return const CircularProgressIndicator();
  },
  onCompleted: (event, controller) {
    File archive = File(event.path!);
    return Image.file(archive);
  },
  onError: (event, controller) {
    return const Text('Error...');
  },
  onCancelled: (event, controller) {
    return const Text('Cancelled...');
  },
  onInitialized: (event, controller) {
    return const Icon(Icons.image);
  },
);
```

Ejemplo de cómo almacenar y recuperar datos en la caché:

```dart
import 'package:jcache/jcache.dart';

// ...

final customKey = 'user-data';

final customData = {
  'name': 'Jhon',
  'lastName': 'Doe',
  'age': 35,
};

// ...

// Write Data
await JCacheManager.cacheData(
  key: customKey,
  value: customData,
  expiryInDays: 3,
);

// Read Data
final data = await JCacheManager.getCachedData(customKey);
print(data);
```
## Resumen

**JCache** es excelente en el manejo de la caché. Con su capacidad para almacenar en caché tanto archivos como datos, se convierte en una herramienta indispensable para cualquier desarrollador de Flutter.

Además con su widget especializado `JCacheWidget`, te proporciona una interfaz fácil de usar para descargar y cachear archivos en tu aplicación Flutter. Y con su clase `JCacheManager`, tienes un administrador de caché que se encarga de todas las operaciones de caché, desde almacenar datos hasta recuperarlos y eliminar los datos obsoletos.

**JCache** no solo mejora la eficiencia de tu aplicación al reducir la necesidad de descargas repetidas, sino que también mejora la experiencia del usuario al proporcionar un acceso más rápido a los datos y archivos que necesita.

Este es un paquete que te ofrece un control completo sobre el almacenamiento en caché en tus aplicaciones Flutter. Es una herramienta poderosa, flexible y fácil de usar que puede llevar tus aplicaciones al siguiente nivel.

Así que, te invitamos a probar `JCache`; seguro que te encantará la facilidad y la flexibilidad que ofrece. ¡Feliz codificación!