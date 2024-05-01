# JCACHE

## Descripción

JCache es un paquete de Flutter que proporciona una solución completa para el almacenamiento en caché de archivos y datos JSON. Puede manejar archivos de cualquier tipo, ya sean locales o descargados de Internet, y permite definir un tiempo de expiración para los datos en caché. Además, JCache puede ser utilizado como una solución de almacenamiento local.

## Características

- `Almacenamiento en caché de archivos`: JCache puede almacenar en caché archivos de cualquier tipo. Los archivos pueden ser locales o descargados de Internet.

- `Almacenamiento en caché de datos JSON`: Además de los archivos; JCache también puede almacenar en caché datos JSON.

- `Expiración de los datos`: Puedes definir un tiempo de expiración personalizado para cada dato en caché. Después de este tiempo, los datos se consideran obsoletos y se eliminan de la caché.

- `JCacheWidget`: Este widget es el encargado de obtener un archivo desde la caché. Proporciona una interfaz fácil de usar para descargar y cachear archivos en una aplicación Flutter.

- `JCacheManager`: Esta es la clase administradora de la caché. Se encarga de todas las operaciones de caché, como almacenar datos, recuperar datos y eliminar datos obsoletos.

## Instalación

Añada la librería **JCACHE** a su archivo `pubspec.yaml`:

```yaml
dependencies:
  jcache:
```

## Uso
Aquí tienes un ejemplo básico de cómo usar el paquete JCache:

```dart
JCacheWidget(
  url: 'https://example.com/image.png',
  expiryInDays: 5,
  onDownloading: (event, controller) {
    return CircularProgressIndicator();
  },
  onCompleted: (event, controller) {
    return Image.file(File(event.path!));
  },
  onError: (event, controller) {
    return Text('Error');
  },
  onCancelled: (event, controller) {
    return Text('Cancelled');
  },
  onInitialized: (event, controller) {
    return Text('Initialized');
  },
);
```

Aquí tienes un ejemplo de cómo almacenar y recuperar datos JSON en la caché:

```dart
import 'package:jcache/jcache.dart';

// ...

void cacheUserData() async {
  String customKey = 'user-data';
  // Write Data
  await JCacheManager.cacheData(
    key: customKey,
    value: {
      'name': 'Jhon',
      'lastName': 'Doe',
      'age': 35,
    },
    expiryInDays: 3,
  );
  // Read Data
  final data = await JCacheManager.getCachedData(customKey);
  debugPrint(data.toString());
}
```
## Resumen

JCache es excelente en el manejo de la caché. Con su capacidad para almacenar en caché tanto archivos como datos, se convierte en una herramienta indispensable para cualquier desarrollador de Flutter.

Además con su widget `JCacheWidget`, te proporciona una interfaz fácil de usar para descargar y cachear archivos en tu aplicación Flutter. Y con su clase `JCacheManager`, tienes un administrador de caché que se encarga de todas las operaciones de caché, desde almacenar datos hasta recuperarlos y eliminar los datos obsoletos.

JCache no solo mejora la eficiencia de tu aplicación al reducir la necesidad de descargas repetidas, sino que también mejora la experiencia del usuario al proporcionar un acceso más rápido a los datos y archivos que necesita.

Este es un paquete que te ofrece un control completo sobre el almacenamiento en caché en tus aplicaciones Flutter. Es una herramienta poderosa, flexible y fácil de usar que puede llevar tus aplicaciones al siguiente nivel.

Así que, ya seas un veterano del desarrollo de Flutter o estés empezando, te invitamos a probar JCache. Estamos seguros de que te encantará la facilidad y la flexibilidad que ofrece. ¡Feliz codificación!