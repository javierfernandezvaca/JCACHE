# JCACHE

## Descripción

**JCache** es un paquete de Flutter que proporciona una solución completa para el almacenamiento en caché de archivos y datos. Permite manejar archivos de cualquier tipo y almacenar datos en formato `JSON`, con la posibilidad de definir un tiempo de expiración para cada elemento en caché.

## Características

- **Almacenamiento en caché de archivos**: JCache puede almacenar en caché archivos de cualquier tipo. Los archivos pueden ser locales o descargados de Internet.
- **Almacenamiento en caché de datos**: Además de los archivos, JCache también puede almacenar en caché datos en formato `JSON`.
- **Expiración de los archivos y datos**: Permite definir un tiempo de expiración personalizado para cada elemento en caché. Después de este tiempo, los elementos se consideran obsoletos y se eliminan de la caché.
- **JCacheManager**: Esta es la clase administradora de la caché. Se encarga de todas las operaciones de caché, como almacenar, recuperar y eliminar elementos obsoletos.
- **JCacheWidget**: Este es un widget de Flutter que se encarga de obtener un archivo desde la caché. Si el archivo es local, simplemente lo registra y lo proporciona cuando se solicita. Si el archivo se descarga de Internet, JCacheWidget lo descarga, lo almacena en la caché y luego lo proporciona cuando se solicita.

## Instalación

Para instalar JCache, añade la librería a tu archivo `pubspec.yaml`:

```yaml
dependencies:
  jcache:
```

## Uso

En Flutter, la gestión de la caché es una parte esencial para garantizar un 
rendimiento óptimo de la aplicación y una experiencia de usuario fluida. `JCacheManager` y `JCacheWidget` son dos formas eficaces de administrar los elementos en la caché.

Para utilizar este paquete después de haberlo instalado, puedes hacerlo de la siguiente manera:

### Importar la biblioteca

```dart
import 'package:jcache/jcache.dart';
```

### Inicializar la caché

```dart
await JCacheManager.init();
```

### Ejemplo de datos

```dart
/// Unique key for the user data
final userKey = 'user';

/// URL of the user's image
final userImageUrl = 'https://example.com/image.png';

/// Local path of the user's image
final userImagePath = '/path/local/image.png';

/// Map containing the user's data
final userData = {
  'name': 'John Doe',
  'age': 35,
  'resourceUrl': userImageUrl,
  'resourcePath': userImagePath,
};
```

## JCacheManager

Esta es una clase integral que proporciona una serie de métodos para administrar eficientemente la caché. Cada elemento en la caché se almacena con una clave única y tiene un tiempo de expiración definido, después del cual se elimina automáticamente. Esto asegura un manejo eficiente de la memoria y evita que los elementos en la caché se vuelvan obsoletos.

A continuación, se presentan algunas de las operaciones clave que puedes realizar con `JCacheManager`:

#### Almacenar Datos en la Caché

Para almacenar datos en la caché, puedes utilizar el método `setData`. Este método toma una clave y un valor como argumentos:

```dart
await JCacheManager.setData(key: userKey, value: userData);
```

#### Recuperar Datos de la Caché

Para recuperar datos de la caché, puedes utilizar el método `getData`. Este método devuelve los datos asociados en formato `JSON` con la clave proporcionada:

```dart
Map<String, dynamic>? data = await JCacheManager.getData(userKey);
```

#### Almacenar la Ruta del Archivo en la Caché

Para almacenar la ruta de un archivo en la caché, puedes utilizar el método `setFile`. Este método toma una URL y una ruta como argumentos:

```dart
await JCacheManager.setFile(url: userImageUrl, path: userImagePath);
```

#### Recuperar la Ruta del Archivo de la Caché

Para recuperar la ruta de un archivo de la caché, puedes utilizar el método `getFile`. Este método devuelve la ruta del archivo asociado con la clave proporcionada:

```dart
String? filePath = await JCacheManager.getFile(userKey);
```

#### Escuchar Cambios en un Elemento

Para escuchar los cambios en un elemento específico, puedes utilizar el método `watch`. Este método devuelve un `Stream` que emite eventos cada vez que los datos asociados con la clave proporcionada cambian:

```dart
Stream<JCacheManagerData> userStream = JCacheManager.watch(userKey);
````

```dart
userStream.listen((event) {
  debugPrint('Data changed: ${event.data}');
});
```

#### Eliminar un Elemento de la Caché

Para eliminar un elemento de la caché, puedes utilizar el método `remove`. Este método elimina el elemento asociado con la clave proporcionada:

```dart
JCacheManager.remove(userKey);
```

#### Limpiar Todos los Elementos de la Caché

Para limpiar todos los elementos de la caché, puedes utilizar el método `clear`. Este método elimina todos los elementos de la caché:

```dart
JCacheManager.clear();
```

#### Obtener Todas las Claves en la Caché

Para obtener todas las claves en la caché, puedes utilizar el método `getKeys`. Este método devuelve una lista de todas las claves en la caché:

```dart
List<String> keys = await JCacheManager.getKeys();
```
#### Imprimir un Elemento de la Caché

Para imprimir un elemento de la caché, puedes utilizar el método `print`. Este método imprime el elemento asociado con la clave proporcionada:

```dart
JCacheManager.print(userKey);
```

#### Consultar el Número de Elementos en la Caché

Para obtener el número de elementos en la caché, puedes utilizar la propiedad `length`:

```dart
int numItems = JCacheManager.length;
```

#### Verificar si la Caché está Vacía

Para verificar si la caché está vacía, puedes utilizar la propiedad `isEmpty`:

```dart
bool isEmpty = JCacheManager.isEmpty;
```

#### Verificar si la Caché No está Vacía

Para verificar si la caché no está vacía, puedes utilizar la propiedad `isNotEmpty`:

```dart
bool isNotEmpty = JCacheManager.isNotEmpty;
```

#### Comprobar si la Caché Contiene un Elemento

Para comprobar si la caché contiene un elemento con una clave dada, puedes utilizar el método `contains`:

```dart
bool isMember = JCacheManager.contains(userKey);
```

#### Eliminar los Datos y Archivos Expirados

Para eliminar los datos y archivos expirados de la caché, puedes utilizar el método `garbageCollector`. Este método puede ser útil para liberar espacio de almacenamiento:

```dart
await JCacheManager.garbageCollector();
```

#### Liberar los Recursos de la Caché

Para liberar los recursos de la caché cuando ya no se necesiten, puedes utilizar el método dispose. Este método debe ser llamado cuando la aplicación se cierra:

```dart
await JCacheManager.dispose();
```

## JCacheWidget

`JCacheWidget` es un widget de Flutter diseñado específicamente para la descarga y administración en caché de archivos. Este widget es especialmente útil cuando se trabaja con archivos que se descargan de Internet, como imágenes, documentos, audios, videos, entre otros.

Cuando se utiliza `JCacheWidget`, el widget intentará primero recuperar el archivo de la caché local. Si el archivo no está en la caché o ha expirado (según su tiempo de expiración configurado), `JCacheWidget` descargará el archivo de la URL proporcionada y lo almacenará en la caché para su uso futuro. Todo este proceso se realiza de manera óptima y automática.

Las ventajas de utilizar `JCacheWidget` incluyen:

- **Eficiencia de la red**: Al reducir la cantidad de descargas necesarias, `JCacheWidget` mejora la eficiencia de la red.
- **Experiencia del usuario**: Al permitir un acceso más rápido a los archivos ya descargados, incluso cuando el dispositivo está `offline`, `JCacheWidget` mejora la experiencia del usuario.

Aquí te dejo un ejemplo de cómo puedes utilizar `JCacheWidget` en tu aplicación:

```dart
JCacheWidget(
  // URL of the file to download
  url: userImageUrl,
  // Expiry time of the file in days
  expiryDays: 5,
  onInitialized: (event, controller) {
    // Widget to display during initialization
    return const Icon(Icons.image);
  },
  onDownloading: (event, controller) {
    // Widget to display while downloading
    return const CircularProgressIndicator();
  },
  onCompleted: (event, controller) {
    // Widget to display when the download is completed
    File archive = File(event.resourcePath!);
    return Image.file(archive);
  },
  // Widget to display in case of error
  onError: (event, controller) {
    return const Text('Error...');
  },  
  onCancelled: (event, controller) {
    // Widget to display if the download is cancelled
    return const Text('Cancelled...');
  },
);
```

## Resumen

**JCache** es excelente en el manejo de la caché. Con su capacidad para almacenar en caché tanto archivos como datos, se convierte en una herramienta indispensable para cualquier desarrollador de Flutter.

Además con su widget especializado `JCacheWidget`, te proporciona una interfaz fácil de usar para descargar y cachear archivos en tu aplicación Flutter. Y con su clase `JCacheManager`, tienes un administrador de caché que se encarga de todas las operaciones de caché, desde almacenar elementos hasta recuperarlos y eliminar los elementos obsoletos.

**JCache** no solo mejora la eficiencia de tu aplicación al reducir la necesidad de descargas repetidas, sino que también mejora la experiencia del usuario al proporcionar un acceso más rápido a los datos y archivos que necesita.

Este es un paquete que te ofrece un control completo sobre el almacenamiento en caché en tus aplicaciones Flutter. Es una herramienta poderosa, flexible y fácil de usar que puede llevar tus aplicaciones al siguiente nivel.

Así que, te invitamos a probar `JCache`; seguro que te encantará la facilidad y la flexibilidad que ofrece. ¡Feliz codificación!